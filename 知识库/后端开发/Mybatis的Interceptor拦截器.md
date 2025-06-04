`@Signature` 注解是 MyBatis 拦截器中用来指定拦截方法的注解，它定义了要拦截的类、方法和参数类型。让我详细解释一下：

## @Signature 注解的基本结构

```java
@Signature(
    type = Class<?>,           // 要拦截的接口类型
    method = "methodName",     // 要拦截的方法名
    args = {Class<?>, ...}     // 方法的参数类型数组
)
```

## MyBatis 中可拦截的四个核心接口

### 1. Executor（执行器）

```java
@Intercepts({
    @Signature(
        type = Executor.class,
        method = "update", 
        args = {MappedStatement.class, Object.class}
    ),
    @Signature(
        type = Executor.class,
        method = "query",
        args = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class}
    )
})
public class ExecutorInterceptor implements Interceptor {
    // 拦截 SQL 执行
}
```

**Executor 常用方法：**
- `update(MappedStatement ms, Object parameter)` - 拦截 INSERT/UPDATE/DELETE
- `query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler)` - 拦截 SELECT

### 2. StatementHandler（语句处理器）

```java
@Intercepts({
    @Signature(
        type = StatementHandler.class,
        method = "prepare",
        args = {Connection.class, Integer.class}
    ),
    @Signature(
        type = StatementHandler.class,
        method = "parameterize",
        args = {Statement.class}
    )
})
public class StatementInterceptor implements Interceptor {
    // 拦截 SQL 语句准备和参数设置
}
```

**StatementHandler 常用方法：**
- `prepare(Connection connection, Integer transactionTimeout)` - SQL 预编译
- `parameterize(Statement statement)` - 参数设置
- `query(Statement statement, ResultHandler resultHandler)` - 查询执行

### 3. ParameterHandler（参数处理器）

```java
@Intercepts({
    @Signature(
        type = ParameterHandler.class,
        method = "setParameters",
        args = {PreparedStatement.class}
    )
})
public class ParameterInterceptor implements Interceptor {
    // 拦截参数设置
}
```

### 4. ResultSetHandler（结果集处理器）

```java
@Intercepts({
    @Signature(
        type = ResultSetHandler.class,
        method = "handleResultSets",
        args = {Statement.class}
    )
})
public class ResultSetInterceptor implements Interceptor {
    // 拦截结果集处理
}
```

## 完整的拦截器示例

### 1. SQL 执行时间监控拦截器

```java
@Intercepts({
    @Signature(
        type = Executor.class,
        method = "update",
        args = {MappedStatement.class, Object.class}
    ),
    @Signature(
        type = Executor.class,
        method = "query",
        args = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class}
    ),
    @Signature(
        type = Executor.class,
        method = "query",
        args = {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class, CacheKey.class, BoundSql.class}
    )
})
@Component
public class SqlExecutionTimeInterceptor implements Interceptor {

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        long startTime = System.currentTimeMillis();
        
        try {
            // 执行原方法
            Object result = invocation.proceed();
            return result;
        } finally {
            long endTime = System.currentTimeMillis();
            long executionTime = endTime - startTime;
            
            // 获取执行的 SQL 信息
            MappedStatement mappedStatement = (MappedStatement) invocation.getArgs()[0];
            String sqlId = mappedStatement.getId();
            
            System.out.println("SQL执行时间: " + executionTime + "ms, SqlId: " + sqlId);
        }
    }

    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }

    @Override
    public void setProperties(Properties properties) {
        // 可以设置配置属性
    }
}
```

### 2. 分页拦截器

