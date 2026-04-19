# ---- Build stage ----
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Copy Gradle wrapper and config first for better layer caching
COPY gradlew .
COPY gradle/ gradle/
COPY settings.gradle build.gradle ./

# Pre-download dependencies
RUN ./gradlew dependencies --no-daemon || true

# Copy source code and build
COPY src/ src/
RUN ./gradlew bootJar --no-daemon

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/build/libs/workshop-organizer-*.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
