# escape=`

ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022-amd64

FROM ${BASE_IMAGE}

SHELL ["cmd", "/S", "/C"]

ENV GIT_VERSION=2.47.1

RUN `
	# Download Git
	`
	curl -SL --output git.zip https://github.com/git-for-windows/git/releases/download/v%GIT_VERSION%.windows.1/MinGit-%GIT_VERSION%-64-bit.zip `
	`
	&& mkdir "C:\\git" `
	`
	&& tar -xf git.zip -C "C:\\git" `
	`
	&& setx PATH "%PATH%;C:\\git\\cmd" /M `
	`
	&& del /q git.zip
	
RUN `
	# Post git configuration
	`
	git config --system --add safe.directory *

ENV PYTHON_VERSION=3.11.0

RUN `
    # Download Python
    `
    curl -SL --output python.zip https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip `
    `
    && mkdir "C:\\python" `
    `
    && tar -xf python.zip -C "C:\\python" `
    `
    && setx PATH "%PATH%;C:\\python" /M `
    `
    && del /q python.zip

ENV NODEJS_MSI=https://nodejs.org/dist/v18.19.0/node-v18.19.0-x64.msi

RUN `
	# Install Node LTS
	`
	curl -SL --output nodejs.msi %NODEJS_MSI% `
	`
	&& msiexec /i nodejs.msi /qn `
	`
	&& del /q nodejs.msi

ENV GIT_GODBOLT_REPOSITORY_PATH=C:\compiler-explorer
ENV CE_URL=https://github.com/Devsh-Graphics-Programming/compiler-explorer.git
ENV CE_SHA=ce980aded514ae6a0a1b1f63e7fb358e57c9ed57

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

ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN `
    # Install Node.js dependencies & precompile production
    `
    cd %GIT_GODBOLT_REPOSITORY_PATH% `
    `
    && npm ci `
    `
    && npm run webpack
	
RUN `
	# Post registry configuration
	`
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d 1 /f

COPY ce_healthy_check.py /ce_healthy_check.py

SHELL ["powershell.exe", "-ExecutionPolicy", "Bypass", "-Command"]
ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass"]
CMD ["-NoExit"]