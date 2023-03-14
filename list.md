1. Java 本地锁到分布式锁，各种锁的场景，为什么要用，以及不同锁实现方式的底层，优缺点，还有 volitale
2. hashmap  ，这个就不用多说了，put 过程啊，为什么线程不安全，1.7 和 1.8 的区别，为什么要用红黑树等等，可问的很多
3. 多线程实现方式，线程池核心参数，运行过程，有什么问题需要注意的
4. jvm  方面，cms  问的比较多，和 g1 的区别，还有 rootsearching，类加载过程，jvm 内存模型以及各个模块运用
5. redis  哨兵同步，投票选举，集群模式，持久化方式，zset 实现方式
6. ~~dubbo 调用链路， 其 spi 和 java 的有什么区别~~
7. mysql  索引优化思路，事务 mvcc，日志系统，主从同步， buffer  pool ，分库分表等
8. zookeeper 脑裂问题，leader 选举过程
9. spring bean 生命周期，循环依赖，ioc 和 aop ，事务实现方式等
10. kafka 高吞吐原因，丢失消息的场景，副本维护，leader 选举，消息幂等性保证等

GC、
分布式锁：
    redisson:
    zookeeper: 
redis和mysql同步：
    mysql主从同步：master -> 写数据 -> 写入binglog -> slave开启一个I/O线程读取binglog -> 存入relaylog -> slave执行relaylog的语句进行同步

`redis同步： slave -> 向master发送psync指令请求同步,master响应FullSync(全同步)，并带上主库的runId和offset -> master执行bgsave命令，生成RDB文件，
           发送给slave库，slave执行RDB文件，主库将同步过程中新来的数据会写到 replication buffer中 -> 主库完成RDB发送后，会把replication buffer中的修改操作发给从库，从库再重新执行这些操作。这样主从库就实现同步啦`

分布式事务: CAP(一致性、可用性、分区容忍性) 
    XA方案： 2PC 两阶段提交：pepare阶段：资源准备，每个操作在本地事务中进行事务操作，并写入(undo/Redo日志) 对资源上锁；commit阶段：事务管理器收到事务提交的信息，如果失败则给每个参与者发送回滚消息，根据事务管理器指令进行回滚操作，最后释放资源。
    TCC：事务补偿机制 Try、Confirm、Cancel
注册中心满足CAP条件。
