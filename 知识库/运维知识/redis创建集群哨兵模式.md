好的，这是一份非常详细的 Redis 哨兵（Sentinel）模式配置指南，从基本概念、架构到具体配置步骤、启动和测试，以及客户端如何连接，都做了全面的说明。

---

### 1. 什么是 Redis 哨兵模式？

Redis 哨兵是 Redis 官方推荐的高可用性（High Availability）解决方案。它由一个或多个哨兵（Sentinel）实例组成，用于监控任意多个 Redis 主从集群。

**哨兵模式的核心功能：**

*   **监控（Monitoring）：** 哨兵会持续地检查你的主服务器（Master）和从服务器（Replica/Slave）是否运作正常。
*   **通知（Notification）：** 当被监控的某个 Redis 实例出现问题时，哨兵可以通过 API 向管理员或者其他应用程序发送通知。
*   **自动故障转移（Automatic Failover）：** 当主服务器挂掉时，哨兵会启动自动故障转移过程。它会在从服务器中选举出一个新的主服务器，并让其他从服务器指向新的主服务器。同时，它会通知客户端新的主服务器地址。
*   **配置提供者（Configuration Provider）：** 客户端在初始化时，可以连接到哨兵并获取当前 Redis 主服务器的地址，从而实现无缝切换。

### 2. 架构说明

一个典型的哨兵模式架构如下：

*   **1个 Master 节点：** 负责处理读写请求。
*   **N个 Replica 节点：** 负责从 Master 同步数据，可以分担读请求。
*   **M个 Sentinel 节点：** 监控整个主从集群。**官方建议至少部署3个哨兵节点**，以避免脑裂（Split-brain）问题，并且这些哨兵节点应该部署在不同的物理机或虚拟机上。

**架构图示意：**

```
                  +-----------------+
                  |     Client      |
                  +-----------------+
                         ^   |
                         |   | 1. 查询Master地址
                         |   v
+------------------------+------------------------+------------------------+
|       Sentinel 1       |       Sentinel 2       |       Sentinel 3       |
+------------------------+------------------------+------------------------+
          ^   |                    ^   |                    ^   |
          |   | 监控与通信         |   | 监控与通信         |   | 监控与通信
          |   v                    |   v                    |   v
+------------------------+<-------+------------------------+------->+------------------------+
|      Redis Master      |         |     Redis Replica 1    |        |     Redis Replica 2    |
|       (Port 6379)      |-------->|       (Port 6380)      |        |       (Port 6381)      |
+------------------------+         +------------------------+        +------------------------+
         (数据同步)                 (数据同步)
```

### 3. 配置步骤

假设我们在一台机器上模拟这个环境，使用不同端口。在生产环境中，请将它们部署在不同的服务器上。

*   **Redis Master:** 127.0.0.1:6379
*   **Redis Replica 1:** 127.0.0.1:6380
*   **Redis Replica 2:** 127.0.0.1:6381
*   **Sentinel 1:** 127.0.0.1:26379
*   **Sentinel 2:** 127.0.0.1:26380
*   **Sentinel 3:** 127.0.0.1:26381

#### **步骤一：配置 Redis 主从复制**

首先，我们需要一个正常工作的主从复制集群。

**1. 配置 Master (redis-6379.conf)**

```conf
port 6379
daemonize yes
logfile "6379.log"
pidfile "/var/run/redis_6379.pid"
dbfilename "dump-6379.rdb"
# 如果需要密码，请设置
# requirepass your_password
```

**2. 配置 Replica 1 (redis-6380.conf)**

```conf
port 6380
daemonize yes
logfile "6380.log"
pidfile "/var/run/redis_6380.pid"
dbfilename "dump-6380.rdb"

# 声明这是 127.0.0.1:6379 的从节点
# Redis 5.0 之后推荐使用 replicaof
replicaof 127.0.0.1 6379

# 如果 Master 有密码，需要配置
# masterauth your_password
```

**3. 配置 Replica 2 (redis-6381.conf)**

与 Replica 1 类似，只是端口和文件名不同。

```conf
port 6381
daemonize yes
logfile "6381.log"
pidfile "/var/run/redis_6381.pid"
dbfilename "dump-6381.rdb"

replicaof 127.0.0.1 6379
# masterauth your_password
```

