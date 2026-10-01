$env:Path += ";C:\flutter\bin"
cd C:\Users\dell\shattab-app
flutter build web --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python -m http.server 8080 --directory build\web --bind 127.0.0.1
