# Step 1: Build the application using Maven with Java 21
FROM maven:3.9.4-eclipse-temurin-21 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (cache layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Package the application
RUN mvn clean package -DskipTests

# Step 2: Run the application in a lightweight Java 21 JRE
FROM eclipse-temurin:21-jre-alpine

# Set working directory
WORKDIR /app

# Copy the jar from the build stage
COPY --from=build /app/target/hello-web-1.0-SNAPSHOT.jar app.jar

# Expose port
EXPOSE 9090

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

