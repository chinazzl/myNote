好的,我给你一个完整的Spring Cloud Gateway实例,基于SpringBoot 3和Spring Cloud 2022.x版本。

## 项目结构

```
gateway-demo/
├── pom.xml
└── src/
    └── main/
        ├── java/
        │   └── com/
        │       └── example/
        │           └── gateway/
        │               ├── GatewayApplication.java
        │               ├── config/
        │               │   ├── GatewayConfig.java
        │               │   └── CorsConfig.java
        │               ├── filter/
        │               │   ├── AuthGlobalFilter.java
        │               │   └── LogGlobalFilter.java
        │               └── handler/
        │                   └── GlobalExceptionHandler.java
        └── resources/
            └── application.yml
```

## 1. pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>gateway-demo</artifactId>
    <version>1.0.0</version>
    <name>gateway-demo</name>
    <description>Spring Cloud Gateway Demo</description>
    
    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2023.0.0</spring-cloud.version>
    </properties>
    
    <dependencies>
        <!-- Spring Cloud Gateway -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>
        
        <!-- Nacos服务发现(可选,如果需要服务发现) -->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
            <version>2022.0.0.0</version>
        </dependency>
        
        <!-- 负载均衡 -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-loadbalancer</artifactId>
        </dependency>
        
        <!-- Redis限流(可选) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
        </dependency>
        
        <!-- JSON处理 -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- 配置处理器 -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>
    </dependencies>
    
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

## 2. application.yml

```yaml
server:
  port: 9999

spring:
  application:
    name: api-gateway
  
  # Redis配置(用于限流)
  redis:
    host: localhost
    port: 6379
    password: 
    database: 0
  
  # Nacos配置(可选,如果使用服务发现)
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
        namespace: public
        group: DEFAULT_GROUP
    
    # Gateway配置
    gateway:
      # 全局CORS配置
      globalcors:
        cors-configurations:
          '[/**]':
            allowed-origins: "*"
            allowed-methods: "*"
            allowed-headers: "*"
            allow-credentials: true
            max-age: 3600
      
      # 路由配置
      routes:
        # 用户服务路由
        - id: user-service
          uri: lb://user-service  # lb表示从注册中心获取服务
          predicates:
            - Path=/api/user/**
          filters:
            - StripPrefix=2  # 去掉前缀/api/user
            - name: RequestRateLimiter  # 限流
              args:
                redis-rate-limiter.replenishRate: 10  # 令牌桶每秒填充速率
                redis-rate-limiter.burstCapacity: 20  # 令牌桶总容量
                key-resolver: "#{@ipKeyResolver}"  # 根据IP限流
        
        # 订单服务路由
        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/api/order/**
          filters:
            - StripPrefix=2
            - name: CircuitBreaker  # 熔断
              args:
                name: orderCircuitBreaker
                fallbackUri: forward:/fallback/order
        
        # 静态路由示例(直接指定URL)
        - id: external-api
          uri: https://api.example.com
          predicates:
            - Path=/external/**
          filters:
            - StripPrefix=1
            - AddRequestHeader=X-Request-Source, Gateway
        
        # 基于请求头的路由
        - id: header-route
          uri: lb://special-service
          predicates:
            - Path=/api/special/**
            - Header=X-Request-Type, special
          filters:
            - StripPrefix=2
        
        # 基于请求参数的路由
        - id: query-route
          uri: lb://query-service
          predicates:
            - Path=/api/search/**
            - Query=version, v2
          filters:
            - StripPrefix=2
      
      # 默认过滤器(应用到所有路由)
      default-filters:
        - AddResponseHeader=X-Response-From, Gateway
        - name: Retry  # 重试
          args:
            retries: 3
            statuses: BAD_GATEWAY,GATEWAY_TIMEOUT
            methods: GET,POST
            backoff:
              firstBackoff: 10ms
              maxBackoff: 50ms
              factor: 2
              basedOnPreviousValue: false

# 日志配置
logging:
  level:
    org.springframework.cloud.gateway: DEBUG
    org.springframework.web.reactive: DEBUG
    reactor.netty: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"

# 管理端点配置
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    gateway:
      enabled: true
```

## 3. 主启动类

```java
package com.example.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient  // 启用服务发现
public class GatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }
}
```

## 4. 编程式路由配置

