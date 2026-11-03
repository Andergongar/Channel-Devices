
@echo off
setlocal EnableExtensions

:: ==========================================
:: CONFIGURATION
:: ==========================================

set "BASE_DIR=%~dp0"
set "DEPENDENCIES_DIR=%BASE_DIR%Dependencies"
set "RELEASE_DIR=%BASE_DIR%Release"

:: Generic Channel
set "GENERIC_CH_VERSION=v1.0.0"
set "GENERIC_CH_REPO=Andergongar/Generic-Channel"

:: Abstraction Channels
set "ABSTRACTION_CH_VERSION=v1.0.0"
set "ABSTRACTION_CH_REPO=Andergongar/Abstraction-Channels"

:: ==========================================
:: CREATE DIRECTORIES
:: ==========================================

if not exist "%DEPENDENCIES_DIR%" mkdir "%DEPENDENCIES_DIR%"
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"


:: ==========================================
:: DOWNLOAD DEPENDENCIES
:: ==========================================

call :DownloadDependency "Generic-Channel" "%GENERIC_CH_REPO%" "%GENERIC_CH_VERSION%" || goto :ERROR

call :DownloadDependency "Abstraction-Channels" "%ABSTRACTION_CH_REPO%" "%ABSTRACTION_CH_VERSION%" || goto :ERROR


:: ==========================================
:: COMPLETED
:: ==========================================

echo.
echo ==========================================
echo All dependencies downloaded successfully!
echo ==========================================
echo Release directory: "%RELEASE_DIR%"

endlocal
exit /b 0


:: ==========================================
:: FUNCTION: DOWNLOAD DEPENDENCY
::
:: Parameters:
:: %1 = Dependency Name
:: %2 = GitHub Repository
:: %3 = Release Version
:: ==========================================


:DownloadDependency

setlocal EnableExtensions

set "DEP_NAME=%~1"
set "DEP_REPO=%~2"
set "DEP_VERSION=%~3"
set "DEP_DIR=%DEPENDENCIES_DIR%"

echo.
echo ==========================================
echo Downloading %DEP_NAME%
echo Repository: %DEP_REPO%
echo Version: %DEP_VERSION%
echo ==========================================

:: Download GitHub Release directly into Dependencies
gh release download "%DEP_VERSION%" --repo "%DEP_REPO%" --dir "%DEP_DIR%"

if errorlevel 1 (
    echo ERROR: Failed to download %DEP_NAME%.
    endlocal & exit /b 1
)

:: Extract downloaded ZIP files
for %%F in ("%DEP_DIR%\*.zip") do (
    if exist "%%~fF" (
        echo Extracting %%~nxF...

        tar -xf "%%~fF" -C "%DEP_DIR%"

        if errorlevel 1 (
            echo ERROR: Failed to extract %%~nxF.
            endlocal & exit /b 1
        )

        del "%%~fF"
    )
)

echo %DEP_NAME% completed successfully.

endlocal & exit /b 0

echo %DEP_NAME% completed successfully.

endlocal & exit /b 0


:: ==========================================
:: ERROR HANDLING
:: ==========================================

:ERROR

echo.
echo ==========================================
echo ERROR: Dependency installation failed!
echo ==========================================

endlocal
exit /b 1
