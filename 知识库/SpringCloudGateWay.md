# SpringCloud-GateWay 网关

1. 如果没有在调用`RouteLocator`的时候进行设置匹配path，则相当于全局使用gateway都会使用

## 为什么我设置了匹配path，也成功转发到了指定的服务中，但是还是找不到路径

```java
public RouteLocator requestHandlerRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()
            .route("add_request_header", r -> r.path("/testRequestHeader")
                    .filters(f -> f.addRequestHeader("X-Request_Acme", "ValueB"))
                    .uri("http://localhost:8010/test/gateway/addRequestHeader"))
            .build();

}
```

这个问题很有意思！你的配置确实会有这个现象，让我解释一下原因：

### 问题分析

你的路由配置：
```java
.route("add_request_header", r -> r.path("/testRequestHeader")
    .filters(f -> f.addRequestHeader("X-Request_Acme", "ValueB"))
    .uri("http://localhost:8010/test/gateway/addRequestHeader"))
```

**关键问题**：你把完整的路径 `/test/gateway/addRequestHeader` 放在了 `uri()` 中，这是错误的用法。

## 实际发生的事情

当你访问 `http://localhost:8011/testRequestHeader` 时：

1. **网关匹配路由**：匹配到 `path("/testRequestHeader")`
2. **添加请求头**：添加 `X-Request_Acme: ValueB`
3. **转发请求**：转发到 `http://localhost:8010/test/gateway/addRequestHeader/testRequestHeader`

**注意**：网关会把原始路径 `/testRequestHeader` **追加** 到目标 URI 后面！

所以实际的请求路径变成了：
```
http://localhost:8010/test/gateway/addRequestHeader/testRequestHeader
```

### 验证这个现象

在你的后端服务（8010）添加一个通配符路由来验证：

```java
@RestController
public class DebugController {
    
    @RequestMapping("/**")
    public ResponseEntity<Map<String, Object>> catchAll(HttpServletRequest request) {
        Map<String, Object> info = new HashMap<>();
        info.put("actualPath", request.getRequestURI());
        info.put("method", request.getMethod());
        info.put("headers", Collections.list(request.getHeaderNames()));
        
        System.out.println("实际接收到的路径: " + request.getRequestURI());
        return ResponseEntity.ok(info);
    }
}
```

### 正确的配置方式

#### 方案1：使用基础 URI + RewritePath 过滤器

```java
@Bean
public RouteLocator requestHandlerRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()
        .route("add_request_header", r -> r.path("/testRequestHeader")
            .filters(f -> f
                .addRequestHeader("X-Request_Acme", "ValueB")
                .rewritePath("/testRequestHeader", "/test/gateway/addRequestHeader"))
            .uri("http://localhost:8010"))  // 只包含基础地址
        .build();
}
```

#### 方案2：使用 StripPrefix 过滤器

```java
@Bean
public RouteLocator requestHandlerRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()
        .route("add_request_header", r -> r.path("/api/testRequestHeader")
            .filters(f -> f
                .addRequestHeader("X-Request_Acme", "ValueB")
                .stripPrefix(1)  // 去掉路径的第一部分 /api
                .prefixPath("/test/gateway/addRequestHeader"))  // 添加目标路径前缀
            .uri("http://localhost:8010"))
        .build();
}
```

### 方案3：使用配置文件方式（推荐）

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: add_request_header
          uri: http://localhost:8010
          predicates:
            - Path=/testRequestHeader
          filters:
            - AddRequestHeader=X-Request_Acme, ValueB
            - RewritePath=/testRequestHeader, /test/gateway/addRequestHeader
```

### Spring Cloud Gateway 的 URI 工作原理

**正确理解**：
- `uri()` 应该只包含 **目标服务的基础地址**（协议+主机+端口）
- **路径映射** 通过过滤器来处理（RewritePath、StripPrefix、PrefixPath 等）

**错误用法**：
```java
.uri("http://localhost:8010/test/gateway/addRequestHeader")  // ❌ 包含了路径
```

**正确用法**：
```java
.uri("http://localhost:8010")  // ✅ 只包含基础地址
.filters(f -> f.rewritePath("/source", "/target"))  // ✅ 路径通过过滤器处理
```

### 验证修正后的效果

修正配置后，再次测试：

1. **访问**：`http://localhost:8011/testRequestHeader`
2. **实际转发到**：`http://localhost:8010/test/gateway/addRequestHeader`
3. **请求头包含**：`X-Request_Acme: ValueB`

在后端服务中应该能看到正确的路径 `/test/gateway/addRequestHeader`，而不是之前的错误路径。

你现在能进入后端的过滤器，是因为你可能在后端配置了比较宽泛的路径匹配（比如 `/**`），所以即使路径不对也能匹配到。