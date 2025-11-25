# SpringBoot 项目实现入参解密和返回结果加密

我来为你介绍几种常用的实现方案：

## 方案一：使用请求响应体增强器（推荐）

这种方式通过 `RequestBodyAdvice` 和 `ResponseBodyAdvice` 来实现全局的加解密处理。

### 1. 创建自定义注解

```java
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Encrypt {
}

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Decrypt {
}
```

### 2. 实现请求体解密

```java
@ControllerAdvice
public class DecryptRequestBodyAdvice extends RequestBodyAdviceAdapter {

    @Autowired
    private CryptoService cryptoService;

    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType,
                          Class<? extends HttpMessageConverter<?>> converterType) {
        return methodParameter.hasMethodAnnotation(Decrypt.class) 
            || methodParameter.getDeclaringClass().isAnnotationPresent(Decrypt.class);
    }

    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage inputMessage, 
                                          MethodParameter parameter, 
                                          Type targetType,
                                          Class<? extends HttpMessageConverter<?>> converterType) 
                                          throws IOException {
        return new DecryptHttpInputMessage(inputMessage, cryptoService);
    }
}

class DecryptHttpInputMessage implements HttpInputMessage {
    private HttpHeaders headers;
    private InputStream body;

    public DecryptHttpInputMessage(HttpInputMessage inputMessage, CryptoService cryptoService) 
            throws IOException {
        this.headers = inputMessage.getHeaders();
        String encryptedData = IOUtils.toString(inputMessage.getBody(), StandardCharsets.UTF_8);
        String decryptedData = cryptoService.decrypt(encryptedData);
        this.body = new ByteArrayInputStream(decryptedData.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public InputStream getBody() {
        return body;
    }

    @Override
    public HttpHeaders getHeaders() {
        return headers;
    }
}
```

### 3. 实现响应体加密

```java
@ControllerAdvice
public class EncryptResponseBodyAdvice implements ResponseBodyAdvice<Object> {

    @Autowired
    private CryptoService cryptoService;

    @Override
    public boolean supports(MethodParameter returnType, 
                          Class<? extends HttpMessageConverter<?>> converterType) {
        return returnType.hasMethodAnnotation(Encrypt.class)
            || returnType.getDeclaringClass().isAnnotationPresent(Encrypt.class);
    }

    @Override
    public Object beforeBodyWrite(Object body, 
                                 MethodParameter returnType,
                                 MediaType selectedContentType,
                                 Class<? extends HttpMessageConverter<?>> selectedConverterType,
                                 ServerHttpRequest request,
                                 ServerHttpResponse response) {
        if (body == null) { 
            return null;
        }
        
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            String jsonData = objectMapper.writeValueAsString(body);
            String encryptedData = cryptoService.encrypt(jsonData);
            
            // 返回加密后的数据结构
            Map<String, String> result = new HashMap<>();
            result.put("data", encryptedData);
            return result;
        } catch (Exception e) {
            throw new RuntimeException("加密失败", e);
        }
    }
}
```

### 4. 加密服务实现（AES示例）

```java
@Service
public class CryptoService {

    private static final String ALGORITHM = "AES";
    private static final String TRANSFORMATION = "AES/CBC/PKCS5Padding";
    
    @Value("${crypto.secret-key}")
    private String secretKey;
    
    @Value("${crypto.iv}")
    private String iv;

    public String encrypt(String data) {
        try {
            SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), ALGORITHM);
            IvParameterSpec ivSpec = new IvParameterSpec(iv.getBytes());
            
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivSpec);
            
            byte[] encrypted = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(encrypted);
        } catch (Exception e) {
            throw new RuntimeException("加密失败", e);
        }
    }

    public String decrypt(String encryptedData) {
        try {
            SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), ALGORITHM);
            IvParameterSpec ivSpec = new IvParameterSpec(iv.getBytes());
            
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
            
            byte[] decrypted = cipher.doFinal(Base64.getDecoder().decode(encryptedData));
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new RuntimeException("解密失败", e);
        }
    }
}
```

### 5. 在 Controller 中使用

```java
@RestController
@RequestMapping("/api")
public class UserController {

    @PostMapping("/user")
    @Decrypt  // 请求参数自动解密
    @Encrypt  // 响应结果自动加密
    public ResponseEntity<User> createUser(@RequestBody User user) {
        // 这里的 user 已经是解密后的对象
        // 业务逻辑处理
        return ResponseEntity.ok(user);
    }
}
```

### 6. 配置文件

```yaml
crypto:
  secret-key: 1234567890123456  # 16字节密钥
  iv: 1234567890123456          # 16字节IV
```

## 方案二：使用拦截器

如果需要更细粒度的控制，可以使用拦截器配合自定义注解实现。

## 方案三：使用过滤器

对于需要在 Spring MVC 之前处理的场景，可以使用 Filter 实现。

## 注意事项

1. **密钥管理**：不要将密钥硬编码，使用配置中心或密钥管理服务
2. **性能考虑**：加解密会影响性能，考虑使用缓存或异步处理
3. **异常处理**：完善的异常处理机制，避免泄露敏感信息
4. **HTTPS**：加解密不能替代 HTTPS，仍需使用 HTTPS 保护传输层
5. **算法选择**：根据安全需求选择合适的加密算法（AES、RSA、SM4 等）
6. **数据格式**：统一前后端的加密数据格式和编码方式

