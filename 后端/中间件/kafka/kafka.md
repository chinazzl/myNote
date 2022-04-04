## Kafka
> Kafka 是一种分布式的，基于发布 / 订阅的消息系统

**「主题」**

发布订阅的对象是主题（`Topic`），可以为每 个业务、每个应用甚至是每类数据都创建专属的主题

**「生产者和消费者」**

向主题发布消息的客户端应用程序称为生产者，生产者程序通常持续不断地 向一个或多个主题发送消息

订阅这些主题消息的客户端应用程序就被称为消费者，消费者也能够同时订阅多个主题的消息

**「Broker」**

集群由多个 Broker 组成，`Broker` 负责接收和处理客户端发送过来的请求，以及对消息进行持久化

虽然多个 Broker 进程能够运行在同一台机器上，但更常见的做法是将 不同的 `Broker` 分散运行在不同的机器上，这样如果集群中某一台机器宕机，即使在它上面 运行的所有 Broker 进程都挂掉了，其他机器上的 `Broker` 也依然能够对外提供服务

**「备份机制」**

备份的思想很简单，就是把相同的数据拷贝到多台机器上，而这些相同的数据拷贝被称为副本

定义了两类副本：领导者副本和追随者副本

前者对外提供服务，这里的对外指的是与 客户端程序进行交互；而后者只是被动地追随领导者副本而已，不能与外界进行交互

**「分区」**

分区机制指的是将每个主题划分成多个分区，每个分区是一组有序的消息日志

生产者生产的每条消息只会被发送到一个分区中，也就是说如果向一个双分区的主题发送一条消息，这条消息要么在分区 0 中，要么在分区 1 中

每个分区下可以配置若干个副本，其中只能有 1 个领 导者副本和 N-1 个追随者副本

生产者向分区写入消息，每条消息在分区中的位置信息叫位移

**「消费者组」**

多个消费者实例共同组成一个组来 消费一组主题

这组主题中的每个分区都只会被组内的一个消费者实例消费，其他消费者实例不能消费它

❝

**同时实现了传统消息引擎系统的两大模型：**

❞

如果所有实例都属于同一个 `Group`， 那么它实现的就是消息队列模型；

如果所有实例分别属于不 同的 `Group`，那么它实现的就是发布 / 订阅模型

**「Coordinator：协调者」**

所谓协调者，它专门为 Consumer Group 服务，负责为 Group 执行 Rebalance 以及提供位移管理和组成员管理等。

具体来讲，Consumer 端应用程序在提交位移时，其实是向 Coordinator 所在的 Broker 提交位移，同样地，当 Consumer 应用启动时，也是向 Coordinator 所在的 Broker 发送各种请求，然后由 Coordinator 负责执行消费者组的注册、成员管理记录等元数据管理操作。

所有 Broker 在启动时，都会创建和开启相应的 Coordinator 组件。

也就是说，**「所有 Broker 都有各自的 Coordinator 组件」**。

那么，Consumer Group 如何确定为它服务的 Coordinator 在哪台 Broker 上呢？

通过 Kafka 内部主题`__consumer_offsets`。

目前，Kafka 为某个 Consumer Group 确定 Coordinator 所在的 Broker 的算法有 2 个步骤。

- 第 1 步：确定由`__consumer_offsets`主题的哪个分区来保存该 Group 数据：`partitionId=Math.abs(groupId.hashCode() % offsetsTopicPartitionCount)`。
- 第 2 步：找出该分区 Leader 副本所在的 Broker，该 Broker 即为对应的 Coordinator。

首先，Kafka 会计算该 Group 的`group.id`参数的哈希值。

比如你有个 Group 的`group.id`设置成了`test-group`，那么它的 hashCode 值就应该是 627841412。

其次，Kafka 会计算`__consumer_offsets`的分区数，通常是 50 个分区，之后将刚才那个哈希值对分区数进行取模加求绝对值计算，即`abs(627841412 % 50) = 12`。

此时，我们就知道了`__consumer_offsets`主题的分区 12 负责保存这个 Group 的数据。

有了分区号，我们只需要找出`__consumer_offsets`主题分区 12 的 Leader 副本在哪个 Broker 上就可以了，这个 Broker，就是我们要找的 Coordinator。

**「消费者位移：Consumer Offset」**

消费者消费进度，每个消费者都有自己的消费者位移。

**「重平衡：Rebalance」**

消费者组内某个消费者实例挂掉后，其他消费者实例自动重新分配订阅主题分区的过程。

Rebalance 是 Kafka 消费者端实现高可用的重要手段。

**「AR（Assigned Replicas）」**：分区中的所有副本统称为 AR。

所有消息会先发送到 leader 副本，然后 follower 副本才能从 leader 中拉取消息进行同步。

但是在同步期间，follower 对于 leader 而言会有一定程度的滞后，这个时候 follower 和 leader 并非完全同步状态

**「OSR（Out Sync Replicas）」**：follower 副本与 leader 副本没有完全同步或滞后的副本集合

**「ISR（In Sync Replicas）：\**「AR 中的一个子集，ISR 中的副本都」\**是与 leader 保持完全同步的副本」**，如果某个在 ISR 中的 follower 副本落后于 leader 副本太多，则会被从 ISR 中移除，否则如果完全同步，会从 OSR 中移至 ISR 集合。

在默认情况下，当 leader 副本发生故障时，只有在 ISR 集合中的 follower 副本才有资格被选举为新 leader，而 OSR 中的副本没有机会（可以通过`unclean.leader.election.enable`进行配置）

**「HW（High Watermark）」**：高水位，它标识了一个特定的消息偏移量（offset），消费者只能拉取到这个水位 offset 之前的消息

下图表示一个日志文件，这个日志文件中只有 9 条消息，第一条消息的 offset（LogStartOffset）为 0，最有一条消息的 offset 为 8，offset 为 9 的消息使用虚线表示的，代表下一条待写入的消息。

日志文件的 HW 为 6，表示消费者只能拉取 offset 在 0 到 5 之间的消息，offset 为 6 的消息对消费者而言是不可见的。

**「LEO（Log End Offset)」**：标识当前日志文件中下一条待写入的消息的 offset

上图中 offset 为 9 的位置即为当前日志文件的 LEO，LEO 的大小相当于当前日志分区中最后一条消息的 offset 值加 1

分区 ISR 集合中的每个副本都会维护自身的 LEO ，而 ISR 集合中最小的 LEO 即为分区的 HW，对消费者而言只能消费 HW 之前的消息。


kafka的选举，如果有三个broker，并且分区为3，kafka会把三个分区均匀的分布在三个broker中，partition_topic_0的AR（所有的副本集合[1,2,0]）,根据优先副本原则会选举broker1为分区partition_topic_0的Leader。每一次在新增Consumer消费者或者恢复的时候都会进行Rebanlance，再次进行选举。

