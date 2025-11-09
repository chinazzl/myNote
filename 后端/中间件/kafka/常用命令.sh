# 1. 先启动zookeeper
./zookeeper-server-start.sh /config/zookeeper.properties

# 2. 启动kafka
./kafka-server-start.sh /config/server.properties

# 3. 创建kafka主题
# --zookeeper zookeeper 地址；--replication-factor 副本数量；--partitions 分区数量；--topic 创建主题
./kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic topic-first

# 4. 查询topic，进入kafka目录：
bin/kafka-topics.sh --list --zookeeper localhost:2181

# 5. 查询topic内容：
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic topicName --from-beginning

# 5.1 查询topic
./bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --describe
# 5.2 创建topic
./bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --create --topic first --partitions 4 --replication-factor 2
# 5.3 查看topic 为 first的 详细信息
./bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --describe --topic first
# 5.4 往topic 为 first 的内部生产消息
./bin/kafka-console-producer.sh --broker-list hadoop102:9092 --topic first
#从topic 为first的内部消费消息
./bin/kafka-console-consumer.sh --bootstrap-server hadoop102:9092 --topic first

# 6. 如果我发送kafka消息的时候主题写错了，我如何通过命令行去消费这条数据?

    # 1. 首先确认错误主题是否存在：
    bin/kafka-topics.sh --bootstrap-server <broker_host:port> --list

# 2. 使用消费者命令行工具从错误主题中消费消息：
bin/kafka-console-consumer.sh --bootstrap-server <broker_host:port> --topic <错误的主题名> --from-beginning


# 如果你需要查看更多消息详情（如消息头、时间戳等）：

bin/kafka-console-consumer.sh --bootstrap-server <broker_host:port> --topic <错误的主题名> --from-beginning --property print.timestamp=true --property print.key=true --property print.headers=true


# 如果你只想消费最新的消息而非从头开始：
bin/kafka-console-consumer.sh --bootstrap-server <broker_host:port> --topic <错误的主题名>


# 如果需要指定消费特定分区的消息：
bin/kafka-console-consumer.sh --bootstrap-server <broker_host:port> --topic <错误的主题名> --partition 0


# 如果你需要消费特定偏移量范围的消息：
bin/kafka-console-consumer.sh --bootstrap-server <broker_host:port> --topic <错误的主题名> --partition 0 --offset <起始偏移量> --max-messages <消息数量>


消费完错误主题中的消息后，你可能需要决定是否保留或删除该主题，这取决于你的具体情况。
