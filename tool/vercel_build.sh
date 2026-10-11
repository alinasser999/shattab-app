#!/usr/bin/env bash
set -Eeuo pipefail

# Do not enable xtrace: Preview values are written to the temporary dotenv file.

readonly FLUTTER_VERSION='3.44.4'
readonly FLUTTER_ARCHIVE_URL='https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz'
readonly FLUTTER_ARCHIVE_SHA256='c853cda0312a162854c481fe6a1bc286d84fbb74bfab7037c39750061dc9b466'
readonly FLUTTER_PROBE_CAPTURE_MAX_BYTES=16384
readonly FLUTTER_DIAGNOSTIC_MAX_RAW_LINE_BYTES=2048
readonly FLUTTER_DIAGNOSTIC_MAX_LINES=11
readonly FLUTTER_DIAGNOSTIC_MAX_OUTPUT_LINE_BYTES=240

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
OUTPUT_DIR="$ROOT_DIR/build/web"

env_created=0
env_identity=''
temp_dir=''
probe_output=''

fail() {
  printf 'Vercel Flutter build failed: %s\n' "$1" >&2
  exit 1
}

redact_flutter_diagnostic() {
  local input_path="$1"
  local input_bytes=''
  local last_byte=''
  local bounded_text=''
  local awk_program=''
  local line=''
  local redacted_line=''
  local diagnostic=''
  local final_text=''
  local control_free_text=''

  [[ -r "$input_path" ]] || return 1
  for command_name in head tail od sed tr awk cut wc; do
    command -v "$command_name" >/dev/null 2>&1 || return 1
  done

  # If capture reached its byte cap, it may split a token across the stored
  # boundary. Withhold the sample instead of exposing an unmatched fragment.
  if ! input_bytes="$(wc -c < "$input_path" | tr -d '[:space:]')"; then
    return 1
  fi
  [[ "$input_bytes" =~ ^[0-9]+$ ]] || return 1
  if (( input_bytes >= FLUTTER_PROBE_CAPTURE_MAX_BYTES )); then
    bounded_text='[Flutter diagnostic capture reached its byte limit; sample withheld]'
  elif (( input_bytes == 0 )); then
    bounded_text=''
  else
    if ! last_byte="$(
      head -c "$FLUTTER_PROBE_CAPTURE_MAX_BYTES" "$input_path" \
        | tail -c 1 \
        | od -An -tu1 \
        | tr -d '[:space:]'
    )"; then
      return 1
    fi
    if [[ -n "$last_byte" && ! "$last_byte" =~ ^[0-9]+$ ]]; then
      return 1
    fi
    if [[ "$last_byte" != '10' ]]; then
      bounded_text='[Flutter diagnostic ended with an incomplete line; sample withheld]'
    else
      # Map terminal/control bytes before inspection. Any marked, oversized,
      # or excessive source record withholds the complete sample. Safe records
      # are concatenated before redaction, so LF cannot split a secret/token.
      awk_program='
        BEGIN { source_lines = 0; unsafe = 0; sample = "" }
        {
          source_lines++
          if (source_lines > max_lines || index($0, "\001") > 0 || length($0) > max_line_bytes) {
            unsafe = 1
            next
          }
          sample = sample $0
        }
        END {
          if (unsafe) {
            print "[diagnostic contained an unsafe, oversized, or excessive line; sample withheld]"
          } else {
            printf "%s\n", sample
          }
        }
      '
      if ! bounded_text="$(
        head -c "$FLUTTER_PROBE_CAPTURE_MAX_BYTES" "$input_path" \
          | LC_ALL=C tr '\000-\011\013-\037\177-\237' '\001' \
          | LC_ALL=C awk \
              -v max_line_bytes="$FLUTTER_DIAGNOSTIC_MAX_RAW_LINE_BYTES" \
              -v max_lines="$FLUTTER_DIAGNOSTIC_MAX_LINES" \
              "$awk_program"
      )"; then
        return 1
      fi
    fi
  fi

  # The normalized sample is one line, bounded by the 16 KiB capture. Redact
  # before the output byte cut so truncation cannot expose a secret fragment.
  line="$bounded_text"
  if [[ -n "$line" ]]; then
    line="${line//"$SUPABASE_URL"/[REDACTED_SUPABASE_URL]}"
    line="${line//"$SUPABASE_ANON_KEY"/[REDACTED_SUPABASE_ANON_KEY]}"

    if ! redacted_line="$(
      printf '%s' "$line" \
        | LC_ALL=C sed -E \
            -e 's#eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+#[REDACTED_JWT]#g' \
            -e 's#sb_(publishable|secret)_[A-Za-z0-9_-]+#[REDACTED_SUPABASE_TOKEN]#g' \
            -e 's#(SUPABASE_URL|SUPABASE_ANON_KEY)[[:space:]]*=[[:space:]]*[^[:space:]]+#\1=[REDACTED]#g' \
            -e 's#https?://[^[:space:]]+#[REDACTED_URL]#g' 2>/dev/null \
        | LC_ALL=C cut -b "1-$FLUTTER_DIAGNOSTIC_MAX_OUTPUT_LINE_BYTES" 2>/dev/null
    )"; then
      return 1
    fi
    diagnostic="${redacted_line}"$'\n'
  fi

  final_text="${diagnostic%$'\n'}"
  if ! control_free_text="$(
    printf '%s' "$final_text" \
      | LC_ALL=C tr -d '\000-\011\013-\037\177-\237' 2>/dev/null
  )"; then
    return 1
  fi
  [[ "$control_free_text" == "$final_text" ]] || return 1

  printf '%s' "$diagnostic"
}

