## kafka开发常用参数

**「broker 端配置」**

- broker.id

每个 kafka broker 都有一个唯一的标识来表示，这个唯一的标识符即是 `broker.id`，它的默认值是 0。

这个值在 kafka 集群中必须是唯一的，这个值可以任意设定，

- port

如果使用配置样本来启动 kafka，它会监听 9092 端口，修改 port 配置参数可以把它设置成任意的端口。

要注意，如果使用 1024 以下的端口，需要使用 root 权限启动 kakfa。

- zookeeper.connect

用于保存 broker 元数据的 Zookeeper 地址是通过 `zookeeper.connect` 来指定的。

比如可以这么指定 `localhost:2181` 表示这个 Zookeeper 是运行在本地 2181 端口上的。

我们也可以通过 比如我们可以通过 `zk1:2181,zk2:2181,zk3:2181` 来指定 `zookeeper.connect` 的多个参数值。

该配置参数是用冒号分割的一组 `hostname:port/path` 列表，其含义如下

- hostname 是 Zookeeper 服务器的机器名或者 ip 地址。
- port 是 Zookeeper 客户端的端口号
- /path 是可选择的 Zookeeper 路径，Kafka 路径是使用了 `chroot` 环境，如果不指定默认使用跟路径。

❝

如果你有两套 Kafka 集群，假设分别叫它们 kafka1 和 kafka2，那么两套集群的`zookeeper.connect`参数可以这样指定：`zk1:2181,zk2:2181,zk3:2181/kafka1`和`zk1:2181,zk2:2181,zk3:2181/kafka2`

❞

- log.dirs

Kafka 把所有的消息都保存到磁盘上，存放这些日志片段的目录是通过 `log.dirs` 来制定的，它是用一组逗号来分割的本地系统路径，`log.dirs` 是没有默认值的，**「你必须手动指定他的默认值」**。

其实还有一个参数是 `log.dir`，这个配置是没有 `s` 的，默认情况下只用配置 `log.dirs` 就好了，比如你可以通过 `/home/kafka1,/home/kafka2,/home/kafka3` 这样来配置这个参数的值。

- auto.create.topics.enable

默认情况下，kafka 会自动创建主题

`auto.create.topics.enable`参数建议最好设置成 false，即不允许自动创建 Topic。

**「主题相关配置」**

- num.partitions

num.partitions 参数指定了新创建的主题需要包含多少个分区，该参数的默认值是 1。

- default.replication.factor

这个参数比较简单，它表示 kafka 保存消息的副本数。

- log.retention.ms

Kafka 通常根据时间来决定数据可以保留多久。

默认使用`log.retention.hours`参数来配置时间，默认是 168 个小时，也就是一周。

除此之外，还有两个参数`log.retention.minutes` 和`log.retentiion.ms` 。

这三个参数作用是一样的，都是决定消息多久以后被删除，推荐使用`log.retention.ms`。

- message.max.bytes

broker 通过设置 `message.max.bytes` 参数来限制单个消息的大小，默认是 1000 000， 也就是 1MB，如果生产者尝试发送的消息超过这个大小，不仅消息不会被接收，还会收到 broker 返回的错误消息。

- retention.ms

规定了该主题消息被保存的时常，默认是 7 天，即该主题只能保存 7 天的消息，一旦设置了这个值，它会覆盖掉 Broker 端的全局参数值。