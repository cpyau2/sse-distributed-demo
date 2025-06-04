@echo off
echo Fix SSL Version or Cipher Mismatch Error
echo ========================================

echo.
echo This script will help fix the ERR_SSL_VERSION_OR_CIPHER_MISMATCH error
echo by switching to HTTP mode for development.
echo.

pause

echo 1. Stopping any running Docker containers...
docker-compose down

echo.
echo 2. Killing any Java processes...
taskkill /F /IM java.exe 2>nul

echo.
echo 3. Starting Redis...
docker-compose up redis -d

echo.
echo 4. Waiting for Redis to be ready...
timeout /t 10 /nobreak

echo.
echo 5. Starting backend on HTTP (port 8080)...
cd backend
start "Backend Server" cmd /k "gradlew.bat bootRun --no-daemon"
cd ..

echo.
echo 6. Waiting for backend to start...
timeout /t 15 /nobreak

echo.
echo 7. Starting frontend on HTTP (port 5173)...
cd frontend
start "Frontend Server" cmd /k "npm run dev"
cd ..

echo.
echo ========================================
echo All services should now be running on HTTP:
echo - Backend: http://localhost:8080
echo - Frontend: http://localhost:5173
echo - Redis: localhost:6379
echo.
echo You can now access the application at:
echo http://localhost:5173
echo.
echo No more SSL errors! 
echo ========================================

pause 