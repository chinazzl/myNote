    

Kafka最佳实践
=========

发表于 2017-09-21 | 分类于 [Kafka](https://shiyueqi.github.io/categories/Kafka/) | [](https://shiyueqi.github.io/2017/09/21/Kafka%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5/#comments) | 阅读次数

Kafka最佳实践

[](about:blank#broker_u914D_u7F6E "broker配置")broker配置
-----------------------------------------------------

broker配置文件为config/server.properties文件，配置内容主要分为以下几个模块，其他详细配置参见-[Kafka用户手册](https://shiyueqi.github.io/2017/09/21/Kafka%E7%94%A8%E6%88%B7%E6%89%8B%E5%86%8C/ "https://shiyueqi.github.io/2017/09/21/Kafka%E7%94%A8%E6%88%B7%E6%89%8B%E5%86%8C/")：

### [](about:blank#Server_Basics "Server Basics")Server Basics

Kafka server 基本配置

*   broker.id：是kafka集群server的唯一标识。
*   delete.topic.enable：是否开启topic删除功能，可根据具体需求决定。开发测试环境推荐开启，生产环境推荐关闭。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># The id of the broker. This must be set to a unique integer for each broker.</span></span><br><span class="line">broker.id=<span class="number">0</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># Switch to enable topic deletion or not, default value is false</span></span><br><span class="line"><span class="comment">#delete.topic.enable=false</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Socket_Server_Settings "Socket Server Settings")Socket Server Settings

Kafka 网络相关配置

*   listeners：由用户配置协议，ip，port。
*   其他配置项，开发测试环境可使用默认配置；生产环境推荐如下配置。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br><span class="line">6</span><br><span class="line">7</span><br><span class="line">8</span><br><span class="line">9</span><br><span class="line">10</span><br><span class="line">11</span><br><span class="line">12</span><br><span class="line">13</span><br><span class="line">14</span><br><span class="line">15</span><br><span class="line">16</span><br><span class="line">17</span><br><span class="line">18</span><br><span class="line">19</span><br><span class="line">20</span><br><span class="line">21</span><br><span class="line">22</span><br><span class="line">23</span><br><span class="line">24</span><br><span class="line">25</span><br><span class="line">26</span><br><span class="line">27</span><br><span class="line">28</span><br><span class="line">29</span><br><span class="line">30</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># The address the socket server listens on. It will get the value returned from</span></span><br><span class="line"><span class="comment"># java.net.InetAddress.getCanonicalHostName() if not configured.</span></span><br><span class="line"><span class="comment">#   FORMAT:</span></span><br><span class="line"><span class="comment">#     listeners = listener_name://host_name:port</span></span><br><span class="line"><span class="comment">#   EXAMPLE:</span></span><br><span class="line"><span class="comment">#     listeners = PLAINTEXT://your.host.name:9092</span></span><br><span class="line">listeners=PLAINTEXT://<span class="number">172.21</span>.<span class="number">195.89</span>:<span class="number">9092</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># Hostname and port the broker will advertise to producers and consumers. If not set,</span></span><br><span class="line"><span class="comment"># it uses the value for "listeners" if configured.  Otherwise, it will use the value</span></span><br><span class="line"><span class="comment"># returned from java.net.InetAddress.getCanonicalHostName().</span></span><br><span class="line"><span class="comment">#advertised.listeners=PLAINTEXT://your.host.name:9092</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># Maps listener names to security protocols, the default is for them to be the same. See the config documentation for more details</span></span><br><span class="line"><span class="comment">#listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The number of threads that the server uses for receiving requests from the network and sending responses to the network</span></span><br><span class="line">num.network.threads=<span class="number">8</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The number of threads that the server uses for processing requests, which may include disk I/O</span></span><br><span class="line">num.io.threads=<span class="number">8</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The send buffer (SO_SNDBUF) used by the socket server</span></span><br><span class="line">socket.send.buffer.bytes=<span class="number">1048576</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The receive buffer (SO_RCVBUF) used by the socket server</span></span><br><span class="line">socket.receive.buffer.bytes=<span class="number">1048576</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The maximum size of a request that the socket server will accept (protection against OOM)</span></span><br><span class="line">socket.request.max.bytes=<span class="number">104857600</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Log_Basics "Log Basics")Log Basics

Kafka log 基本配置

*   log.dirs：log文件存储路径
*   num.partitions：topic默认的partitions数量。在创建topic时，一般会指定partitions数量，因此该配置项在上述条件下基本无用。为了防止在创建topic时，未指定partitions数量，因此推荐使用配置为3。
*   其他配置推荐使用默认配置

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br><span class="line">6</span><br><span class="line">7</span><br><span class="line">8</span><br><span class="line">9</span><br><span class="line">10</span><br><span class="line">11</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># A comma seperated list of directories under which to store log files</span></span><br><span class="line">log.dirs=/home/ggzjs/kafka-logs</span><br><span class="line"></span><br><span class="line"><span class="comment"># The default number of log partitions per topic. More partitions allow greater</span></span><br><span class="line"><span class="comment"># parallelism for consumption, but this will also result in more files across</span></span><br><span class="line"><span class="comment"># the brokers.</span></span><br><span class="line">num.partitions=<span class="number">3</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.</span></span><br><span class="line"><span class="comment"># This value is recommended to be increased for installations with data dirs located in RAID array.</span></span><br><span class="line">num.recovery.threads.per.data.dir=<span class="number">1</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Internal_Topic_Settings "Internal Topic Settings")Internal Topic Settings

Kafka 内部topic配置

*   开发测试环境推荐使用默认配置，均为1
*   生产环境推荐如下配置，replication数量为3，isr数量为2。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"</span></span><br><span class="line"><span class="comment"># For anything other than development testing, a value greater than 1 is recommended for to ensure availability such as 3.</span></span><br><span class="line">offsets.topic.replication.factor=<span class="number">3</span></span><br><span class="line">transaction.state.log.replication.factor=<span class="number">3</span></span><br><span class="line">transaction.state.log.min.isr=<span class="number">2</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Log_Flush_Policy "Log Flush Policy")Log Flush Policy

Kafka log 刷盘、落盘机制

*   log.flush.interval.messages：日志落盘消息条数间隔，即每接收到一定条数消息，即进行log落盘。
*   log.flush.interval.ms：日志落盘时间间隔，单位ms，即每隔一定时间，即进行log落盘。
*   强烈推荐开发、测试、生产环境均采用默认值，即不配置该配置，交由操作系统自行决定何时落盘，以提升性能。
*   若对消息高可靠性要求较高的应用系统，可针对topic级别的配置，配置该属性。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br><span class="line">6</span><br><span class="line">7</span><br><span class="line">8</span><br><span class="line">9</span><br><span class="line">10</span><br><span class="line">11</span><br><span class="line">12</span><br><span class="line">13</span><br><span class="line">14</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># Messages are immediately written to the filesystem but by default we only fsync() to sync</span></span><br><span class="line"><span class="comment"># the OS cache lazily. The following configurations control the flush of data to disk.</span></span><br><span class="line"><span class="comment"># There are a few important trade-offs here:</span></span><br><span class="line"><span class="comment">#    1. Durability: Unflushed data may be lost if you are not using replication.</span></span><br><span class="line"><span class="comment">#    2. Latency: Very large flush intervals may lead to latency spikes when the flush does occur as there will be a lot of data to flush.</span></span><br><span class="line"><span class="comment">#    3. Throughput: The flush is generally the most expensive operation, and a small flush interval may lead to exceessive seeks.</span></span><br><span class="line"><span class="comment"># The settings below allow one to configure the flush policy to flush data after a period of time or</span></span><br><span class="line"><span class="comment"># every N messages (or both). This can be done globally and overridden on a per-topic basis.</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The number of messages to accept before forcing a flush of data to disk</span></span><br><span class="line"><span class="comment">#log.flush.interval.messages=10000</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The maximum amount of time a message can sit in a log before we force a flush</span></span><br><span class="line"><span class="comment">#log.flush.interval.ms=1000</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Log_Retention_Policy "Log Retention Policy")Log Retention Policy

Kafka log保留策略配置

*   log.retention.hours：日志保留时间，单位小时。和log.retention.minutes两个配置只需配置一项。
*   log.retention.minutes：日志保留时间，单位分钟。和log.retention.hours两个配置只需配置一项。
*   log.retention.bytes：日志保留大小。一topic的一partition下的所有日志大小总和达到该值，即进行日志清除任务。当日志保留时间或日志保留大小，任一条件满足即进行日志清除任务。
*   log.segment.bytes：日志分段大小。即一topic的一partition下的所有日志会进行分段，达到该大小，即进行日志分段，滚动出新的日志文件。
*   log.retention.check.interval.ms：日志保留策略定期检查时间间隔，单位ms。
*   log.segment.delete.delay.ms：日志分段删除延迟时间间隔，单位ms。
*   日志保留大小，保留时间以及日志分段大小可根据具体服务器磁盘空间大小，业务场景自行决定。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br><span class="line">6</span><br><span class="line">7</span><br><span class="line">8</span><br><span class="line">9</span><br><span class="line">10</span><br><span class="line">11</span><br><span class="line">12</span><br><span class="line">13</span><br><span class="line">14</span><br><span class="line">15</span><br><span class="line">16</span><br><span class="line">17</span><br><span class="line">18</span><br><span class="line">19</span><br><span class="line">20</span><br><span class="line">21</span><br><span class="line">22</span><br><span class="line">23</span><br><span class="line">24</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># The following configurations control the disposal of log segments. The policy can</span></span><br><span class="line"><span class="comment"># be set to delete segments after a period of time, or after a given size has accumulated.</span></span><br><span class="line"><span class="comment"># A segment will be deleted whenever *either* of these criteria are met. Deletion always happens</span></span><br><span class="line"><span class="comment"># from the end of the log.</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The minimum age of a log file to be eligible for deletion due to age</span></span><br><span class="line"><span class="comment">#log.retention.hours=168</span></span><br><span class="line">log.retention.minutes=<span class="number">10</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># A size-based retention policy for logs. Segments are pruned from the log as long as the remaining</span></span><br><span class="line"><span class="comment"># segments don't drop below log.retention.bytes. Functions independently of log.retention.hours.</span></span><br><span class="line"><span class="comment">#log.retention.bytes=1073741824</span></span><br><span class="line">log.retention.bytes=<span class="number">5368709120</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The maximum size of a log segment file. When this size is reached a new log segment will be created.</span></span><br><span class="line">log.segment.bytes=<span class="number">536870912</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># The interval at which log segments are checked to see if they can be deleted according</span></span><br><span class="line"><span class="comment"># to the retention policies</span></span><br><span class="line">log.retention.check.interval.ms=<span class="number">300000</span></span><br><span class="line"></span><br><span class="line">log.segment.delete.delay.ms=<span class="number">60000</span></span><br><span class="line"></span><br><span class="line">log.cleaner.enable=<span class="literal">true</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Zookeeper "Zookeeper")Zookeeper

Kafka zookeeper 配置

*   zookeeper.connect：zk连接地址
*   zookeeper.connection.timeout.ms：zk连接超时时间，默认6s。可根据具体的应用场景进行更改，特可采用如下配置。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br><span class="line">6</span><br><span class="line">7</span><br><span class="line">8</span><br><span class="line">9</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># Zookeeper connection string (see zookeeper docs for details).</span></span><br><span class="line"><span class="comment"># This is a comma separated host:port pairs, each corresponding to a zk</span></span><br><span class="line"><span class="comment"># server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".</span></span><br><span class="line"><span class="comment"># You can also append an optional chroot string to the urls to specify the</span></span><br><span class="line"><span class="comment"># root directory for all kafka znodes.</span></span><br><span class="line">zookeeper.connect=<span class="number">172.21</span>.<span class="number">195.89</span>:<span class="number">2181</span>,<span class="number">172.21</span>.<span class="number">195.90</span>:<span class="number">2181</span>,<span class="number">172.21</span>.<span class="number">195.91</span>:<span class="number">2181</span></span><br><span class="line"></span><br><span class="line"><span class="comment"># Timeout in ms for connecting to zookeeper</span></span><br><span class="line">zookeeper.connection.timeout.ms=<span class="number">60000</span></span><br></pre></td></tr></tbody></table>

### [](about:blank#Group_Coordinator_Settings "Group Coordinator Settings")Group Coordinator Settings

Kafka consumer group 协调配置

*   生产环境推荐配置3000
*   开发测试环境推荐配置0

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br><span class="line">6</span><br></pre></td><td class="code"><pre><span class="line"><span class="comment"># The following configuration specifies the time, in milliseconds, that the GroupCoordinator will delay the initial consumer rebalance.</span></span><br><span class="line"><span class="comment"># The rebalance will be further delayed by the value of group.initial.rebalance.delay.ms as new members join the group, up to a maximum of max.poll.interval.ms.</span></span><br><span class="line"><span class="comment"># The default value for this is 3 seconds.</span></span><br><span class="line"><span class="comment"># We override this to 0 here as it makes for a better out-of-the-box experience for development and testing.</span></span><br><span class="line"><span class="comment"># However, in production environments the default value of 3 seconds is more suitable as this will help to avoid unnecessary, and potentially expensive, rebalances during application startup.</span></span><br><span class="line">group.initial.rebalance.delay.ms=<span class="number">3000</span></span><br></pre></td></tr></tbody></table>

[](about:blank#producer_u914D_u7F6E "producer配置")producer配置
-----------------------------------------------------------

*   ProducerConfig.ACKS\_CONFIG：producer发送消息，server端确认机制。可配置值为0，1，all。0时，producer只需发送，不需要server端确认接收，适合对消息可靠性不敏感的应用系统；1时，producer发送，需要server端该topic的leader确认接收，适合对消息可靠性相对敏感的应用系统；all时，producer发送，需要server端该topic的全部结点均确认接收，适合对消息可靠性特别敏感的应用系统；业务的应用系统可根据具体的应用场景自行决定采用何种策略。
*   其他配置推荐使用默认值。

代码示例详情参见Kafka 快速开始文档。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br></pre></td><td class="code"><pre><span class="line">props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, <span class="string">"172.21.195.89:9092,172.21.195.90:9092,172.21.195.91:9092"</span>);</span><br><span class="line">props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, <span class="string">"org.apache.kafka.common.serialization.StringSerializer"</span>);</span><br><span class="line">props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, <span class="string">"org.apache.kafka.common.serialization.StringSerializer"</span>);</span><br><span class="line">props.put(ProducerConfig.ACKS_CONFIG, <span class="string">"1"</span>);</span><br></pre></td></tr></tbody></table>

[](about:blank#consumer_u914D_u7F6E "consumer配置")consumer配置
-----------------------------------------------------------

*   ConsumerConfig.GRO
*   \_ID\_CONFIG：配置consumer的group id。由应用系统进行各自的配置。
*   ConsumerConfig.ENABLE\_AUTO\_COMMIT\_CONFIG：配置consumer消费消息自动提交消费记录。也可改为手动提交，由应用系统根据需求决定。
*   其他配置推荐使用默认值。

<table><tbody><tr><td class="gutter"><pre><span class="line">1</span><br><span class="line">2</span><br><span class="line">3</span><br><span class="line">4</span><br><span class="line">5</span><br></pre></td><td class="code"><pre><span class="line">props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, <span class="string">"172.21.195.89:9092,172.21.195.90:9092,172.21.195.91:9092"</span>);</span><br><span class="line">props.put(ConsumerConfig.GROUP_ID_CONFIG, <span class="string">"test_consumer_group"</span>);</span><br><span class="line">props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, <span class="string">"true"</span>);</span><br><span class="line">props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, <span class="string">"org.apache.kafka.common.serialization.StringDeserializer"</span>);</span><br><span class="line">props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, <span class="string">"org.apache.kafka.common.serialization.StringDeserializer"</span>);</span><br></pre></td></tr></tbody></table>

