param(
    [string]$CEWD
)

$ErrorActionPreference = 'Stop'

Set-Location -Path $CEWD
$ROOT = Get-Location

$HASH = (git rev-parse HEAD) -join [Environment]::NewLine
$RELEASE_FILE_NAME = $HASH
$RELEASE_NAME = $HASH
$BRANCH = $HASH

Write-Host "RELEASE_FILE_NAME: $RELEASE_FILE_NAME"
Write-Host "RELEASE_NAME: $RELEASE_NAME"
Write-Host "HASH: $HASH"
Write-Host "BRANCH: $BRANCH"

Remove-Item -Path "out" -Recurse -Force -ErrorAction Ignore
New-Item -Path . -Name "out/dist" -Force -ItemType "directory"

Set-Location -Path "./out/dist"

New-Item -Name "git_hash"
Set-Content -Path "git_hash" -Value "$HASH"

New-Item -Name "release_build"
Set-Content -Path "release_build" -Value "$RELEASE_NAME"

Copy-Item -Path "$ROOT/etc" -Destination . -Recurse
Copy-Item -Path "$ROOT/examples" -Destination . -Recurse
Copy-Item -Path "$ROOT/views" -Destination . -Recurse
Copy-Item -Path "$ROOT/types" -Destination . -Recurse
Copy-Item -Path "$ROOT/package*.json" -Destination . -Recurse

Remove-Item -Path "$ROOT/lib/storage/data" -Force -Recurse -ErrorAction Ignore

Set-Location -Path $ROOT

npm install --no-audit
if ($LASTEXITCODE -ne 0) {
   throw "npm install exited with error $LASTEXITCODE"
}

npm run webpack
if ($LASTEXITCODE -ne 0) {
   throw "npm run webpack exited with error $LASTEXITCODE"
}

npm run ts-compile
if ($LASTEXITCODE -ne 0) {
   throw "npm run ts-compile exited with error $LASTEXITCODE"
}

Set-Location -Path "./out/dist"
npm install --no-audit --ignore-scripts --production
if ($LASTEXITCODE -ne 0) {
   throw "npm install (prod) exited with error $LASTEXITCODE"
}

Remove-Item -Path "node_modules/.cache" -Force -Recurse -ErrorAction Ignore
Remove-Item -Path "node_modules/monaco-editor" -Force -Recurse -ErrorAction Ignore
Remove-Item -Path "node_modules" -Include "*.ts" -Force -Recurse -ErrorAction Ignore

node --import=tsx --no-warnings=ExperimentalWarning ./app.js --version --dist
if ($LASTEXITCODE -ne 0) {
   throw "node exited with error $LASTEXITCODE"
}

$DIST_DIR = "$ROOT/out/dist-bin/dist"
Remove-Item -Path $DIST_DIR -Recurse -Force -ErrorAction Ignore
New-Item -ItemType Directory -Force -Path $DIST_DIR
Set-Content -Path "$DIST_DIR/$HASH.txt" -Value "$HASH"

Set-Location -Path $ROOT