# 1. 先启动zookeeper
./zookeeper-server-start.sh /config/zookeeper.properties

# 2. 启动kafka
./kafka-server-start.sh /config/server.properties

# 3. 创建kafka主题
# --zookeeper zookeeper 地址；--replication-factor 副本数量；--partitions 分区数量；--topic 创建主题
./kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic topic-first