你的项目是什么加密场景？我可以提供更具体的实现方案。# SpringBoot 项目实现入参解密和返回结果加密

我来为你介绍几种常用的实现方案：

## 方案一：使用请求响应体增强器（推荐）

这种方式通过 `RequestBodyAdvice` 和 `ResponseBodyAdvice` 来实现全局的加解密处理。

### 1. 创建自定义注解

```java
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Encrypt {
}

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Decrypt {
}
```

### 2. 实现请求体解密

```java
@ControllerAdvice
public class DecryptRequestBodyAdvice extends RequestBodyAdviceAdapter {

    @Autowired
    private CryptoService cryptoService;

    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType,
                          Class<? extends HttpMessageConverter<?>> converterType) {
        return methodParameter.hasMethodAnnotation(Decrypt.class) 
            || methodParameter.getDeclaringClass().isAnnotationPresent(Decrypt.class);
    }

    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage inputMessage, 
                                          MethodParameter parameter, 
                                          Type targetType,
                                          Class<? extends HttpMessageConverter<?>> converterType) 
                                          throws IOException {
        return new DecryptHttpInputMessage(inputMessage, cryptoService);
    }
}

class DecryptHttpInputMessage implements HttpInputMessage {
    private HttpHeaders headers;
    private InputStream body;

    public DecryptHttpInputMessage(HttpInputMessage inputMessage, CryptoService cryptoService) 
            throws IOException {
        this.headers = inputMessage.getHeaders();
        String encryptedData = IOUtils.toString(inputMessage.getBody(), StandardCharsets.UTF_8);
        String decryptedData = cryptoService.decrypt(encryptedData);
        this.body = new ByteArrayInputStream(decryptedData.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public InputStream getBody() {
        return body;
    }

    @Override
    public HttpHeaders getHeaders() {
        return headers;
    }
}
```

### 3. 实现响应体加密

```java
@ControllerAdvice
public class EncryptResponseBodyAdvice implements ResponseBodyAdvice<Object> {

    @Autowired
    private CryptoService cryptoService;

    @Override
    public boolean supports(MethodParameter returnType, 
                          Class<? extends HttpMessageConverter<?>> converterType) {
        return returnType.hasMethodAnnotation(Encrypt.class)
            || returnType.getDeclaringClass().isAnnotationPresent(Encrypt.class);
    }

    @Override
    public Object beforeBodyWrite(Object body, 
                                 MethodParameter returnType,
                                 MediaType selectedContentType,
                                 Class<? extends HttpMessageConverter<?>> selectedConverterType,
                                 ServerHttpRequest request,
                                 ServerHttpResponse response) {
        if (body == null) {
            return null;
        }
        
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            String jsonData = objectMapper.writeValueAsString(body);
            String encryptedData = cryptoService.encrypt(jsonData);
            
            // 返回加密后的数据结构
            Map<String, String> result = new HashMap<>();
            result.put("data", encryptedData);
            return result;
        } catch (Exception e) {
            throw new RuntimeException("加密失败", e);
        }
    }
}
```

### 4. 加密服务实现（AES示例）

```java
@Service
public class CryptoService {

    private static final String ALGORITHM = "AES";
    private static final String TRANSFORMATION = "AES/CBC/PKCS5Padding";
    
    @Value("${crypto.secret-key}")
    private String secretKey;
    
    @Value("${crypto.iv}")
    private String iv;

    public String encrypt(String data) {
        try {
            SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), ALGORITHM);
            IvParameterSpec ivSpec = new IvParameterSpec(iv.getBytes());
            
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivSpec);
            
            byte[] encrypted = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(encrypted);
        } catch (Exception e) {
            throw new RuntimeException("加密失败", e);
        }
    }

    public String decrypt(String encryptedData) {
        try {
            SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), ALGORITHM);
            IvParameterSpec ivSpec = new IvParameterSpec(iv.getBytes());
            
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
            
            byte[] decrypted = cipher.doFinal(Base64.getDecoder().decode(encryptedData));
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new RuntimeException("解密失败", e);
        }
    }
}
```

### 5. 在 Controller 中使用

```java
@RestController
@RequestMapping("/api")
public class UserController {

    @PostMapping("/user")
    @Decrypt  // 请求参数自动解密
    @Encrypt  // 响应结果自动加密
    public ResponseEntity<User> createUser(@RequestBody User user) {
        // 这里的 user 已经是解密后的对象
        // 业务逻辑处理
        return ResponseEntity.ok(user);
    }
}
```

### 6. 配置文件

```yaml
crypto:
  secret-key: 1234567890123456  # 16字节密钥
  iv: 1234567890123456          # 16字节IV
```

## 方案二：使用拦截器

如果需要更细粒度的控制，可以使用拦截器配合自定义注解实现。

## 方案三：使用过滤器

对于需要在 Spring MVC 之前处理的场景，可以使用 Filter 实现。

## 注意事项

1. **密钥管理**：不要将密钥硬编码，使用配置中心或密钥管理服务
2. **性能考虑**：加解密会影响性能，考虑使用缓存或异步处理
3. **异常处理**：完善的异常处理机制，避免泄露敏感信息
4. **HTTPS**：加解密不能替代 HTTPS，仍需使用 HTTPS 保护传输层
5. **算法选择**：根据安全需求选择合适的加密算法（AES、RSA、SM4 等）
6. **数据格式**：统一前后端的加密数据格式和编码方式

你的项目是什么加密场景？我可以提供更具体的实现方案。