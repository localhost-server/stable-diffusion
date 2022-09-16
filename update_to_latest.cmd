@echo off
cd %~dp0

:: Duplicate code to find miniconda

IF EXIST custom-conda-path.txt (
  FOR /F %%i IN (custom-conda-path.txt) DO set v_custom_path=%%i
)

set v_paths=%ProgramData%\miniconda3
set v_paths=%v_paths%;%USERPROFILE%\miniconda3
set v_paths=%v_paths%;%ProgramData%\anaconda3
set v_paths=%v_paths%;%USERPROFILE%\anaconda3

for %%a in (%v_paths%) do (
  IF NOT "%v_custom_path%"=="" (
    set v_paths=%v_custom_path%;%v_paths%
  )
)

for %%a in (%v_paths%) do (
  if EXIST "%%a\Scripts\activate.bat" (
    SET v_conda_path=%%a
    echo anaconda3/miniconda3 detected in %%a
  )
)

IF "%v_conda_path%"=="" (
  echo anaconda3/miniconda3 not found. Install from here https://docs.conda.io/en/latest/miniconda.html
  pause
  exit /b 1
)

:: Update

echo Stashing local changes and pulling latest update...
call git stash
call git pull
set /P restore="Do you want to restore changes you made before updating? (Y/N): "
IF /I "%restore%" == "N" (
  echo Removing changes please wait...
  call git stash drop
  echo Changes removed, press any key to continue...
  pause >nul
) ELSE IF /I "%restore%" == "Y" (
  echo Restoring changes, please wait...
  call git stash pop --quiet
  echo Changes restored, press any key to continue...
  pause >nul
)

for /f "delims=" %%a in ('git log -1 --format^="%%H" -- environment.yaml')  DO set v_cur_hash=%%a
echo %v_cur_hash%>z_version_env.tmp

call conda env create --name "%v_conda_env_name%" -f environment.yaml
call conda env update --name "%v_conda_env_name%" -f environment.yaml
if not defined AUTO pause

call "%v_conda_path%\Scripts\activate.bat"

::cmd /k