@echo off
title Push Healthcare DevOps System to GitHub
color 0b

echo ==============================================================================
echo       Upload PulseCare Healthcare DevOps System to GitHub / GitLab
echo ==============================================================================
echo.

where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Git CLI is not installed or not in your system PATH.
    echo.
    echo Please follow either of these simple steps:
    echo 1. Download and install Git from: https://git-scm.com/download/win
    echo 2. OR open this folder in VS Code and use the Source Control (Ctrl+Shift+G)
    echo    tab to initialize and publish repository directly to GitHub!
    echo.
    pause
    exit /b
)

echo [*] Initializing Git repository...
git init

echo [*] Adding all project files...
git add .

echo [*] Creating initial commit...
git commit -m "feat: complete healthcare system with Jenkins CI/CD, Kubernetes, Blue-Green, and DevSecOps"

echo.
echo ==============================================================================
echo Repository initialized! Now link it to your remote GitHub repository.
echo.
set /p REPO_URL="Enter your GitHub Repository URL (e.g., https://github.com/username/healthcare-devsecops.git): "

if "%REPO_URL%"=="" (
    echo No repository URL entered. You can add it later via:
    echo   git remote add origin YOUR_URL
    echo   git branch -M main
    echo   git push -u origin main
    pause
    exit /b
)

git branch -M main
git remote remove origin 2>nul
git remote add origin %REPO_URL%
echo [*] Pushing to main branch...
git push -u origin main

echo.
echo ==============================================================================
echo [SUCCESS] Project pushed to GitHub!
echo You can now connect this GitHub URL to your Jenkins pipeline on AWS.
echo ==============================================================================
pause
