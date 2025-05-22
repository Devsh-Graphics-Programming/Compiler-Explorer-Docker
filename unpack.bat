@echo off
pushd C:\
setlocal EnableDelayedExpansion
set filecount=0
for %%F in ("pack\*-artifacts.tar.zst") do set /A filecount+=1
if %filecount% GTR 0 (
    echo Unpack started
    for %%Z in ("pack\*-artifacts.tar.zst") do (
        set "zst=%%~fZ"
        set "tar=%%~dpnZ.tar"
        if not exist "!tar!" (
            zstd.exe -d -T0 "!zst!" -o "!tar!"
        )
        tar.exe -xf "!tar!"
        del /Q "!tar!" "!zst!"
    )
    dir
    echo Unpack finished
) else (
    echo No artifacts to unpack.
)
endlocal
popd