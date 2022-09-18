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
./bin/kafka-topics.sh --bootstrap-server hadoop102:9092
# 5.2 创建topic
./bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --create --topic first --partitions 4 --replication-factor 2
# 5.3 查看topic 为 first的 详细信息
./bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --describe --topic first
# 5.4 往topic 为 first 的内部生产消息
./bin/kafka-console-producer.sh --broker-list hadoop102:9092 --topic first
#从topic 为first的内部消费消息
./bin/kafka-console-consumer.sh --bootstrap-server hadoop102:9092 --topic first