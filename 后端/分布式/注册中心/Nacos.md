# Nacos

> Nacos是阿里的一个开源产品，它是针对微服务架构中的服务发现、配置管理、服务治理的综合型解决方案 

### Nacos特性

1. **服务发现与健康检查**
   
   Nacos使服务更容易注册，并通过DNS或HTTP接口发现其他服务，Nacos还提供服务的实时健康检查，以防止向不健康的主机或服务实例发送请求

2. **动态配置管理**
   
   动态配置服务允许您在所有的环境中以集中和动态的方式管理所有服务配置，Nacos消除了在更新配置时重新部署应用程序，这使配置的更改更加高效和灵活。

3. **动态DNS服务**
   
   Nacos提供基于DNS协议的服务发现能力，在支持异构语言的服务发现，支持将注册在Nacos上的服务以域名的方式暴露端点，让三方应用方便的查阅以及发现。

4. **服务和元数据管理**
   
   Nacos能让您从微服务平台建设的视角管理数据中心的所有服务以及元数据，包括管理服务的描述、生命周期、服务的静态依赖分析、服务的健康状态、服务的流量管理、路由及安全策略

### OpenAPI

1. 发布配置

```url
curl -X POST "http://49.4.114.32:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=HelloWorld"
```

2. 获取配置

```url
curl -X GET "http://49.4.114.32:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test
```

### 服务发现与动态u管理配置文件

1. 读取配置文件的优先级：
   如下图：
   a: alicloud-web.yml
   b: web-ext-config-0.yml web-ext-config-0.yml
   c: shared-config.yml
   优先级低 -> 高 a < b < c， 公共配置文件的优先级高于扩展配置优先级，扩展配置优先级高于自定义优先级。
2. 让本地配置覆盖nacos配置文件，如下面配置文件，需要在alicloud-web.yml中增加
   ```yaml
   spring：
     cloud:
     # nacos不覆盖本地文件
       override-none: true
       # 允许覆盖nacos配置文件
       allow-override: true
       # 允许覆盖系统配置文件
       override-system-properties: false
   ```

Nacos配置文件示例：
```yaml
# bootstrap.yml
spring:
  application:
    name: alicloud-web
  cloud:
    nacos:
      server-addr: localhost:8848
      discovery:
        namespace: 5bf3d99b-35dc-4eea-917d-10ee3fa4e030
      #        username: nacos
      #        password: nacos
      config:
        namespace: 5bf3d99b-35dc-4eea-917d-10ee3fa4e030
        group: ZZL_GROUP
        file-extension: yml
        extension-configs:
          extension-config[0]: web-ext-config-0.yml
          extension-config[1]:
            dataId: web-ext-config-1.yml
            group: ZZL_GROUP
         share_config: shared-config.yml
    sentinel:
      web-context-unify: true
      transport:
        dashboard: localhost:8858

```