```java
package com.example.gateway.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayConfig {
    
    /**
     * 编程式路由配置(可选,与yml配置二选一或结合使用)
     */
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                // 产品服务路由
                .route("product-service", r -> r
                        .path("/api/product/**")
                        .filters(f -> f
                                .stripPrefix(2)
                                .addRequestHeader("X-Gateway-Route", "product")
                                .circuitBreaker(config -> config
                                        .setName("productCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/product"))
                        )
                        .uri("lb://product-service")
                )
                
                // 重写路径示例
                .route("rewrite-path", r -> r
                        .path("/v1/api/**")
                        .filters(f -> f
                                .rewritePath("/v1/api/(?<segment>.*)", "/api/${segment}")
                        )
                        .uri("lb://backend-service")
                )
                
                // 添加请求参数
                .route("add-param", r -> r
                        .path("/api/public/**")
                        .filters(f -> f
                                .addRequestParameter("source", "gateway")
                        )
                        .uri("lb://public-service")
                )
                
                .build();
    }
    
    /**
     * IP限流Key解析器
     */
    @Bean
    public org.springframework.cloud.gateway.filter.ratelimit.KeyResolver ipKeyResolver() {
        return exchange -> reactor.core.publisher.Mono.just(
                exchange.getRequest()
                        .getRemoteAddress()
                        .getAddress()
                        .getHostAddress()
        );
    }
    
    /**
     * 用户限流Key解析器(基于用户ID)
     */
    @Bean
    public org.springframework.cloud.gateway.filter.ratelimit.KeyResolver userKeyResolver() {
        return exchange -> reactor.core.publisher.Mono.just(
                exchange.getRequest()
                        .getHeaders()
                        .getFirst("userId") != null 
                        ? exchange.getRequest().getHeaders().getFirst("userId")
                        : "anonymous"
        );
    }
}
```

## 5. 全局过滤器 - 认证过滤器

```java
package com.example.gateway.filter;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class AuthGlobalFilter implements GlobalFilter, Ordered {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    // 白名单路径,不需要认证
    private static final List<String> WHITE_LIST = List.of(
            "/api/user/login",
            "/api/user/register",
            "/external",
            "/fallback"
    );
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getURI().getPath();
        
        log.info("请求路径: {}", path);
        
        // 检查是否在白名单中
        if (isWhiteList(path)) {
            return chain.filter(exchange);
        }
        
        // 获取Token
        String token = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        
        if (!StringUtils.hasText(token)) {
            log.warn("未携带Token,路径: {}", path);
            return unauthorizedResponse(exchange, "未授权,请先登录");
        }
        
        // 验证Token(这里简化处理,实际应该调用认证服务)
        if (!validateToken(token)) {
            log.warn("Token验证失败,路径: {}", path);
            return unauthorizedResponse(exchange, "Token无效或已过期");
        }
        
        // Token验证通过,可以将用户信息添加到请求头传递给下游服务
        ServerHttpRequest modifiedRequest = request.mutate()
                .header("X-User-Id", getUserIdFromToken(token))
                .header("X-User-Name", getUserNameFromToken(token))
                .build();
        
        return chain.filter(exchange.mutate().request(modifiedRequest).build());
    }
    
    @Override
    public int getOrder() {
        return -100;  // 优先级较高,先执行认证
    }
    
    /**
     * 检查是否在白名单中
     */
    private boolean isWhiteList(String path) {
        return WHITE_LIST.stream().anyMatch(path::startsWith);
    }
    
    /**
     * 验证Token(示例实现)
     */
    private boolean validateToken(String token) {
        // 实际项目中应该:
        // 1. 解析JWT Token
        // 2. 验证签名
        // 3. 检查过期时间
        // 4. 或者调用认证服务验证
        
        // 这里简化处理
        return token.startsWith("Bearer ") && token.length() > 20;
    }
    
    /**
     * 从Token获取用户ID
     */
    private String getUserIdFromToken(String token) {
        // 实际项目中从JWT中解析
        return "10001";
    }
    
    /**
     * 从Token获取用户名
     */
    private String getUserNameFromToken(String token) {
        // 实际项目中从JWT中解析
        return "testUser";
    }
    
    /**
     * 返回未授权响应
     */
    private Mono<Void> unauthorizedResponse(ServerWebExchange exchange, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        Map<String, Object> result = new HashMap<>();
        result.put("code", 401);
        result.put("message", message);
        result.put("timestamp", System.currentTimeMillis());
        
        try {
            byte[] bytes = objectMapper.writeValueAsBytes(result);
            DataBuffer buffer = response.bufferFactory().wrap(bytes);
            return response.writeWith(Mono.just(buffer));
        } catch (JsonProcessingException e) {
            log.error("JSON序列化失败", e);
            return response.setComplete();
        }
    }
}
```

