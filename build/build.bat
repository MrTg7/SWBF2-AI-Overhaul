@echo off
setlocal

:: 1. Resolve repository root (one level up from /build)
for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"

:: 2. Configure paths to BF2_ModTools and your SWBF2 installation
set "MODTOOLS_BIN=%REPO_ROOT%\build\bin"
set "GAME_LVL_DIR=C:\Games\Steam\steamapps\common\Star Wars Battlefront II Classic\GameData\data\_lvl_pc"

:: 3. Define repo subdirectories matching your tree
set "SRC_SCRIPTS=%REPO_ROOT%\src\scripts"
set "SRC_REQ=%REPO_ROOT%\src\req"
set "MUNGED_DIR=%REPO_ROOT%\build\munged"
set "DIST_LVL_DIR=%REPO_ROOT%\dist\data\_lvl_pc"

if not exist "%MUNGED_DIR%" mkdir "%MUNGED_DIR%"
if not exist "%DIST_LVL_DIR%" mkdir "%DIST_LVL_DIR%"

echo [1/2] Compiling src\scripts\user_script_1.lua...
"%MODTOOLS_BIN%\scriptmunge.exe" -inputfile user_script_1.lua -platform pc -sourcedir "%SRC_SCRIPTS%" -outputdir "%MUNGED_DIR%" -checkdate

if not exist "%MUNGED_DIR%\user_script_1.script" (
    echo [ERROR] Lua compilation failed! Check for syntax errors above.
    pause
    exit /b 1
)

echo [2/2] Packing user_script_1.lvl into dist...
"%MODTOOLS_BIN%\levelpack.exe" -inputfile user_script_1.req -platform pc -sourcedir "%SRC_REQ%" -inputdir "%MUNGED_DIR%" -outputdir "%DIST_LVL_DIR%"

if exist "%DIST_LVL_DIR%\user_script_1.lvl" (
    echo [SUCCESS] Built "%DIST_LVL_DIR%\user_script_1.lvl"
    if exist "%GAME_LVL_DIR%" (
        copy /Y "%DIST_LVL_DIR%\user_script_1.lvl" "%GAME_LVL_DIR%\user_script_1.lvl" >nul
        echo [INSTALLED] Copied user_script_1.lvl to your game's data\_lvl_pc folder!
    )
) else (
    echo [ERROR] Failed to pack user_script_1.lvl.
)

pause