report_flutter_probe_failure() {
  local exit_status="$1"
  local reason="$2"
  local safe_diagnostic=''

  if safe_diagnostic="$(redact_flutter_diagnostic "$probe_output" 2>/dev/null)"; then
    printf 'Flutter CLI startup check failed: %s (exit status %s). Redacted diagnostic follows:\n' \
      "$reason" "$exit_status" >&2
    if [[ -n "$safe_diagnostic" ]]; then
      printf '%s' "$safe_diagnostic" >&2
    else
      printf 'No diagnostic text was available.\n' >&2
    fi
  else
    printf 'Flutter diagnostic redaction failed; startup output was withheld.\n' >&2
  fi

  if [[ "$exit_status" =~ ^[1-9][0-9]*$ ]] && (( exit_status <= 255 )); then
    exit "$exit_status"
  fi
  exit 1
}

cleanup() {
  local status=$?
  local current_identity=''

  trap - EXIT

  if (( env_created )); then
    if [[ -e "$ENV_FILE" || -L "$ENV_FILE" ]]; then
      current_identity="$(stat -c '%d:%i' -- "$ENV_FILE" 2>/dev/null || true)"
      if [[ -n "$env_identity" && "$current_identity" == "$env_identity" ]]; then
        rm -- "$ENV_FILE" || status=1
      elif [[ -z "$env_identity" ]]; then
        printf 'Vercel Flutter build cleanup skipped .env because its file identity could not be verified; leaving it in place.\n' >&2
        status=1
      else
        printf 'Vercel Flutter build cleanup skipped .env because its file identity changed; leaving it in place.\n' >&2
        status=1
      fi
    fi
  fi

  if [[ -n "$probe_output" ]]; then
    case "$probe_output" in
      "$temp_dir"/flutter-version-probe.*)
        if [[ -e "$probe_output" || -L "$probe_output" ]]; then
          rm -- "$probe_output" || status=1
        fi
        ;;
      *)
        printf 'Vercel Flutter build cleanup skipped an unexpected diagnostic path.\n' >&2
        status=1
        ;;
    esac
  fi

  if [[ -n "$temp_dir" ]]; then
    case "$temp_dir" in
      /tmp/shattab-flutter-build.*)
        if [[ -d "$temp_dir" && ! -L "$temp_dir" ]]; then
          rm -rf -- "$temp_dir" || status=1
        fi
        ;;
      *)
        printf 'Vercel Flutter build cleanup skipped an unexpected temporary path.\n' >&2
        status=1
        ;;
    esac
  fi

  exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ ! -f "$ROOT_DIR/pubspec.yaml" ]]; then
  fail 'pubspec.yaml was not found at the repository root.'
fi

if [[ "${VERCEL_ENV:-}" != 'preview' ]]; then
  fail 'VERCEL_ENV must be preview.'
fi

if [[ -z "${SUPABASE_URL:-}" ]]; then
  fail 'SUPABASE_URL is required in the Vercel Preview environment.'
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  fail 'SUPABASE_ANON_KEY is required in the Vercel Preview environment.'
fi

if [[ "$SUPABASE_URL" == *$'\n'* || "$SUPABASE_URL" == *$'\r'* ]]; then
  fail 'SUPABASE_URL must not contain line breaks.'
fi

if [[ "$SUPABASE_ANON_KEY" == *$'\n'* || "$SUPABASE_ANON_KEY" == *$'\r'* ]]; then
  fail 'SUPABASE_ANON_KEY must not contain line breaks.'
fi

if [[ -e "$ENV_FILE" || -L "$ENV_FILE" ]]; then
  fail 'Refusing to overwrite an existing root .env file.'
