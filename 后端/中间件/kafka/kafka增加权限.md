# Kafka鉴权
Kafka有几种常用的鉴权机制，我来为你详细介绍：

## 1. SASL认证机制

### SASL/PLAIN
最简单的用户名密码认证方式：

**服务端配置 (server.properties):**
```properties
listeners=SASL_PLAINTEXT://localhost:9092
security.inter.broker.protocol=SASL_PLAINTEXT
sasl.mechanism.inter.broker.protocol=PLAIN
sasl.enabled.mechanisms=PLAIN

# JAAS配置文件路径
java.security.auth.login.config=/path/to/kafka_server_jaas.conf
```

**JAAS配置文件 (kafka_server_jaas.conf):**
```
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="admin"
    password="admin123"
    user_admin="admin123"
    user_producer="producer123"
    user_consumer="consumer123";
};
```

### SASL/SCRAM
更安全的密码认证机制：

**创建用户:**
```bash
# 创建SCRAM用户
kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[password=admin123],SCRAM-SHA-512=[password=admin123]' --entity-type users --entity-name admin
```

**服务端配置:**
```properties
listeners=SASL_PLAINTEXT://localhost:9092
security.inter.broker.protocol=SASL_PLAINTEXT
sasl.mechanism.inter.broker.protocol=SCRAM-SHA-256
sasl.enabled.mechanisms=SCRAM-SHA-256
```

## 2. SSL/TLS加密认证

**生成证书:**
```bash
# 生成CA证书
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365

# 生成服务器密钥库
keytool -keystore kafka.server.keystore.jks -alias localhost -validity 365 -genkey -keyalg RSA

# 生成证书签名请求
keytool -keystore kafka.server.keystore.jks -alias localhost -certreq -file cert-file

# CA签名证书
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial

# 导入证书
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert
keytool -keystore kafka.server.keystore.jks -alias localhost -import -file cert-signed
```

**服务端SSL配置:**
```properties
listeners=SSL://localhost:9093
security.inter.broker.protocol=SSL
ssl.keystore.location=/path/to/kafka.server.keystore.jks
ssl.keystore.password=password
ssl.key.password=password
ssl.truststore.location=/path/to/kafka.server.truststore.jks
ssl.truststore.password=password
ssl.client.auth=required
```

## 3. 客户端配置

### Producer配置：
```properties
bootstrap.servers=localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="producer" password="producer123";
```

### Consumer配置：
```properties
bootstrap.servers=localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="consumer" password="consumer123";
group.id=test-group
```

## 4. ACL权限控制

启用ACL授权：
```properties
authorizer.class.name=kafka.security.auth.SimpleAclAuthorizer
super.users=User:admin
```

**设置ACL规则：**
```bash
# 给用户producer授予写topic的权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --add --allow-principal User:producer --operation Write --topic test-topic

# 给用户consumer授予读topic和消费组的权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --add --allow-principal User:consumer --operation Read --topic test-topic
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --add --allow-principal User:consumer --operation Read --group test-group
```

## 5. 组合认证方案

对于生产环境，建议使用SASL + SSL的组合：

```properties
listeners=SASL_SSL://localhost:9094
security.inter.broker.protocol=SASL_SSL
sasl.mechanism.inter.broker.protocol=SCRAM-SHA-256
sasl.enabled.mechanisms=SCRAM-SHA-256
ssl.keystore.location=/path/to/kafka.server.keystore.jks
ssl.keystore.password=password
ssl.key.password=password
ssl.truststore.location=/path/to/kafka.server.truststore.jks
ssl.truststore.password=password
authorizer.class.name=kafka.security.auth.SimpleAclAuthorizer
```

这样可以同时保证传输加密和身份认证的安全性。根据你的具体需求，可以选择合适的认证机制组合。

Kafka的用户权限管理主要通过ACL（Access Control List）来实现，我来详细介绍如何创建用户和分配权限：

## 1. 用户管理

### 创建SCRAM用户（推荐）
```bash
# 创建管理员用户
kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[password=admin123]' --entity-type users --entity-name admin

# 创建生产者用户
kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[password=producer123]' --entity-type users --entity-name producer-user

# 创建消费者用户
kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[password=consumer123]' --entity-type users --entity-name consumer-user

# 创建只读用户
kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[password=readonly123]' --entity-type users --entity-name readonly-user
```