## 6. 全局过滤器 - 日志过滤器

```java
package com.example.gateway.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Slf4j
@Component
public class LogGlobalFilter implements GlobalFilter, Ordered {
    
    private static final DateTimeFormatter FORMATTER = 
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        
        String requestPath = request.getURI().getPath();
        String method = request.getMethod().name();
        String remoteAddr = request.getRemoteAddress() != null 
                ? request.getRemoteAddress().getAddress().getHostAddress() 
                : "unknown";
        
        long startTime = System.currentTimeMillis();
        
        log.info("========== 请求开始 ==========");
        log.info("请求时间: {}", LocalDateTime.now().format(FORMATTER));
        log.info("请求方法: {}", method);
        log.info("请求路径: {}", requestPath);
        log.info("客户端IP: {}", remoteAddr);
        log.info("请求参数: {}", request.getURI().getQuery());
        
        return chain.filter(exchange).then(
                Mono.fromRunnable(() -> {
                    long endTime = System.currentTimeMillis();
                    long executeTime = endTime - startTime;
                    
                    log.info("========== 请求结束 ==========");
                    log.info("响应状态: {}", exchange.getResponse().getStatusCode());
                    log.info("执行时间: {} ms", executeTime);
                    log.info("================================");
                })
        );
    }
    
    @Override
    public int getOrder() {
        return -200;  // 最先执行
    }
}
```

## 7. 全局异常处理

```java
package com.example.gateway.handler;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        ServerHttpResponse response = exchange.getResponse();
        
        if (response.isCommitted()) {
            return Mono.error(ex);
        }
        
        log.error("网关异常:", ex);
        
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        Map<String, Object> result = new HashMap<>();
        result.put("timestamp", System.currentTimeMillis());
        result.put("path", exchange.getRequest().getURI().getPath());
        
        if (ex instanceof ResponseStatusException) {
            ResponseStatusException responseStatusException = (ResponseStatusException) ex;
            response.setStatusCode(responseStatusException.getStatusCode());
            result.put("code", responseStatusException.getStatusCode().value());
            result.put("message", responseStatusException.getReason());
        } else {
            response.setStatusCode(HttpStatus.INTERNAL_SERVER_ERROR);
            result.put("code", 500);
            result.put("message", "网关内部错误: " + ex.getMessage());
        }
        
        try {
            byte[] bytes = objectMapper.writeValueAsBytes(result);
            DataBuffer buffer = response.bufferFactory().wrap(bytes);
            return response.writeWith(Mono.just(buffer));
        } catch (JsonProcessingException e) {
            log.error("异常响应序列化失败", e);
            return response.setComplete();
        }
    }
}
```

## 8. CORS配置(可选,如果yml配置不够)

```java
package com.example.gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

@Configuration
public class CorsConfig {
    
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration config = new CorsConfiguration();
        
        // 允许的源
        config.addAllowedOrigin("http://localhost:8080");
        config.addAllowedOrigin("http://localhost:3000");
        
        // 允许的方法
        config.addAllowedMethod("*");
        
        // 允许的请求头
        config.addAllowedHeader("*");
        
        // 是否允许携带Cookie
        config.setAllowCredentials(true);
        
        // 预检请求的有效期(秒)
        config.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        
        return new CorsWebFilter(source);
    }
}
```

## 9. 降级处理Controller(可选)

```java
package com.example.gateway.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/fallback")
public class FallbackController {
    
    @GetMapping("/order")
    public Mono<Map<String, Object>> orderFallback() {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 503);
        result.put("message", "订单服务暂时不可用,请稍后重试");
        result.put("timestamp", System.currentTimeMillis());
        return Mono.just(result);
    }
    
    @GetMapping("/product")
    public Mono<Map<String, Object>> productFallback() {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 503);
        result.put("message", "产品服务暂时不可用,请稍后重试");
        result.put("timestamp", System.currentTimeMillis());
        return Mono.just(result);
    }
}
```

## 测试方式

启动网关后,可以通过以下方式测试:

```bash
# 1. 测试用户服务(需要Token)
curl -X GET http://localhost:9999/api/user/info \
  -H "Authorization: Bearer your-token-here"

# 2. 测试白名单路径(不需要Token)
curl -X POST http://localhost:9999/api/user/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'

# 3. 查看网关路由信息
curl http://localhost:9999/actuator/gateway/routes

# 4. 刷新路由
curl -X POST http://localhost:9999/actuator/gateway/refresh
```

这个完整示例包含了Spring Cloud Gateway的主要功能,你可以根据实际需求进行调整和扩展。