#!/bin/bash

# Create directories if they don't exist
mkdir -p backend/src/main/resources/ssl
mkdir -p nginx/ssl

echo "Generating SSL certificates..."

# Generate private key for Nginx
openssl genrsa -out nginx/ssl/server.key 2048

# Generate certificate signing request
openssl req -new -key nginx/ssl/server.key -out nginx/ssl/server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Generate self-signed certificate for Nginx
openssl x509 -req -days 365 -in nginx/ssl/server.csr -signkey nginx/ssl/server.key -out nginx/ssl/server.crt

# Generate keystore for Spring Boot
keytool -genkeypair -alias sse-demo -keyalg RSA -keysize 2048 -storetype PKCS12 \
    -keystore backend/src/main/resources/ssl/keystore.p12 -validity 365 \
    -storepass changeit -keypass changeit \
    -dname "CN=localhost, OU=SSE Demo, O=Example Corp, L=City, ST=State, C=US"

# Clean up CSR file
rm nginx/ssl/server.csr

echo "SSL certificates generated successfully!"
echo "Nginx certificates: nginx/ssl/"
echo "Spring Boot keystore: backend/src/main/resources/ssl/keystore.p12" 