@echo off
setlocal
echo Cleaning build output...

if exist bin (
    echo Deleting bin\
    rd /s /q bin
)

if exist bin-int (
    echo Deleting bin-int\
    rd /s /q bin-int
)

echo Clean complete.
endlocal