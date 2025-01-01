# escape=`

ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022-amd64

FROM ${BASE_IMAGE}

SHELL ["cmd", "/S", "/C"]

ENV GIT_VERSION=2.43.0
ENV GIT_GODBOLT_REPOSITORY_PATH=C:\compiler-explorer
ENV CE_URL=https://github.com/Devsh-Graphics-Programming/compiler-explorer.git
ENV CE_SHA=ce980aded514ae6a0a1b1f63e7fb358e57c9ed57
ENV NODEJS_MSI=https://nodejs.org/dist/v18.19.0/node-v18.19.0-x64.msi

RUN ` 
    # Install Chocolatey
    `
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

RUN `
    # Install Git
    `
    choco install -y git --version %GIT_VERSION%

RUN `
	# Install Node LTS
	`
	curl -SL --output nodejs.msi %NODEJS_MSI% `
	`
	&& msiexec /i nodejs.msi /qn `
	`
	&& del /q nodejs.msi

RUN `
    # Checkout Compiler-Explorer
    `
	mkdir %GIT_GODBOLT_REPOSITORY_PATH% `
	`
	&& git -C %GIT_GODBOLT_REPOSITORY_PATH% init `
	`
	&& git -C %GIT_GODBOLT_REPOSITORY_PATH% remote add origin %CE_URL% `
	`
	&& git -C %GIT_GODBOLT_REPOSITORY_PATH% fetch --depth=1 -- origin %CE_SHA% `
	`
	&& git -C %GIT_GODBOLT_REPOSITORY_PATH% checkout %CE_SHA% `
    `
    && setx GIT_GODBOLT_REPOSITORY_PATH %GIT_GODBOLT_REPOSITORY_PATH% /M

RUN `
    # Install node depenendencies
    `
    cd %GIT_GODBOLT_REPOSITORY_PATH% `
    `
    && npm install

RUN `
	# Post git configuration, trust containers
	`
	git config --system --add safe.directory * `
    `
    # Enable Long Paths feature
	`
    && reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d 1 /f