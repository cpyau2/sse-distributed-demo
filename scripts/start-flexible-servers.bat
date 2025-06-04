@echo off
echo Flexible Server Startup
echo ========================

echo.
echo Choose deployment mode:
echo 1) Local development (Single instance - Port 8080)
echo 2) Local development (Two instances - Ports 8080, 8081)  
echo 3) Local development (Three instances - Ports 8080, 8081, 8082)
echo 4) Docker with Load Balancer (Complete system with nginx)
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto single
if "%choice%"=="2" goto dual
if "%choice%"=="3" goto triple
if "%choice%"=="4" goto docker_with_lb

echo Invalid choice. Starting single instance by default.
goto single

:docker_with_lb
echo.
echo Starting Docker System with Load Balancer...
echo =============================================

echo 1. Stopping any running containers...
docker-compose down

echo.
echo 2. Building and starting all services (Redis + 3 Backend instances + Nginx Load Balancer + Frontend)...
docker-compose up --build -d

echo.
echo 3. Waiting for services to be ready...
timeout /t 30 /nobreak

echo.
echo 4. Checking service status...
docker-compose ps

echo.
echo ========================================
echo Docker System with Load Balancer Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend instances: 3 instances (internal)
echo - Load Balancer (nginx): http://localhost:80
echo - Frontend: http://localhost:3000
echo.
echo API endpoints through load balancer:
echo - http://localhost/api/events (SSE endpoint)
echo - http://localhost/api/broadcast (broadcast endpoint)
echo - http://localhost/health (load balancer health)
echo ========================================
goto end

:single
echo.
echo Starting Single Instance...
echo ===========================

echo 1. Stopping Java processes...
taskkill /F /IM java.exe 2>nul

echo.
echo 2. Checking Redis status...
docker ps --filter "name=redis" --format "{{.Names}}" | findstr /i "redis" >nul 2>&1
if %errorlevel%==0 (
    echo Redis is already running, skipping restart...
) else (
    echo Redis not running, starting Redis...
    docker-compose down 2>nul
    docker-compose up redis -d
    echo.
    echo 3. Waiting for Redis to be ready...
    timeout /t 5 /nobreak
)

echo.
echo 4. Starting Backend Instance (Port 8080)...
cd backend
start "Backend-1 (Port 8080)" cmd /k "set SERVER_PORT=8080 && set INSTANCE_ID=backend-1 && set INSTANCE_NAME=Backend-1 && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"
cd ..

echo.
echo 5. Waiting for backend to start...
timeout /t 15 /nobreak
goto start_frontend

:dual
echo.
echo Starting Two Instances...
echo =========================

echo 1. Stopping Java processes...
taskkill /F /IM java.exe 2>nul

echo.
echo 2. Checking Redis status...
docker ps --filter "name=redis" --format "{{.Names}}" | findstr /i "redis" >nul 2>&1
if %errorlevel%==0 (
    echo Redis is already running, skipping restart...
) else (
    echo Redis not running, starting Redis...
    docker-compose down 2>nul
    docker-compose up redis -d
    echo.
    echo 3. Waiting for Redis to be ready...
    timeout /t 5 /nobreak
)

echo.
echo 4. Starting Backend Instance 1 (Port 8080)...
cd backend
start "Backend-1 (Port 8080)" cmd /k "set SERVER_PORT=8080 && set INSTANCE_ID=backend-1 && set INSTANCE_NAME=Backend-1 && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"

echo.
echo 5. Waiting 10 seconds before starting next instance...
timeout /t 10 /nobreak

echo.
echo 6. Starting Backend Instance 2 (Port 8081)...
start "Backend-2 (Port 8081)" cmd /k "set SERVER_PORT=8081 && set INSTANCE_ID=backend-2 && set INSTANCE_NAME=Backend-2 && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"
cd ..

echo.
echo 7. Waiting for backends to start...
timeout /t 15 /nobreak
goto start_frontend

:triple
echo.
echo Starting Three Instances...
echo ===========================

echo 1. Stopping Java processes...
taskkill /F /IM java.exe 2>nul

echo.
echo 2. Checking Redis status...
docker ps --filter "name=redis" --format "{{.Names}}" | findstr /i "redis" >nul 2>&1
if %errorlevel%==0 (
    echo Redis is already running, skipping restart...
) else (
    echo Redis not running, starting Redis...
    docker-compose down 2>nul
    docker-compose up redis -d
    echo.
    echo 3. Waiting for Redis to be ready...
    timeout /t 5 /nobreak
)

echo.
echo 4. Starting Backend Instance 1 (Port 8080)...
cd backend
start "Backend-1 (Port 8080)" cmd /k "set SERVER_PORT=8080 && set INSTANCE_ID=backend-1 && set INSTANCE_NAME=Backend-1 && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"

echo.
echo 5. Waiting 10 seconds before starting next instance...
timeout /t 10 /nobreak

echo.
echo 6. Starting Backend Instance 2 (Port 8081)...
start "Backend-2 (Port 8081)" cmd /k "set SERVER_PORT=8081 && set INSTANCE_ID=backend-2 && set INSTANCE_NAME=Backend-2 && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"

echo.
echo 7. Waiting 10 seconds before starting next instance...
timeout /t 10 /nobreak

echo.
echo 8. Starting Backend Instance 3 (Port 8082)...
start "Backend-3 (Port 8082)" cmd /k "set SERVER_PORT=8082 && set INSTANCE_ID=backend-3 && set INSTANCE_NAME=Backend-3 && set SPRING_DATA_REDIS_HOST=localhost && .\gradlew bootRun --no-daemon"
cd ..

echo.
echo 9. Waiting for all backends to start...
timeout /t 15 /nobreak
goto start_frontend

:start_frontend
echo.
echo Starting Frontend...
cd frontend
start "Frontend (Port 5173)" cmd /k "npm run dev"
cd ..

if "%choice%"=="1" goto single_complete
if "%choice%"=="2" goto dual_complete
if "%choice%"=="3" goto triple_complete

:single_complete
echo.
echo ========================================
echo Single Server Setup Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend: http://localhost:8080
echo - Frontend: http://localhost:5173
echo ========================================
goto end

:dual_complete
echo.
echo ========================================
echo Dual Server Setup Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend-1: http://localhost:8080
echo - Backend-2: http://localhost:8081
echo - Frontend: http://localhost:5173
echo.
echo Note: For load balancing, consider using option 4 (Docker with Load Balancer)
echo ========================================
goto end

:triple_complete
echo.
echo ========================================
echo Triple Server Setup Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend-1: http://localhost:8080
echo - Backend-2: http://localhost:8081
echo - Backend-3: http://localhost:8082
echo - Frontend: http://localhost:5173
echo.
echo Note: For load balancing, consider using option 4 (Docker with Load Balancer)
echo ========================================

:end
pause 