FROM openjdk:8-jdk-alpine
ARG JAR_FILE=target/chetan_motor-0.0.1-SNAPSHOT.jar
COPY ${JAR_FILE} chetan_motor-0.0.1-SNAPSHOT.jar
ENTRYPOINT ["java","-jar","/chetan_motor-0.0.1-SNAPSHOT.jar"]