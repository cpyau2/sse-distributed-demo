@echo off

echo Stopping All SSE Demo Services
echo ===============================

echo.
echo 1. Stopping Docker containers...
if exist docker-compose-prod.yml (
    echo Detected docker-compose-prod.yml, stopping prod containers...
    docker-compose -f docker-compose-prod.yml down
) else (
    echo No docker-compose-prod.yml found, stopping default containers...
    docker-compose down
)

echo.
echo 2. Stopping Java processes...
taskkill /F /IM java.exe 2>nul

echo.
echo 3. Stopping Node.js processes (frontend)...
taskkill /F /IM node.exe 2>nul

echo.
echo 4. Checking remaining processes...
echo Active Java processes:
tasklist /FI "IMAGENAME eq java.exe" 2>nul | find "java.exe" || echo No Java processes running

echo.
echo Active Node processes:
tasklist /FI "IMAGENAME eq node.exe" 2>nul | find "node.exe" || echo No Node processes running

echo.
echo Active Docker containers:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr sse || echo No SSE demo containers running

echo.
echo ========================================
echo All services stopped successfully!
echo ========================================

pause 