[](about:blank#u53C2_u8003_u8D44_u6599 "参考资料")参考资料
--------------------------------------------------

1.  [Kafka官方性能测试报告](https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines "https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines")
2.  [Kafka官方性能测试配置参数](https://gist.github.com/jkreps/c7ddb4041ef62a900e6c "https://gist.github.com/jkreps/c7ddb4041ef62a900e6c")
3.  [Kafka性能测试报告](https://shiyueqi.github.io/2017/09/21/Kafka%E6%80%A7%E8%83%BD%E6%B5%8B%E8%AF%95/ "https://shiyueqi.github.io/2017/09/21/Kafka%E6%80%A7%E8%83%BD%E6%B5%8B%E8%AF%95/")
4.  [Kafka用户手册](https://shiyueqi.github.io/2017/09/21/Kafka%E7%94%A8%E6%88%B7%E6%89%8B%E5%86%8C/ "https://shiyueqi.github.io/2017/09/21/Kafka%E7%94%A8%E6%88%B7%E6%89%8B%E5%86%8C/")

[\# Kafka](https://shiyueqi.github.io/tags/Kafka/) [\# benchmark](https://shiyueqi.github.io/tags/benchmark/) [\# 消息中间件](https://shiyueqi.github.io/tags/%E6%B6%88%E6%81%AF%E4%B8%AD%E9%97%B4%E4%BB%B6/)

[Kafka性能测试](https://shiyueqi.github.io/2017/09/21/Kafka%E6%80%A7%E8%83%BD%E6%B5%8B%E8%AF%95/ "Kafka性能测试")

[Kafka快速开始](https://shiyueqi.github.io/2017/09/21/Kafka%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B/ "Kafka快速开始")

  

本文转自 [https://shiyueqi.github.io/2017/09/21/Kafka%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5/](https://shiyueqi.github.io/2017/09/21/Kafka%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5/)，如有侵权，请联系删除。