### 查看用户列表
```bash
kafka-configs.sh --zookeeper localhost:2181 --describe --entity-type users
```

### 删除用户
```bash
kafka-configs.sh --zookeeper localhost:2181 --alter --delete-config 'SCRAM-SHA-256' --entity-type users --entity-name username
```

## 2. ACL权限分配

### 基本权限操作类型
- **Read**: 读取数据
- **Write**: 写入数据
- **Create**: 创建topic
- **Delete**: 删除topic
- **Alter**: 修改topic配置
- **Describe**: 查看topic信息
- **ClusterAction**: 集群操作
- **All**: 所有权限

### 资源类型
- **Topic**: 主题
- **Group**: 消费者组
- **Cluster**: 集群
- **TransactionalId**: 事务ID

## 3. 实际权限分配示例

### 管理员权限（所有权限）
```bash
# 给admin用户集群所有权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:admin \
  --operation All --cluster
```

### 生产者权限（只能写入指定topic）
```bash
# 允许写入特定topic
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:producer-user \
  --operation Write --topic order-events

kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:producer-user \
  --operation Write --topic user-events

# 允许查看topic信息（生产者需要）
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:producer-user \
  --operation Describe --topic order-events

# 如果需要创建topic的权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:producer-user \
  --operation Create --topic order-events
```

### 消费者权限（只能读取指定topic和消费组）
```bash
# 允许读取特定topic
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:consumer-user \
  --operation Read --topic order-events

# 允许使用特定消费者组
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:consumer-user \
  --operation Read --group order-processing-group

# 允许查看topic信息
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:consumer-user \
  --operation Describe --topic order-events
```

### 只读用户权限（只能读取，不能提交offset）
```bash
# 只允许读取topic数据
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:readonly-user \
  --operation Read --topic order-events

kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:readonly-user \
  --operation Describe --topic order-events
```

## 4. 使用通配符分配权限

### 给用户分配所有topic的权限
```bash
# 允许读取所有topic
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:consumer-user \
  --operation Read --topic '*'

# 允许写入所有以"app-"开头的topic
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:producer-user \
  --operation Write --topic 'app-*'
```

## 5. 复杂权限场景

### 应用服务权限（读写特定topic）
```bash
# 应用既需要消费也需要生产
APP_USER="app-service"

# 读权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:$APP_USER \
  --operation Read --topic input-topic

kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:$APP_USER \
  --operation Read --group app-service-group

# 写权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:$APP_USER \
  --operation Write --topic output-topic

# 查看权限
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:$APP_USER \
  --operation Describe --topic input-topic

kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:$APP_USER \
  --operation Describe --topic output-topic
```

### 按环境分配权限
```bash
# 开发环境用户
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:dev-user \
  --operation All --topic 'dev-*'

# 测试环境用户
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:test-user \
  --operation All --topic 'test-*'

# 生产环境用户（更严格的权限）
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --add --allow-principal User:prod-user \
  --operation Read --topic 'prod-*'
```

## 6. 权限管理命令

### 查看所有ACL规则
```bash
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 --list
```

### 查看特定用户的权限
```bash
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --list --principal User:producer-user
```

### 查看特定topic的权限
```bash
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --list --topic order-events
```

### 删除ACL规则
```bash
kafka-acls.sh --authorizer-properties zookeeper.connect=localhost:2181 \
  --remove --allow-principal User:producer-user \
  --operation Write --topic order-events
```

## 7. 服务端配置

确保server.properties中启用了ACL：
```properties
# 启用ACL授权
authorizer.class.name=kafka.security.auth.SimpleAclAuthorizer

# 超级用户（拥有所有权限）
super.users=User:admin

# 拒绝未授权访问
allow.everyone.if.no.acl.found=false
```

## 8. 客户端使用示例

### 生产者客户端配置
```properties
bootstrap.servers=localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="producer-user" password="producer123";
```

### 消费者客户端配置
```properties
bootstrap.servers=localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="consumer-user" password="consumer123";
group.id=order-processing-group
```

通过这种方式，你可以实现细粒度的权限控制，确保每个用户只能访问他们需要的资源，提高系统安全性。