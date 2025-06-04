# Build stage
FROM node:18-alpine AS build
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build application with verbose output
RUN npm run build --verbose

# Production stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Install openssl for SSL certificate generation
RUN apk add --no-cache openssl

# Create directory for certificates
RUN mkdir -p /etc/nginx/conf.d

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/conf.d/server.key \
    -out /etc/nginx/conf.d/server.crt \
    -subj "/C=US/ST=CA/L=San Francisco/O=MyOrg/OU=MyUnit/CN=localhost"

# Remove default nginx static assets
RUN rm -rf ./*

# Copy built application from build stage
COPY --from=build /app/dist .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]