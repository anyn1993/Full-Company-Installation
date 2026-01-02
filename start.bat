@echo off
REM ===========================================
REM Start Script for Company Services (Windows)
REM ===========================================
REM Usage: start.bat
REM
REM This script will:
REM 1. Check if Docker is running
REM 2. Run initialization if needed
REM 3. Start all Docker services
REM ===========================================

echo ============================================
echo   Starting Company Services
echo ============================================
echo.

REM Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo [WARNING] No .env file found. Creating from template...
    echo.
    
    REM Create basic directories
    if not exist "odoo\conf" mkdir odoo\conf
    if not exist "odoo\web_data" mkdir odoo\web_data
    if not exist "odoo\extra-addons" mkdir odoo\extra-addons
    if not exist "odoo\db_data" mkdir odoo\db_data
    if not exist "odoo\addons\web" mkdir odoo\addons\web
    if not exist "odoo\addons\reporting-engine" mkdir odoo\addons\reporting-engine
    if not exist "odoo\addons\manufacture" mkdir odoo\addons\manufacture
    if not exist "odoo\addons\purchase-workflow" mkdir odoo\addons\purchase-workflow
    if not exist "odoo\addons\icons" mkdir odoo\addons\icons
    if not exist "open-sign-forms\mongodb-data" mkdir open-sign-forms\mongodb-data
    if not exist "open-sign-forms\opensign-files" mkdir open-sign-forms\opensign-files
    if not exist "nextcloud\html" mkdir nextcloud\html
    if not exist "nextcloud\data" mkdir nextcloud\data
    if not exist "nextcloud\config" mkdir nextcloud\config
    if not exist "nextcloud\custom_apps" mkdir nextcloud\custom_apps
    if not exist "nextcloud\db_data" mkdir nextcloud\db_data
    if not exist "mattermost\db_data" mkdir mattermost\db_data
    if not exist "portainer\data" mkdir portainer\data
    if not exist "caddy\html" mkdir caddy\html
    
    echo Directories created.
    echo.
    
    REM Copy .env.example to .env if it exists
    if exist ".env.example" (
        copy .env.example .env > nul
        echo Created .env from .env.example
    ) else (
        echo [ERROR] No .env.example file found. Please create a .env file manually.
        pause
        exit /b 1
    )
    
    echo.
    echo [IMPORTANT] Please edit .env with your domain and settings, then run this script again.
    echo.
    pause
    exit /b 0
)

REM Create directories if they don't exist
if not exist "odoo\conf" mkdir odoo\conf
if not exist "nextcloud\html" mkdir nextcloud\html

REM Start all services
echo Starting Docker services...
echo.

docker compose up -d

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to start services. Check the error above.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   All services started!
echo ============================================
echo.
echo Your services are starting up. It may take a few minutes for SSL certificates to be issued.
echo.
echo Check your .env file for the configured domain.
echo.
echo To view logs:  docker compose logs -f
echo To stop:       stop.bat
echo.
pause

