@echo off
echo Generating SSL certificates for HTTP/2...

rem Create directories if they don't exist
if not exist "backend\src\main\resources\ssl" mkdir "backend\src\main\resources\ssl"
if not exist "nginx\ssl" mkdir "nginx\ssl"

rem Generate private key for Nginx (using openssl if available, otherwise suggest manual creation)
echo Checking for OpenSSL...
where openssl >nul 2>nul
if %errorlevel% == 0 (
    echo Found OpenSSL, generating certificates...
    
    rem Generate private key for Nginx
    openssl genrsa -out nginx\ssl\server.key 2048
    
    rem Generate certificate signing request
    openssl req -new -key nginx\ssl\server.key -out nginx\ssl\server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    
    rem Generate self-signed certificate for Nginx
    openssl x509 -req -days 365 -in nginx\ssl\server.csr -signkey nginx\ssl\server.key -out nginx\ssl\server.crt
    
    rem Clean up CSR file
    del nginx\ssl\server.csr
    
    echo Nginx certificates generated successfully!
) else (
    echo OpenSSL not found. Please install OpenSSL or use the manual method.
    echo You can download OpenSSL from: https://slproweb.com/products/Win32OpenSSL.html
)

rem Generate keystore for Spring Boot using Java keytool
echo Generating Spring Boot keystore...
keytool -genkeypair -alias sse-demo -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore backend\src\main\resources\ssl\keystore.p12 -validity 365 -storepass changeit -keypass changeit -dname "CN=localhost, OU=SSE Demo, O=Example Corp, L=City, ST=State, C=US"

if %errorlevel% == 0 (
    echo Spring Boot keystore generated successfully!
    echo.
    echo SSL certificates generated successfully!
    echo Nginx certificates: nginx\ssl\
    echo Spring Boot keystore: backend\src\main\resources\ssl\keystore.p12
) else (
    echo Failed to generate Spring Boot keystore. Please check if Java keytool is available.
)

pause 