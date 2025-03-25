ARG IMPL_NANO_BASE=mcr.microsoft.com/powershell
ARG IMPL_NANO_TAG=lts-nanoserver-ltsc2022
ARG IMPL_ARTIFACTS_DIR="C:\artifacts"
ARG NODE_VERSION=23.10.0

# nodejs
FROM ${IMPL_NANO_BASE}:${IMPL_NANO_TAG} as node
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG NODE_VERSION
ARG IMPL_ARTIFACTS_DIR

RUN New-Item -ItemType Directory -Force -Path "C:\Temp", $env:IMPL_ARTIFACTS_DIR && Invoke-WebRequest -Uri https://nodejs.org/download/release/latest/node-v$env:NODE_VERSION-win-x64.zip -OutFile C:\Temp\nodejs.zip && tar -xf C:\Temp\nodejs.zip -C $env:IMPL_ARTIFACTS_DIR && Remove-Item C:\Temp\nodejs.zip && ls $env:IMPL_ARTIFACTS_DIR

# compiler-explorer
FROM ${IMPL_NANO_BASE}:${IMPL_NANO_TAG} as compiler-explorer
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG IMPL_ARTIFACTS_DIR

RUN New-Item -ItemType Directory -Force -Path "C:\Temp", $env:IMPL_ARTIFACTS_DIR && Invoke-WebRequest -Uri https://github.com/Devsh-Graphics-Programming/compiler-explorer/archive/refs/heads/main.zip -OutFile C:\Temp\CompilerExplorer.zip && tar -xf C:\Temp\CompilerExplorer.zip -C $env:IMPL_ARTIFACTS_DIR && Remove-Item C:\Temp\CompilerExplorer.zip

# final image
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
SHELL ["cmd.exe", "/C"]

ARG IMPL_ARTIFACTS_DIR
ARG NODE_VERSION

COPY --link --from=node ["${IMPL_ARTIFACTS_DIR}/node-v${NODE_VERSION}-win-x64", "C:/Node"]
COPY --link --from=compiler-explorer ["${IMPL_ARTIFACTS_DIR}/compiler-explorer-main", "C:/Compiler-Explorer"]

USER ContainerAdministrator
ENV NODE_VERSION=${NODE_VERSION} NODE_OPTIONS="--max-old-space-size=4096" GIT_VERSION=${GIT_VERSION} PATH="C:\Windows\system32;C\Windows;C:\Program Files\PowerShell;C:\Git\cmd;C:\Git\bin;C:\Git\usr\bin;C:\Git\mingw64\bin;C:\Node"

EXPOSE 10240
WORKDIR C:\\Compiler-Explorer

RUN npm install && npm run webpack

ENTRYPOINT ["cmd.exe", "/C"]
CMD ["npm", "run", "start"]