#### **步骤二：配置 Sentinel 哨兵**

为每个哨兵实例创建一个配置文件。哨兵的配置非常简洁。

**1. 配置 Sentinel 1 (sentinel-26379.conf)**

```conf
port 26379
daemonize yes
logfile "26379.log"
pidfile "/var/run/redis_sentinel_26379.pid"

# 核心配置：sentinel monitor <master-name> <ip> <port> <quorum>
# <master-name>: 主节点的别名，自定义，如 "mymaster"。
# <ip> <port>: 主节点的实际 IP 和端口。
# <quorum>: 选举主节点所需的最低哨兵同意票数。
#           例如，设置为 2 表示至少需要 2 个哨兵认为主节点已下线，才会发起故障转移。
#           这个数字最好是 (哨兵总数 / 2) + 1。
sentinel monitor mymaster 127.0.0.1 6379 2

# 主观下线时间（SDOWN）：哨兵在多少毫秒内收不到主节点的 PONG 回复，就认为它主观下线。
sentinel down-after-milliseconds mymaster 30000

# 故障转移超时时间：在故障转移开始后，若超过此时间（毫秒）仍未完成，则视为失败。
sentinel failover-timeout mymaster 180000

# 并行同步数：在故障转移后，允许多少个从节点同时与新主节点进行同步。
# 值为 1 表示一次只同步一个。
sentinel parallel-syncs mymaster 1

# 如果你的 Redis 主从节点设置了密码，哨兵也需要密码才能连接。
# sentinel auth-pass <master-name> <password>
# sentinel auth-pass mymaster your_password
```

**2. 配置 Sentinel 2 (sentinel-26380.conf) 和 Sentinel 3 (sentinel-26381.conf)**

这两个配置文件内容和 Sentinel 1 基本一样，**只需要修改 `port`、`logfile` 和 `pidfile`** 即可。`sentinel monitor` 这一行保持不变。

*   **sentinel-26380.conf:**
    ```conf
    port 26380
    daemonize yes
    logfile "26380.log"
    pidfile "/var/run/redis_sentinel_26380.pid"
    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 30000
    sentinel failover-timeout mymaster 180000
    sentinel parallel-syncs mymaster 1
    # sentinel auth-pass mymaster your_password
    ```

*   **sentinel-26381.conf:**
    ```conf
    port 26381
    daemonize yes
    logfile "26381.log"
    pidfile "/var/run/redis_sentinel_26381.pid"
    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 30000
    sentinel failover-timeout mymaster 180000
    sentinel parallel-syncs mymaster 1
    # sentinel auth-pass mymaster your_password
    ```

> **重要提示：** 你只需要在一个哨兵配置文件中配置 `sentinel monitor`。当哨兵启动后，它们会通过主节点自动发现其他哨兵和从节点，并同步配置。这也是哨兵的强大之处。

### 4. 启动与验证

**1. 启动顺序：**
先启动 Master，再启动 Replicas，最后启动 Sentinels。

```bash
# 启动 Redis 实例
redis-server /path/to/redis-6379.conf
redis-server /path/to/redis-6380.conf
redis-server /path/to/redis-6381.conf

# 启动 Sentinel 实例
# 方法一：使用 redis-sentinel
redis-sentinel /path/to/sentinel-26379.conf
redis-sentinel /path/to/sentinel-26380.conf
redis-sentinel /path/to/sentinel-26381.conf

# 方法二：使用 redis-server --sentinel
# redis-server /path/to/sentinel-26379.conf --sentinel
# redis-server /path/to/sentinel-26380.conf --sentinel
# redis-server /path/to/sentinel-26381.conf --sentinel
```

**2. 验证状态：**
连接到任意一个哨兵，查看集群信息。

