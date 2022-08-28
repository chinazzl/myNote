# Nacos

> Nacos是阿里的一个开源产品，它是针对微服务架构中的服务发现、配置管理、服务治理的综合型解决方案 

### Nacos特性

1. **服务发现与健康检查**
   
   Nacos使服务更容易注册，并通过DNS或HTTP接口发现其他服务，Nacos还提供服务的实时健康检查，以防止向不健康的主机或服务实例发送请求

2. **动态配置管理**
   
   动态配置服务允许您在所有的环境中以集中和动态的方式管理所有服务配置，Nacos消除了在更新配置时重新部署应用程序，这使配置的更改更加高效和灵活。

3. **动态DNS服务**
   
   Nacos提供基于DNS协议的服务发现能力，在支持异构语言的服务发现，支持将注册在Nacos上的服务以域名的方式暴露端点，让三方应用方便的查阅以及发现。

4. **服务和元数据管理  **
   
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
