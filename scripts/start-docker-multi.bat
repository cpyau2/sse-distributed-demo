@echo off
echo Starting Docker Multi-Instance Deployment
echo ==========================================

echo.
echo This script will start all services using Docker Compose
echo with multiple backend instances.
echo.

pause

echo 1. Stopping any existing containers...
docker-compose down

echo.
echo 2. Building images (this may take a few minutes)...
docker-compose build

echo.
echo 3. Starting all services...
docker-compose up -d

echo.
echo 4. Waiting for services to be ready...
timeout /t 30 /nobreak

echo.
echo 5. Checking service status...
docker-compose ps

echo.
echo 6. Testing backend instances...
echo Testing Backend-1:
docker exec sse-distributed-demo-backend-1-1 curl -f http://localhost:8080/actuator/health 2>nul && echo "✓ Backend-1 is healthy" || echo "✗ Backend-1 is not ready"

echo Testing Backend-2:
docker exec sse-distributed-demo-backend-2-1 curl -f http://localhost:8080/actuator/health 2>nul && echo "✓ Backend-2 is healthy" || echo "✗ Backend-2 is not ready"

echo Testing Backend-3:
docker exec sse-distributed-demo-backend-3-1 curl -f http://localhost:8080/actuator/health 2>nul && echo "✓ Backend-3 is healthy" || echo "✗ Backend-3 is not ready"

echo.
echo ========================================
echo Docker Multi-Instance Deployment Complete!
echo.
echo Services running:
echo - Redis: localhost:6379
echo - Backend-1: http://localhost:8080
echo - Backend-2: http://localhost:8081  
echo - Backend-3: http://localhost:8082
echo - Nginx (Load Balancer): http://localhost:80
echo - Frontend: http://localhost:3000
echo.
echo Access the application at: http://localhost:3000
echo Monitor with: docker-compose logs -f
echo ========================================

pause 