```java
@Intercepts({
    @Signature(
        type = StatementHandler.class,
        method = "prepare",
        args = {Connection.class, Integer.class}
    )
})
@Component
public class PageInterceptor implements Interceptor {

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        StatementHandler statementHandler = (StatementHandler) invocation.getTarget();
        
        // 通过反射获取到当前StatementHandler的 boundSql
        BoundSql boundSql = statementHandler.getBoundSql();
        String sql = boundSql.getSql();
        
        // 检查是否需要分页
        Object parameterObject = boundSql.getParameterObject();
        if (parameterObject instanceof PageParam) {
            PageParam pageParam = (PageParam) parameterObject;
            
            // 修改 SQL 添加 LIMIT
            String pageSql = sql + " LIMIT " + pageParam.getOffset() + ", " + pageParam.getSize();
            
            // 通过反射修改 SQL
            Field sqlField = BoundSql.class.getDeclaredField("sql");
            sqlField.setAccessible(true);
            sqlField.set(boundSql, pageSql);
        }
        
        return invocation.proceed();
    }

    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }

    @Override
    public void setProperties(Properties properties) {
        // 配置属性
    }
}
```

### 3. 敏感信息脱敏拦截器

```java
@Intercepts({
    @Signature(
        type = ResultSetHandler.class,
        method = "handleResultSets",
        args = {Statement.class}
    )
})
@Component
public class DataMaskingInterceptor implements Interceptor {

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        // 执行原方法，获取结果
        Object result = invocation.proceed();
        
        // 对结果进行脱敏处理
        return maskSensitiveData(result);
    }
    
    private Object maskSensitiveData(Object result) {
        if (result instanceof List) {
            List<?> list = (List<?>) result;
            for (Object item : list) {
                maskObject(item);
            }
        } else {
            maskObject(result);
        }
        return result;
    }
    
    private void maskObject(Object obj) {
        if (obj == null) return;
        
        Field[] fields = obj.getClass().getDeclaredFields();
        for (Field field : fields) {
            if (field.isAnnotationPresent(SensitiveData.class)) {
                field.setAccessible(true);
                try {
                    Object value = field.get(obj);
                    if (value instanceof String) {
                        String maskedValue = maskString((String) value);
                        field.set(obj, maskedValue);
                    }
                } catch (IllegalAccessException e) {
                    // 处理异常
                }
            }
        }
    }
    
    private String maskString(String str) {
        if (str == null || str.length() <= 2) return str;
        return str.substring(0, 1) + "***" + str.substring(str.length() - 1);
    }

    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }

    @Override
    public void setProperties(Properties properties) {
        // 配置属性
    }
}
```

## 参数类型对照表

### Executor 方法签名

```java
// 查询方法
int update(MappedStatement ms, Object parameter);

List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler);

List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, CacheKey cacheKey, BoundSql boundSql);
```

### StatementHandler 方法签名

```java
Statement prepare(Connection connection, Integer transactionTimeout);
void parameterize(Statement statement);
<E> List<E> query(Statement statement, ResultHandler resultHandler);
<E> Cursor<E> queryCursor(Statement statement);
int update(Statement statement);
```

### ParameterHandler 方法签名

```java
Object getParameterObject();
void setParameters(PreparedStatement ps);
```

### ResultSetHandler 方法签名

```java
<E> List<E> handleResultSets(Statement stmt);
<E> Cursor<E> handleCursorResultSets(Statement stmt);
void handleOutputParameters(CallableStatement cs);
```

## 配置和注册

### 1. 通过配置文件注册

```yaml
mybatis:
  configuration:
    interceptors:
      - com.example.interceptor.SqlExecutionTimeInterceptor
      - com.example.interceptor.PageInterceptor
```

### 2. 通过 @Component 自动注册

```java
@Configuration
public class MyBatisConfig {
    
    @Bean
    public SqlExecutionTimeInterceptor sqlExecutionTimeInterceptor() {
        return new SqlExecutionTimeInterceptor();
    }
}
```

## 注意事项

1. **参数类型必须完全匹配**：`args` 中的类型必须与实际方法参数类型完全一致
2. **方法重载**：如果方法有重载，需要通过 `args` 区分具体要拦截哪个方法
3. **执行顺序**：多个拦截器按注册顺序执行
4. **性能影响**：拦截器会影响性能，需要谨慎使用
5. **异常处理**：拦截器中的异常会影响正常的 SQL 执行

通过 `@Signature` 注解，你可以精确控制要拦截的方法，实现各种自定义功能，如 SQL 监控、权限控制、数据脱敏、分页等。