# Compiler-Explorer-Docker

Host your own Compiler Explorer instance in docker container!

## Requirements

- [Git](https://git-scm.com/download/win)
- [Docker](https://www.docker.com/products/docker-desktop/)
- [Enabled Hyper-V Windows feature](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v#enable-hyper-v-using-powershell) 

> [!NOTE]  
> [Hyper-V Windows feature](<https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/Install-Hyper-V?pivots=windows#enable-hyper-v-using-powershell>) _is not_ really required if you use process isolation for both the image build & runtime.

## How to

> [!IMPORTANT]  
> If using Docker Desktop - first make sure you have switched to `Containers for Windows`. If you are CLI user and have client & daemon headless, then use appropriate windows build context.

![Containers for Windows](https://user-images.githubusercontent.com/65064509/152947300-affca592-35a7-4e4c-a7fc-2055ce1ba528.png)

### Build and run

Clone the repository 

```powershell
git clone https://github.com/Devsh-Graphics-Programming/Compiler-Explorer-Docker.git
```

enter the cloned directory, build the image

```powershell
docker build --isolation "process" -t godbolt/nano .
```

> [!TIP]
> I highly recommend to build the image without virtualization (process isolation) to use all host resources, HyperV isolation will assign 1/2 CPUs + 1GB of RAM by default hence the result could be < 10x slower build _without assigning cpu resources by hand_. If you get an error and can't use process isolation it's because your host kernel version is too low - update your OS or switch to HyperV (skip `--process "isolation"` flag).

> [!TIP]
> The image is built with default set of options, there are a few you can override (eg. NodeJS version, remote & sha of CE). See [Dockerfile](<https://github.com/Devsh-Graphics-Programming/Compiler-Explorer-Docker/blob/master/Dockerfile>) code for more details.

run the container 

```powershell
docker run -p 80:10240 -it godbolt/nano
```

and open your browser with **http://localhost**. 

> [!IMPORTANT]  
> You should use produced image as base to provide your own compilers (installation binaries) & configuration files for CE to use them. By default we run it without any compilers.
