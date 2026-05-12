FROM eclipse-temurin:21-jre-alpine

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /app
COPY app.jar app.jar

ENV SPRING_DATASOURCE_DRUID_MASTER_URL="jdbc:mysql://mysql:3306/ry_stridemoor?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true"
ENV SPRING_DATASOURCE_DRUID_MASTER_USERNAME="root"
ENV SPRING_DATASOURCE_DRUID_MASTER_PASSWORD="stridemoor_root_2026"
ENV SPRING_DATASOURCE_DRUID_SLAVE_URL="jdbc:mysql://mysql:3306/stridemoor?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true"
ENV SPRING_DATASOURCE_DRUID_SLAVE_USERNAME="root"
ENV SPRING_DATASOURCE_DRUID_SLAVE_PASSWORD="stridemoor_root_2026"
ENV SPRING_DATA_REDIS_HOST="stridemoor-redis"
ENV SPRING_DATA_REDIS_PORT="6379"

EXPOSE 8088

ENTRYPOINT ["java", "-jar", "app.jar"]
