

##`k8s-demo` adlı Spring Boot tətbiqimi necə Docker konteynerinə yerləşdirib, daha sonra Docker Desktop istifadə edərək lokal Kubernetes klasterində işə saldığımı izah edirəm.

## Mərhələ 0: İlkin Şərtlər və Hazırlıq

**Java/Gradle:** Sistemimdə JDK 17 və Gradle quraşdırılıb.

**Docker Desktop:**
1.  Docker Desktop-u quraşdırmışam.
2.  **Settings → Kubernetes** bölməsindən **"Enable Kubernetes"** seçimini aktivləşdirmişəm.
3.  Klasterin hazır olduğunu `kubectl get nodes` əmri ilə yoxlamışam və `docker-desktop` node-u `Ready` statusundadır.

## Mərhələ 1: Spring Boot Tətbiqim

### Addım 1.1: Controller
Tətbiqimdə aşağıdakı kimi sadə bir `HelloController` var:

```java
// src/main/java/com/orkhan/k8sdemo/controller/HelloController.java
package com.orkhan.k8sdemo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return  "Hello World! - I'm using k8s just now ";
    }
}
```

### Addım 1.2: Tətbiqi Paketləmək
Layihəmin kök qovluğunda, tətbiqi icra edilə bilən JAR faylına paketləmək üçün bu əmri istifadə edirəm:

```bash
./gradlew clean build
```
*Nəticə: `build/libs/k8s-demo-0.0.1-SNAPSHOT.jar` faylı yaranır.*

## Mərhələ 2: Tətbiqi Dockerize Etmək

### Addım 2.1: Dockerfile
Proyektimin kök qovluğundakı `Dockerfile` belədir:

```dockerfile
# 1. Əsas İmic (Java 17-nin yüngül versiyası)
FROM openjdk:17-jdk-slim

# 2. 8080 portunu xaricə açmaq
EXPOSE 8080

# 3. JAR faylının yolunu arqument kimi qəbul etmək (Gradle üçün)
ARG JAR_FILE=build/libs/*.jar

# 4. JAR faylını konteynerə kopyalamaq
COPY ${JAR_FILE} app.jar

# 5. Konteyneri işə salmaq üçün əmr
ENTRYPOINT ["java","-jar","/app.jar"]
```

### Addım 2.2: Docker İmicini Yaratmaq
Tətbiqim üçün `k8s-demo` adlı Docker imicini bu əmrlə qururam:

```bash
docker build -t k8s-demo .
```
*Nəticə: `k8s-demo:latest` adlı imic lokal Docker registrimə əlavə olunur.*

## Mərhələ 3: Kubernetes Konfiqurasiya Fayllarım (Manifestlər)

### Addım 3.1: Deployment Manifesti (deployment.yaml)
Bu fayl tətbiqimin necə və harada işləyəcəyini təyin edir:

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-demo-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: spring-demo
  template:
    metadata:
      labels:
        app: spring-demo
    spec:
      containers:
      - name: spring-k8s-container
        # Addım 2.2-də yaratdığım imicin adı
        image: k8s-demo:latest
        # Lokal imici istifadə etmək üçün
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
```

### Addım 3.2: Service Manifesti (service.yaml)
Bu fayl tətbiqimə xaricdən girişi təmin edir:

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: spring-demo-service
spec:
  selector:
    # Deployment-dəki Podlara verdiyim etiketlə eynidir
    app: spring-demo
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  # Lokalda localhost-dan girişə icazə verir
  type: LoadBalancer
```

## Mərhələ 4: Kubernetes-ə Yerləşdirmə

Manifestləri klasterə bu əmrlərlə tətbiq edirəm:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

## Mərhələ 5: Yoxlama və Giriş

### Addım 5.1: Statusu Yoxlamaq
Hər şeyin qaydasında olduğunu bu əmrlərlə yoxlayıram:
```bash
kubectl get pods
kubectl get deployment
kubectl get service
```

### Addım 5.2: Tətbiqə Giriş
`LoadBalancer` service-i sayəsində tətbiqimə `localhost` üzərindən müraciət edə bilirəm.

Brauzerdə bu ünvana daxil oluram:
[http://localhost:8080/hello](http://localhost:8080/hello)

*Nəticə: "Hello World! - I'm using k8s just now " mesajını görürəm.*

## Təmizləmə

İşim bitdikdə resursları bu əmrlərlə silirəm:
```bash
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
```
