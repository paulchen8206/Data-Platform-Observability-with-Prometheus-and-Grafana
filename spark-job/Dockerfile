FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -q -DskipTests package

FROM apache/spark:3.5.1
WORKDIR /opt/app
COPY --from=build /workspace/target/spark-job-1.0.0.jar /opt/app/spark-job.jar
