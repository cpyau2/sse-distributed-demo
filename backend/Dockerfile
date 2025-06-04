# Build stage
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copy gradle files
COPY gradle gradle
COPY gradlew .
COPY build.gradle .
COPY settings.gradle .

# Download dependencies
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src src

# Build application
RUN ./gradlew build -x test --no-daemon

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy jar from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Create non-root user
RUN addgroup -g 1000 spring && \
    adduser -u 1000 -G spring -s /bin/sh -D spring
USER spring:spring

# Expose port
EXPOSE 8080

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]