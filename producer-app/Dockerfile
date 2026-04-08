FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /workspace/target/producer-app-1.0.0.jar /app/producer-app.jar
ENTRYPOINT ["java", "-jar", "/app/producer-app.jar"]
