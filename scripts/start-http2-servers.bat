@echo off
echo Starting HTTP/2 SSE Distributed Demo
echo ====================================

echo.
echo This will start the complete HTTP/2 enabled system with:
echo • Redis server
echo • 3 Backend instances (HTTPS + HTTP/2)
echo • Nginx Load Balancer (HTTPS + HTTP/2)
echo • Frontend
echo.

pause

echo.
echo 1. Stopping any existing containers...
docker-compose -f docker-compose.yml down 2>nul
docker-compose -f docker-compose-http2.yml down 2>nul

echo.
echo 2. Building and starting HTTP/2 system...
docker-compose -f docker-compose-http2.yml up --build -d

echo.
echo 3. Waiting for services to be ready...
timeout /t 30 /nobreak

echo.
echo 4. Checking service status...
docker-compose -f docker-compose-http2.yml ps

echo.
echo ========================================
echo HTTP/2 System Started Successfully!
echo ========================================
echo.
echo Services running:
echo • Redis: localhost:6379
echo • Backend-1 HTTPS: https://localhost:8443 (HTTP/2)
echo • Backend-2 HTTPS: https://localhost:8444 (HTTP/2)
echo • Backend-3 HTTPS: https://localhost:8445 (HTTP/2)
echo • Nginx Load Balancer: https://localhost:443 (HTTP/2)
echo • Frontend: https://localhost:3443
echo.
echo HTTP/2 API endpoints:
echo • https://localhost:443/api/sse/stream (SSE endpoint)
echo • https://localhost:443/api/sse/broadcast (broadcast endpoint)
echo • https://localhost:443/health (load balancer health)
echo.
echo Test HTTP/2 support:
echo • curl -k -I -w "%%{http_version}\n" https://localhost:443/health
echo • curl -k -I -w "%%{http_version}\n" https://localhost:8443/actuator/health
echo ========================================

pause 