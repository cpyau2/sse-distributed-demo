@echo off
echo Starting Single Server Instance
echo =================================

echo.
echo This script will start only one backend instance for simple testing.
echo Perfect for basic development and testing.
echo.

pause

echo 1. Stopping any running processes...
taskkill /F /IM java.exe 2>nul
docker-compose down 2>nul

echo.
echo 2. Starting Redis...
docker-compose up redis -d

echo.
echo 3. Waiting for Redis to be ready...
timeout /t 5 /nobreak

echo.
echo 4. Starting Single Backend Instance (Port 8080)...
cd backend
start "Backend Server (Port 8080)" cmd /k "set SERVER_PORT=8080 && set INSTANCE_ID=backend-single && set INSTANCE_NAME=Backend-Single && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"

cd ..

echo.
echo 5. Waiting for backend to start...
timeout /t 15 /nobreak

echo.
echo 6. Starting Frontend...
cd frontend
start "Frontend (Port 5173)" cmd /k "npm run dev"
cd ..

echo.
echo ========================================
echo Single Server Setup Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend: http://localhost:8080
echo - Frontend: http://localhost:5173
echo.
echo Access the application at: http://localhost:5173
echo Backend health check: http://localhost:8080/actuator/health
echo ========================================

pause 