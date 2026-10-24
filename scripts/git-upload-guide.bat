@echo off
title Push Healthcare DevOps System to GitHub
color 0b

echo ==============================================================================
echo       Upload PulseCare Healthcare DevOps System to GitHub
echo ==============================================================================
echo.

set GIT_PATH="%LOCALAPPDATA%\Programs\Git\cmd\git.exe"

if exist %GIT_PATH% (
    set "GIT_CMD=%GIT_PATH%"
) else (
    where git >nul 2>nul
    if %errorlevel% equ 0 (
        set "GIT_CMD=git"
    ) else (
        echo [!] Git CLI is not found.
        pause
        exit /b
    )
)

cd /d "C:\Users\Lenovo\.gemini\antigravity\scratch\healthcare-system-devsecops"

echo [*] Checking remote repository...
%GIT_CMD% remote remove origin 2>nul
%GIT_CMD% remote add origin https://github.com/Vamsi-Vyas/medic-devops.git

echo [*] Current branch:
%GIT_CMD% branch -M main

echo [*] Pushing code to https://github.com/Vamsi-Vyas/medic-devops.git ...
echo [NOTE] If prompted, enter your GitHub Username and Personal Access Token (or browser login).
echo.
%GIT_CMD% push -u origin main

echo.
echo ==============================================================================
echo [DONE] Push attempt completed!
echo ==============================================================================
pause

