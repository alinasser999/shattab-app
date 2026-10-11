#!/usr/bin/env bash
set -Eeuo pipefail

# Do not enable xtrace: Preview values are written to the temporary dotenv file.

readonly FLUTTER_VERSION='3.44.4'
readonly FLUTTER_ARCHIVE_URL='https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz'
readonly FLUTTER_ARCHIVE_SHA256='c853cda0312a162854c481fe6a1bc286d84fbb74bfab7037c39750061dc9b466'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
OUTPUT_DIR="$ROOT_DIR/build/web"

env_created=0
env_identity=''
temp_dir=''

fail() {
  printf 'Vercel Flutter build failed: %s\n' "$1" >&2
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

for command_name in curl sha256sum tar mktemp stat chmod; do
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
flutter_version_info="$(flutter --version --machine 2>/dev/null)" || fail 'Pinned Flutter SDK could not start.'
if ! printf '%s\n' "$flutter_version_info" | grep -Eq '"flutterVersion"[[:space:]]*:[[:space:]]*"3\.44\.4"'; then
  fail 'Extracted Flutter SDK version did not match the pinned release.'
fi

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
