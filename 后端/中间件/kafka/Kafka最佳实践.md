## Kafka最佳实践

### 总结 Kafka 无消息丢失的配置：

1. 不要使用`producer.send(msg)`，而要使用`producer.send(msg, callback)`，一定要使用带有回调通知的 send 方法。
2. 设置`acks = all`，acks 是 Producer 的一个参数，代表了你对已提交消息的定义，如果设置成 all，则表明所有副本 Broker 都要接收到消息，该消息才算是已提交。
3. 设置 retries 为一个较大的值。这里的 retries 同样是 Producer 的参数，对应前面提到的 Producer 自动重试，当出现网络的瞬时抖动时，消息发送可能会失败，此时配置了`retries > 0`的 Producer 能够自动重试消息发送，避免消息丢失。
4. 设置`unclean.leader.election.enable = false`，这是 Broker 端的参数，它控制的是哪些 Broker 有资格竞选分区的 Leader，如果一个 Broker 落后原先的 Leader 太多，那么它一旦成为新的 Leader，必然会造成消息的丢失，故一般都要将该参数设置成 false，即不允许这种情况的发生。
5. 设置`replication.factor >= 3`，这也是 Broker 端的参数，将消息多保存几份，目前防止消息丢失的主要机制就是冗余。
6. 设置`min.insync.replicas > 1`，这依然是 Broker 端参数，控制的是消息至少要被写入到多少个副本才算是已提交，设置成大于 1 可以提升消息持久性，在实际环境中千万不要使用默认值 1。
7. 确保`replication.factor > min.insync.replicas`，如果两者相等，那么只要有一个副本挂机，整个分区就无法正常工作了，我们不仅要改善消息的持久性，防止数据丢失，还要在不降低可用性的基础上完成，推荐设置成`replication.factor = min.insync.replicas + 1`。
8. 确保消息消费完成再提交，Consumer 端有个参数`enable.auto.commit`，最好把它设置成 false，并采用手动提交位移的方式。

### 重复消费问题

**「消费重复的场景」**

在`enable.auto.commit` 默认值 true 情况下，出现重复消费的场景有以下几种：

❝

consumer 在消费过程中，应用进程被强制 kill 掉或发生异常退出。

❞

例如在一次 poll 500 条消息后，消费到 200 条时，进程被强制 kill 消费到 offset 未提交，或出现异常退出导致消费到 offset 未提交。

下次重启时，依然会重新拉取 500 消息，造成之前消费到 200 条消息重复消费了两次。

解决方案：在发生异常时正确处理未提交的 offset

**「消费者消费时间过长」**

`max.poll.interval.ms`参数定义了两次 poll 的最大间隔，它的默认值是 5 分钟，表示你的 Consumer 程序如果在 5 分钟之内无法消费完 poll 方法返回的消息，那么 Consumer 会主动发起离开组的请求，Coordinator 也会开启新一轮 Rebalance。

举例：单次拉取 11 条消息，每条消息耗时 30s，11 条消息耗时 5 分钟 30 秒，由于`max.poll.interval.ms` 默认值 5 分钟，所以消费者无法在 5 分钟内消费完，consumer 会离开组，导致 rebalance。

在消费完 11 条消息后，consumer 会重新连接 broker，再次 rebalance，因为上次消费的 offset 未提交，再次拉取的消息是之前消费过的消息，造成重复消费。

**「解决方案：」**

1、提高消费能力，提高单条消息的处理速度；根据实际场景可讲`max.poll.interval.ms`值设置大一点，避免不必要的 rebalance；可适当减小`max.poll.records`的值，默认值是 500，可根据实际消息速率适当调小。

2、生成消息时，可加入唯一标识符如消息 id，在消费端，保存最近的 1000 条消息 id 存入到 redis 或 mysql 中，消费的消息时通过前置去重。

## 消息顺序问题

我们都知道`kafka`的`topic`是无序的，但是一个`topic`包含多个`partition`，每个`partition`内部是有序的

**「乱序场景 1」**

因为一个 topic 可以有多个 partition，kafka 只能保证 partition 内部有序

**「解决方案」**

1、可以设置 topic，有且只有一个 partition

2、根据业务需要，需要顺序的 指定为同一个 partition

3、根据业务需要，比如同一个订单，使用同一个 key，可以保证分配到同一个 partition 上

**「乱序场景 2」**

对于同一业务进入了同一个消费者组之后，用了多线程来处理消息，会导致消息的乱序

**「解决方案」**

消费者内部根据线程数量创建等量的内存队列，对于需要顺序的一系列业务数据，根据 key 或者业务数据，放到同一个内存队列中，然后线程从对应的内存队列中取出并操作

**「通过设置相同 key 来保证消息有序性，会有一点缺陷：」**

例如消息发送设置了重试机制，并且异步发送，消息 A 和 B 设置相同的 key，业务上 A 先发，B 后发，由于网络或者其他原因 A 发送失败，B 发送成功；A 由于发送失败就会重试且重试成功，这时候消息顺序 B 在前 A 在后，与业务发送顺序不一致，如果需要解决这个问题，需要设置参数`max.in.flight.requests.per.connection=1`，其含义是限制客户端在单个连接上能够发送的未响应请求的个数，设置此值是 1 表示 kafka broker 在响应请求之前 client 不能再向同一个 broker 发送请求，这个参数默认值是 5

❝

官方文档说明，这个参数如果大于 1，由于重试消息顺序可能重排

❞