```bash
# 连接到哨兵
redis-cli -p 26379

# 查看 'mymaster' 的状态
127.0.0.1:26379> SENTINEL masters
1)  1) "name"
    2) "mymaster"
    3) "ip"
    4) "127.0.0.1"
    5) "port"
    6) "6379"
    ...
   15) "num-slaves"
   16) "2"
   17) "num-other-sentinels"
   18) "2"
   ...

# 查看 'mymaster' 的从节点信息
127.0.0.1:26379> SENTINEL replicas mymaster
1)  1) "name"
    2) "127.0.0.1:6380"
    ...
2)  1) "name"
    2) "127.0.0.1:6381"
    ...

# 查看当前 Master 的地址
127.0.0.1:26379> SENTINEL get-master-addr-by-name mymaster
1) "127.0.0.1"
2) "6379"
```
如果你看到 `num-slaves` 为 2，`num-other-sentinels` 为 2，说明哨兵已经成功识别了整个集群。

### 5. 模拟故障与测试

**1. 手动关闭 Master 节点**

```bash
# 找到 6379 端口的 Redis 进程 PID
ps -ef | grep "redis-server.*:6379"

# 杀死主节点进程
kill -9 <pid_of_master>
```

**2. 观察哨兵日志**

现在查看任一哨兵的日志文件（如 `26379.log`），你会看到类似以下的输出：

```log
... +sdown master mymaster 127.0.0.1 6379                      # 某个哨兵主观认为 Master 下线 (S-DOWN)
... +odown master mymaster 127.0.0.1 6379 #quorum 2/2         # 达到法定票数，客观认为 Master 下线 (O-DOWN)
... +try-failover master mymaster 127.0.0.1 6379              # 尝试进行故障转移
... +elect-leader master mymaster 127.0.0.1 6379              # 选举一个从节点作为新的主节点
... +failover-state-select-slave master mymaster 127.0.0.1 6379 # 选定了一个从节点
... +selected-slave slave 127.0.0.1:6380 ...                  # 比如选了 6380
... +failover-state-send-slaveof-noone slave 127.0.0.1:6380 ... # 向 6380 发送 `REPLICAOF NO ONE` 命令，使其成为 Master
... +switch-master mymaster 127.0.0.1 6379 127.0.0.1 6380     # 切换 Master！旧的是 6379，新的是 6380
... +slave-reconf-sent slave 127.0.0.1:6381 ...               # 通知其他从节点(6381)去复制新的 Master(6380)
```

**3. 再次验证**

再次连接到哨兵，获取新的 Master 地址。

```bash
redis-cli -p 26379
127.0.0.1:26379> SENTINEL get-master-addr-by-name mymaster
1) "127.0.0.1"
2) "6380"  # <-- 地址已经变为 6380
```

至此，故障转移已成功完成。

### 6. 客户端如何连接哨兵模式

**关键点：** 应用程序不应该直接连接到 Redis Master 的固定 IP 地址，而应该连接到哨兵集群。

主流的 Redis 客户端库（如 Java 的 Jedis/Lettuce，Python 的 redis-py）都支持哨兵模式。

**配置示例（伪代码）：**

*   **哨兵地址列表：** `["127.0.0.1:26379", "127.0.0.1:26380", "127.0.0.1:26381"]`
*   **Master 名称：** `"mymaster"`
*   **密码（如果需要）：** `"your_password"`

客户端库会自动执行以下操作：
1.  连接到一个哨兵。
2.  询问该哨兵 `"mymaster"` 的当前主节点地址。
3.  连接到获取到的主节点地址进行读写操作。
4.  如果连接失败，它会自动尝试连接下一个哨兵，获取新的主节点地址，实现对故障转移的无感知。

**Python (redis-py) 示例：**

```python
from redis.sentinel import Sentinel

# 哨兵列表
sentinel_hosts = [('127.0.0.1', 26379), ('127.0.0.1', 26380), ('127.0.0.1', 26381)]

# 创建 Sentinel 连接对象
sentinel = Sentinel(sentinel_hosts, socket_timeout=0.5, password='your_password') # 如果 Redis 有密码，这里也需要

# 获取 Master 节点的连接
# 'mymaster' 是你在 sentinel.conf 中配置的 master-name
master = sentinel.master_for('mymaster', socket_timeout=0.5)

# 获取 Replica 节点的连接 (用于读)
replica = sentinel.slave_for('mymaster', socket_timeout=0.5)

# 像普通 redis 连接一样使用
master.set('foo', 'bar')
value = master.get('foo')
print(value)
```

---

通过以上步骤，你就可以成功地配置并运行一个高可用的 Redis 哨兵集群了。