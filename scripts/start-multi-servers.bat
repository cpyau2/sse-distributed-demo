@echo off
echo Starting Multiple Local Servers
echo =================================

echo.
echo This script will start multiple backend instances locally for testing.
echo Each instance will run on a different port.
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
echo 4. Starting Backend Instance 1 (Port 8080)...
cd backend
start "Backend-1 (Port 8080)" cmd /k "set SERVER_PORT=8080 && set INSTANCE_ID=backend-1 && set INSTANCE_NAME=Backend-1 && set SPRING_DATA_REDIS_HOST=localhost && gradlew.bat bootRun --no-daemon"

echo.
echo 5. Waiting 10 seconds before starting next instance...
timeout /t 10 /nobreak

echo.
echo 6. Starting Backend Instance 2 (Port 8081)...
start "Backend-2 (Port 8081)" cmd /k "set SERVER_PORT=8081 && set INSTANCE_ID=backend-2 && set INSTANCE_NAME=Backend-2 && set SPRING_DATA_REDIS_HOST=localhost && gradlew.bat bootRun --no-daemon"

echo.
echo 7. Waiting 10 seconds before starting next instance...
timeout /t 10 /nobreak

echo.
echo 8. Starting Backend Instance 3 (Port 8082)...
start "Backend-3 (Port 8082)" cmd /k "set SERVER_PORT=8082 && set INSTANCE_ID=backend-3 && set INSTANCE_NAME=Backend-3 && set SPRING_DATA_REDIS_HOST=localhost && gradlew.bat bootRun --no-daemon"

cd ..

echo.
echo 9. Waiting for all backends to start...
timeout /t 15 /nobreak

echo.
echo 10. Starting Frontend...
cd frontend
start "Frontend (Port 5173)" cmd /k "npm run dev"
cd ..

echo.
echo ========================================
echo Multi-Server Setup Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend-1: http://localhost:8080
echo - Backend-2: http://localhost:8081  
echo - Backend-3: http://localhost:8082
echo - Frontend: http://localhost:5173
echo.
echo You can test SSE distribution across multiple instances!
echo ========================================

pause 