fi

if [[ -e "$OUTPUT_DIR" || -L "$OUTPUT_DIR" ]]; then
  fail 'Refusing to reuse an existing build/web output directory.'
fi

  for command_name in curl sha256sum tar mktemp stat chmod head cat tail od sed tr awk cut wc grep; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "Required Linux build tool is unavailable: $command_name."
  fi
done

umask 077
if (set -o noclobber; : > "$ENV_FILE") 2>/dev/null; then
  env_created=1
else
  fail 'Unable to create the temporary root .env file safely.'
fi

env_identity="$(stat -c '%d:%i' -- "$ENV_FILE")" || fail 'Unable to verify the temporary .env file.'
if [[ ! "$env_identity" =~ ^[0-9]+:[0-9]+$ ]]; then
  fail 'Unable to verify the temporary .env file identity.'
fi
chmod 600 -- "$ENV_FILE" || fail 'Unable to restrict temporary .env file permissions.'
printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\n' \
  "$SUPABASE_URL" "$SUPABASE_ANON_KEY" >> "$ENV_FILE" || fail 'Unable to write the temporary .env file.'

temp_dir="$(mktemp -d /tmp/shattab-flutter-build.XXXXXXXXXX)" || fail 'Unable to create a private temporary SDK directory.'
chmod 700 -- "$temp_dir" || fail 'Unable to restrict temporary SDK directory permissions.'

archive_path="$temp_dir/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
printf 'Downloading pinned Flutter %s Linux SDK archive.\n' "$FLUTTER_VERSION"
curl --fail --location --silent --show-error --output "$archive_path" "$FLUTTER_ARCHIVE_URL" || fail 'Flutter SDK download failed.'

if ! printf '%s  %s\n' "$FLUTTER_ARCHIVE_SHA256" "$archive_path" | sha256sum --check --status; then
  fail 'Flutter SDK archive checksum did not match official release metadata.'
fi
printf 'Verified Flutter %s Linux SDK archive checksum.\n' "$FLUTTER_VERSION"

tar -xf "$archive_path" -C "$temp_dir" || fail 'Flutter SDK extraction failed.'
flutter_bin="$temp_dir/flutter/bin"
if [[ ! -x "$flutter_bin/flutter" ]]; then
  fail 'Flutter executable was not present after SDK extraction.'
fi

export PATH="$flutter_bin:$PATH"
probe_output="$(mktemp "$temp_dir/flutter-version-probe.XXXXXXXXXX")" || fail 'Unable to create a private Flutter startup diagnostic file.'
chmod 600 -- "$probe_output" || fail 'Unable to restrict Flutter startup diagnostic file permissions.'

probe_statuses=()
set +e
flutter --version --machine 2>&1 | {
  head -c "$FLUTTER_PROBE_CAPTURE_MAX_BYTES" > "$probe_output"
  head_capture_status=$?
  cat >/dev/null
  drain_capture_status=$?
  if (( head_capture_status != 0 || drain_capture_status != 0 )); then
    exit 1
  fi
}
probe_statuses=("${PIPESTATUS[@]}")
set -e

probe_exit_status="${probe_statuses[0]:-1}"
probe_capture_status="${probe_statuses[1]:-1}"
if [[ "$probe_capture_status" -ne 0 ]]; then
  fail 'Unable to capture bounded Flutter startup diagnostics.'
fi
if [[ "$probe_exit_status" -ne 0 ]]; then
  report_flutter_probe_failure "$probe_exit_status" 'Flutter CLI startup failed'
fi

if ! grep -Eq '"flutterVersion"[[:space:]]*:[[:space:]]*"3\.44\.4"' "$probe_output"; then
  report_flutter_probe_failure 0 'Flutter version metadata did not match the pinned release'
fi
printf 'Verified Flutter %s CLI startup.\n' "$FLUTTER_VERSION"

printf 'Running flutter pub get --enforce-lockfile.\n'
flutter pub get --enforce-lockfile

printf 'Running dart run build_runner build.\n'
dart run build_runner build

printf 'Building Flutter web release output.\n'
flutter build web --release

require_output_file() {
  local relative_path="$1"
  if [[ ! -s "$OUTPUT_DIR/$relative_path" ]]; then
    fail "Required generated output is missing or empty: build/web/$relative_path."
  fi
  printf 'Verified generated output: build/web/%s\n' "$relative_path"
}

require_output_file 'index.html'
require_output_file 'flutter_bootstrap.js'
require_output_file 'flutter.js'
require_output_file 'main.dart.js'
require_output_file 'assets/.env'

printf 'Flutter web output is ready in build/web.\n'
