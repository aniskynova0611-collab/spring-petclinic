# Multi-stage Dockerfile for Spring Petclinic (Maven-based build)

# ---- Build stage ----
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

# Use Maven wrapper if available to ensure reproducible build
COPY mvnw pom.xml .mvn/ ./
COPY .mvn .mvn
RUN chmod +x mvnw

# Download dependencies (leverages Docker layer caching)
RUN ./mvnw -B -ntp dependency:go-offline

# Copy source and build
COPY src ./src
RUN ./mvnw -B -ntp -DskipTests package

# ---- Run stage ----
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

# Create non-root user
RUN addgroup --system app && adduser --system --ingroup app app

# Copy jar from build stage
COPY --from=build /workspace/target/*.jar app.jar

# Expose default Spring Boot port
EXPOSE 8080

USER app

ENV JAVA_OPTS="-XX:+UseContainerSupport -XshowSettings:vm"
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]
