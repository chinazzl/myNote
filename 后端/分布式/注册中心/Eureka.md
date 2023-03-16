## Eureka

### CAP理论：

* C:：Consistency 数据一致性 ，数据在存在多副本的情况下，可能由于网络、机器故障、软件系统等问题导致数据写入部分副本成功，部分副本失败，进而造成副本之间数据不一致，存在冲突。满足一致性则要求对数据的更新操作成功之后，多副本的数据保持一致
* A：Availability 在任何时候客户端对集群进行读写操作时，请求能够正常响应，即在一定的延时内完成。
* P：Partition Tolerance 分区容忍性，即发生通信故障的时候，整个集群被分割为多个无法相互通信的分区时，集群仍然可用。

Zookeeper："C"P 的，并不是严格的强一致原则。因为zookeeper当过半数操作成功之后就返回，所以客户端B请求可能是客户端A写操作尚未同步的节点，那就不是客户端A写成功之后的数据。所以先执行一下同步操作，与leader同步一下数据，才能保持强一致。

Eureka：选择AP，因为作者认为分布式集群服务不可用时正常现象，所以在进行网络分区的时候保证服务能够正常提供服务注册和发现。采用PeerToPeer架构

1. 主从复制（传统）
   
   Master-Slave模式，一个主副本，其他为从副本。由主副本进行写操作，从副本进行同步。

2. 对等复制（Peer to Peer）
   
   Eureka Client可以设置多个服务实例，所有服务实例都可以提供写操作，如果一个server出现问题，可以切换到另一个server，默认重试次数为3。server进行复制操作的时候使用`HEADER_REPLICATION`的http header来将普通请求和复制请求区分出来。对于复制冲突，Eureka使用`lastDirtyTimestamp`和`heartbeat`进行解决
   
   - lastDirtyTimestamp：如果请求参数的lastDirtyTimestamp 大于server本地实例的lastDirtyTimestamp表示Eureka Server之间的数据出现冲突，返回404，要求应用实例重新进行注册操作。如果请求参数的lastDirtyTimestamp 小于 server本地实例的lastDirtyTimestamp，如果peer节点的复制请求，则表示数据出现冲突，返回409给peer，要求其同步自己最新的数据信息。
   - 作为补充，应用实例与Server之间的heartbeat进行数据的最终修复，如果发现应用实例和某个server的数据出现不一致，则server返回404.