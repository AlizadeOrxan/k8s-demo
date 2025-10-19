# 1. Java-nın yüngül versiyası ilə başla
FROM openjdk:17-jdk-slim

# 2. JAR faylının yolunu Gradle-ın standart çıxış qovluğuna dəyişdiririk
ARG JAR_FILE=build/libs/*.jar

# 3. JAR faylını konteynerin içərisinə 'app.jar' adı ilə kopyala
COPY ${JAR_FILE} app.jar

# 4. Tətbiqin xaricə açıq olacağı port
EXPOSE 8080

# 5. Konteyner işə düşəndə Spring Boot tətbiqini işə salan əmr
ENTRYPOINT ["java","-jar","/app.jar"]