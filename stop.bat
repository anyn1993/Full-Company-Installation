@echo off
REM ===========================================
REM Stop Script for Company Services (Windows)
REM ===========================================
REM Usage: stop.bat
REM
REM This script will stop all Docker services gracefully.
REM Data is preserved and services can be restarted with start.bat
REM ===========================================

echo ============================================
echo   Stopping Company Services
echo ============================================
echo.

REM Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Docker is not running. Nothing to stop.
    pause
    exit /b 0
)

REM Stop all services
echo Stopping Docker services...
echo.

docker compose down

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to stop services. Check the error above.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   All services stopped!
echo ============================================
echo.
echo Your data has been preserved.
echo.
echo To start again:  start.bat
echo To remove data:  docker compose down -v  (WARNING: DESTRUCTIVE)
echo.
pause

