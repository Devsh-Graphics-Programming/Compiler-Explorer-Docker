# syntax=docker/dockerfile:1
# escape=`

# ---------------- GLOBAL VARS ----------------
ARG NODE_VERSION=23.10.0
ARG ZSTD_VERSION=1.5.7

ARG GODBOLT_REMOTE=https://github.com/compiler-explorer/compiler-explorer.git
ARG GODBOLT_SHA=fc1b97ef9325eacbb8100d280aee0b0158a5adca

ARG IMPL_GIT_VERSION=2.48.1
ARG IMPL_ARTIFACTS_DIR="C:\artifacts"

ARG IMPL_NANO_BASE=mcr.microsoft.com/powershell
ARG IMPL_NANO_TAG=lts-nanoserver-ltsc2022

# ---------------- NODE JS ----------------
FROM ${IMPL_NANO_BASE}:${IMPL_NANO_TAG} as node
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG NODE_VERSION
ARG IMPL_ARTIFACTS_DIR

RUN Write-Host "Installing NodeJS $env:NODE_VERSION" ; `
New-Item -ItemType Directory -Force -Path "C:\Temp", $env:IMPL_ARTIFACTS_DIR ; `
Invoke-WebRequest -Uri https://nodejs.org/download/release/v$env:NODE_VERSION/node-v$env:NODE_VERSION-win-x64.zip -OutFile C:\Temp\nodejs.zip ; `
tar -xf C:\Temp\nodejs.zip -C $env:IMPL_ARTIFACTS_DIR ; Remove-Item C:\Temp\nodejs.zip

# ---------------- GIT ----------------
FROM ${IMPL_NANO_BASE}:${IMPL_NANO_TAG} as git
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG IMPL_GIT_VERSION
ARG IMPL_ARTIFACTS_DIR

RUN Write-Host "Installing Git $env:IMPL_GIT_VERSION" ; `
New-Item -ItemType Directory -Force -Path C:\Temp, $env:IMPL_ARTIFACTS_DIR ; `
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v$env:IMPL_GIT_VERSION.windows.1/MinGit-$env:IMPL_GIT_VERSION-busybox-64-bit.zip" -OutFile C:\Temp\git.zip ; `
tar -xf C:\Temp\git.zip -C $env:IMPL_ARTIFACTS_DIR ; Remove-Item C:\Temp\git.zip

# ---------------- COMPILER EXPLORER ----------------
FROM ${IMPL_NANO_BASE}:${IMPL_NANO_TAG} as compiler-explorer
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG NODE_VERSION
ARG IMPL_ARTIFACTS_DIR

COPY --link --from=node ["${IMPL_ARTIFACTS_DIR}/node-v${NODE_VERSION}-win-x64", "C:/Node"]
COPY --link --from=git ["${IMPL_ARTIFACTS_DIR}", "C:/Git"]
ENV PATH="C:\Windows\system32;C:\Windows;C:\Program Files\PowerShell;C:\Git\cmd;C:\Git\bin;C:\Git\usr\bin;C:\Git\mingw64\bin;C:\Node"

ARG GODBOLT_REMOTE
ARG GODBOLT_SHA

RUN Write-Host "Installing Compiler Explorer" ; Write-Host "Remote $env:GODBOLT_REMOTE" ; Write-Host "SHA $env:GODBOLT_SHA" ; `
New-Item -ItemType Directory -Force -Path $env:IMPL_ARTIFACTS_DIR ; `
git config --system --add safe.directory * ; `
git -C "$env:IMPL_ARTIFACTS_DIR" init ; `
git -C "$env:IMPL_ARTIFACTS_DIR" remote add origin $env:GODBOLT_REMOTE ; `
git -C "$env:IMPL_ARTIFACTS_DIR" fetch --depth=1 -- origin $env:GODBOLT_SHA ; `
git -C "$env:IMPL_ARTIFACTS_DIR" checkout $env:GODBOLT_SHA

COPY scripts/build-win.ps1 ${IMPL_ARTIFACTS_DIR}/build-win.ps1 
WORKDIR ${IMPL_ARTIFACTS_DIR}
ENV NODE_OPTIONS="--max-old-space-size=69000"
RUN cd $env:IMPL_ARTIFACTS_DIR ; ` 
Write-Host "Building Compiler Explorer" ; `
pwsh -File build-win.ps1 -CEWD "$env:IMPL_ARTIFACTS_DIR"

# ---------------- ZSTD ----------------
FROM ${IMPL_NANO_BASE}:${IMPL_NANO_TAG} as zstd
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG ZSTD_VERSION
ARG IMPL_ARTIFACTS_DIR

RUN Write-Host "Installing Git $env:ZSTD_VERSION" ; `
New-Item -ItemType Directory -Force -Path C:\Temp, $env:IMPL_ARTIFACTS_DIR ; `
Invoke-WebRequest -Uri "https://github.com/facebook/zstd/releases/download/v$env:ZSTD_VERSION/zstd-v$env:ZSTD_VERSION-win64.zip" -OutFile C:\Temp\zstd.zip ; `
tar -xf C:\Temp\zstd.zip -C $env:IMPL_ARTIFACTS_DIR ; `
Remove-Item C:\Temp\zstd.zip

# ---------------- FINAL IMAGE ----------------
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
USER ContainerAdministrator

LABEL org.opencontainers.image.title="Compiler Explorer in Windows Nano Server"
LABEL org.opencontainers.image.source=https://github.com/Devsh-Graphics-Programming/Compiler-Explorer-Docker
LABEL org.opencontainers.image.description="Run Compiler Explorer in Windows Nano Server!"
LABEL org.opencontainers.image.licenses=Apache-2.0

ARG IMPL_ARTIFACTS_DIR
ARG NODE_VERSION
COPY --link --from=zstd ["${IMPL_ARTIFACTS_DIR}", "C:/compress"]
COPY --link --from=node ["${IMPL_ARTIFACTS_DIR}/node-v${NODE_VERSION}-win-x64", "C:/Node"]
COPY --link --from=compiler-explorer ["${IMPL_ARTIFACTS_DIR}/out/dist", "C:/Compiler-Explorer"]
COPY --link --from=compiler-explorer ["${IMPL_ARTIFACTS_DIR}/out/dist-bin/dist", "C:/Compiler-Explorer"]
COPY --link --from=compiler-explorer ["${IMPL_ARTIFACTS_DIR}/out/webpack/static", "C:/Compiler-Explorer/static"]

ARG ZSTD_VERSION

ENV NODE_VERSION=${NODE_VERSION} `
NODE_ENV=production `
ZSTD_VERSION=${ZSTD_VERSION} `
PATH="C:\Windows\system32;C:\Windows;C:\Node;C:\compress\zstd-v${ZSTD_VERSION}-win64"

EXPOSE 10240
COPY unpack.bat .
WORKDIR C:\Compiler-Explorer

ENTRYPOINT ["cmd.exe", "/S", "/K"]
CMD ["C:/unpack.bat"]