#!/bin/bash

echo "Testing HTTP/2 Support..."
echo "========================="

# Test if HTTP/2 is supported
echo "1. Testing Spring Boot backend HTTP/2 support:"
curl -k -s -I -w "%{http_version}\n" https://localhost:8443/actuator/health | grep "HTTP/2"

echo ""
echo "2. Testing Nginx HTTP/2 support:"
curl -k -s -I -w "%{http_version}\n" https://localhost:443/health | grep "HTTP/2"

echo ""
echo "3. Testing with verbose output (Spring Boot):"
curl -k -v https://localhost:8443/actuator/health 2>&1 | grep "HTTP/2"

echo ""
echo "4. Testing with verbose output (Nginx):"
curl -k -v https://localhost:443/health 2>&1 | grep "HTTP/2"

echo ""
echo "5. Complete response headers from Spring Boot:"
curl -k -I https://localhost:8443/actuator/health

echo ""
echo "6. Complete response headers from Nginx:"
curl -k -I https://localhost:443/health 