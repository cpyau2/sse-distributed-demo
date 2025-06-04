@echo off
echo Testing HTTP/2 Support
echo ======================

echo.
echo 1. Testing Nginx Load Balancer HTTP/2 support...
echo Testing health endpoint:
curl -k -s -I -w "HTTP Version: %%{http_version}\n" https://localhost:443/health
echo.

echo 2. Testing Backend-1 HTTP/2 support...
echo Testing actuator health:
curl -k -s -I -w "HTTP Version: %%{http_version}\n" https://localhost:8443/actuator/health
echo.

echo 3. Testing Backend-2 HTTP/2 support...
curl -k -s -I -w "HTTP Version: %%{http_version}\n" https://localhost:8444/actuator/health
echo.

echo 4. Testing Backend-3 HTTP/2 support...
curl -k -s -I -w "HTTP Version: %%{http_version}\n" https://localhost:8445/actuator/health
echo.

echo 5. Detailed HTTP/2 test with verbose output (Nginx):
curl -k -v https://localhost:443/health 2>&1 | findstr "HTTP/2"
echo.

echo 6. Detailed HTTP/2 test with verbose output (Backend-1):
curl -k -v https://localhost:8443/actuator/health 2>&1 | findstr "HTTP/2"
echo.

echo 7. Testing SSE endpoint through HTTP/2 load balancer:
echo Checking if SSE endpoint is accessible:
curl -k -s -I https://localhost:443/api/sse/stream
echo.

echo 8. Testing broadcast endpoint through HTTP/2:
echo Sending test message:
curl -k -X POST https://localhost:443/api/sse/broadcast -H "Content-Type: application/json" -d "{\"type\":\"HTTP2_TEST\",\"data\":{\"message\":\"Testing HTTP/2 broadcast\",\"protocol\":\"HTTP/2\"}}"
echo.

echo 9. Server metrics through HTTP/2:
curl -k -s https://localhost:443/api/sse/metrics
echo.

echo ========================================
echo HTTP/2 Test Complete!
echo ========================================
echo.
echo If you see "HTTP/2" in the verbose output above,
echo then HTTP/2 is working correctly!
echo.
echo HTTP Version codes:
echo • 1.1 = HTTP/1.1
echo • 2 = HTTP/2
echo ========================================

pause 