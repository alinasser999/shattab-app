$env:Path += ";C:\flutter\bin"
Set-Location $PSScriptRoot
flutter run -d chrome --web-port 8080
