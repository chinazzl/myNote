# zookeeper

> ZooKeeper 是一个开源的分布式协调服务。它是一个为分布式应用提供一致性 服务的软件，分布式应用程序可以基于 Zookeeper 实现诸如数据发布/订阅、 负载均衡、命名服
> 务、分布式协调/通知、集群管理、Master 选举、分布式锁和 分布式队列等功能。  

Zookeeper保证了如下分布式一致性特性：
1. 顺序一致性：（Sequential Consistency）
   含义：来自同一个客户端的更新请求，会按照发送顺序被应用到 ZooKeeper 中。
   理解：
      客户端 A 先创建节点 /a，再创建 /b，那么所有客户端看到的顺序都是先有 /a 后有 /b
      保证了操作的因果关系
2. 原子性（Atomicity）
   含义：每个更新操作要么成功，要么失败，不存在部分成功的情况。
   理解：
      创建节点要么完全创建成功，要么完全失败
      没有中间状态
3. 单一视图（Single System Image）
   含义：无论客户端连接到哪个服务器，看到的数据视图都是一致的。
   理解：
      客户端连接到任何 ZooKeeper 节点，看到的数据都相同
      但注意：这是最终一致性，可能有短暂延迟

4. 可靠性（Reliability）
   含义：一旦更新被应用，它将持久化，直到客户端覆盖更新。
   理解：
      数据一旦写入成功，就不会丢失
      除非被显式修改或删除

5. 实时性/最终一致性（Timeliness）
   含义：客户端看到的数据在一定时间范围内是最新的。
   理解：
      ZooKeeper 不保证强一致性（实时读到最新数据）
      但保证最终一致性（一定时间内会同步到最新数据）
      客户端读操作可能读到稍旧的数据

## Watcher机制——数据变更通知

Zookeeper允许客户端向服务端的某个Znode注册一个wathcer监听，当服务端的一些指定事件触发了这个Watcher，服务端会向指定客户端发送一个事件通知来实现分布式的通知功能，然后客户端根据Watcher通知状态和事件类型做出业务上的改变。

工作机制：
- 客户端注册watcher
- 服务端处理watcher
- 客户端回调watcher

## 服务器角色：

#### Leader：
1. 事务请求的唯一调度和处理者，保证集群事务处理的顺序性
2. 肌群内部各服务的调度者

#### Follower：
1. 处理客户端的非事务请求，转发事务请求给Leader服务器
2. 参与事务请求Proposal的投票
3. 参与Leader的选举投票

#### Observer
1. 3.0版本以后引入一个服务器角色，在不应系那个集群事务处理能力的基础上提升集群的非事务处理能力
2. 处理客户端的非事务请求，转发事务给Leader服务器
3. 不参与任何形式的投票

## 分布式锁

1. 先创建一个临时有序节点znode
2. 客户端扫描 捕获所有的节点，如果发现自己创建的节点顺序最小，则相当于获取了锁，当锁使用结束后，会将节点进行删除
3. 如果发现创建的节点不是最小，则表示没有获取到锁，客户端会找到比自己小的节点并且加入到watcher中进行监听，如果监听到比自己小的被删除则会收到通知，
   此时再次判断自己创建的是否是最小的，如果不是则继续监听

### 四种类型znode

1. PERSISTENT 持久化节点
   
   除非手动删除，否则节点一直存在于 Zookeeper 上  

2. EPHEMRAL 临时节点
   
   临时节点的生命周期与客户端会话绑定，一旦客户端会话失效（客户端与 zookeeper 连接断开不一定会话失效），那么这个客户端创建的所有临时节点 都会被移除。  

3. PERSISTENT_SEQUENTIAL 持久化顺序节点
   
   基本特性同持久节点，只是增加了顺序属性，节点名后边会追加一个由父节点维 护的自增整型数字  

4. EPHEMRAL_SEQUENTIAL  临时顺序节点
   
   基本特性同临时节点，增加了顺序属性，节点名后边会追加一个由父节点维护的 自增整型数字  

#### zookeeper原理

zookeeper的核心是/color:Red`原子广播`形式，这个机制保证了各个Server之间的同步，实现这个机制的协议是zab协议，他么你分别是`恢复模式`和`广播模式`，当服务刚启动或者leader宕机的时候，zab就进入了恢复模式，当领导者被选举出来，
并且大多数Server完成了和leader的状态同步之后，恢复模式就结束了，状态同步 保证leader和Server具有相同的系统状态。

#### zookeeper是如何保持事务顺序一致性

zookeeper采用全局递增的事务id来标志，所有的proposal（提议）都在被提出的时候加上zxid，zxid 实际上是一个 64 位的数字，高 32 位是
epoch（ 时期; 纪元; 世; 新时代）用来标识 leader 周期，如果有新的 leader 产生出来，epoch会自增，低 32 位用来递增计数。当新产生 proposal 的时候，会依据数据库的两
阶段过程，首先会向其他的 server 发出事务执行请求，如果超过半数的机器都能执行并且能够成功，那么就会开始执行。  

#### zookeeper应用场景

1. 数据发布/订阅 
   ∙ 数据存储：将数据（配置信息）存储到 Zookeeper 上的一个数据节点
   ∙ 数据获取：应用在启动初始化节点从 Zookeeper 数据节点读取数据，并在该节点上注册一个数据变更 Watcher
   ∙ 数据变更：当变更数据时，更新 Zookeeper 对应节点数据，Zookeeper会将数据变更通知发到各客户端，客户端接到通知后重新读取变更后的数据即可。
2. 负载均衡：一致性哈希策略
   zk 的命名服务命名服务是指通过指定的名字来获取资源或者服务的地址，利用 zk 创建一个全局的路径，这个路径就可以作为一个名字，指向集群中的集群，提供的服务的地址，或者一个远程的对象等等。
   使用zookeeper的临时节点来维护server的地址列表，然后选择负载均衡策略来对请求进行分配。
3. 命名服务
4. 分布式协调/通知
5. 集群管理
6. Master选举
7. 分布式锁

```plantuml
@startuml "zokeeper lock"
left to right direction
actor c
component zookeeper {
    card "/lock"  as lock
    card "/templock1" as templock1
    card "/templock2" as templock2

}
c --> lock  
lock --> templock1
note left: "创建一个临时有序节点"
lock --> templock2
note left: "创建一个临时有序节点"
@enduml
```

#### Zookeeper 下Server工作状态

* LOOKING 当前Server不知道leader是谁，正在搜寻
* LEADING 当前Server即为选举出来的leader
* FOLLOWING leader已经选举出来，当前Server与之同步。

#### zookeeper 是如何选举出来leader的

（1） 选举线程由当前 Server 发起选举的线程担任，其主要功能是对投票结果进行统计，并选出推荐的Server；
（2） 选举线程首先向所有 Server 发起一次询问(包括自己)；
（3） 选举线程收到回复后，验证是否是自己发起的询问(验证 zxid 是否一致)，然后获取对方的 id(myid)，并存储到当前询问对象列表中，最后获取对方提议的 leader 相关信
息(id,zxid)，并将这些信息存储到当次选举的投票记录表中；
（4） 收到所有 Server 回复以后，就计算出 zxid 最大的那个 Server，并将这个 Server 相关信息设置成下一次要投票的 Server；
（5） 线程将当前 zxid 最大的 Server 设置为当前 Server 要推荐的 Leader，如果此时获胜的 Server 获得 n/2 + 1 的 Server 票数，设置当前推荐的 leader 为获胜的 Server，
将根据获胜的 Server 相关信息设置自己的状态，否则，继续这个过程，直到 leader 被选举出来。 通过流程分析我们可以得出：要使 Leader 获得多数Server 的支持，则 Server
总数必须是奇数 2n+1，且存活的 Server 的数目不得少于 n+1. 每个 Server 启动后都会重复以上流程。在恢复模式下，如果是刚从崩溃状态恢复的或者刚启动的 server 还会从磁
盘快照中恢复数据和会话信息，zk 会记录事务日志并定期进行快照，方便在恢复时进行状态恢复

```plantuml
@startuml "Leader选举"
left to right direction
archimate #Technology "Server0" as s0 <<technology-device>>
archimate #Technology "Server1" as s1 <<technology-device>>
archimate #Technology "Server2" as s2 <<technology-device>>

component leader {
   card "thread" as t
}
s0  --> t 
note right: "创建一个统计线程"
s0 --> s1
note right: "s0对 s1 进行询问，并且和s1交换数据"
s0 --> s2 
note right: "s0对 s1 进行询问，并且和s1,s2交换数据"

legend left
1. s0 创建一个统计线程，用于统计服务投票，此时的状态是LOOKING
2. s0对s1进行询问，s1给自己投票，s0和s1交换数据。因为s1的编号最大，但是没有超过半数 ,s1 的状态还是LOOKING
3. s0对s2进行询问，s2给自己投票，s0和s1交换数据。s2的编号最大，现在投票数正好超过半数，则s2的 状态是Leading
4. 其他两个是Following
end legend
@enduml
```

#### Zookeeper 如何保证主从同步

Zookeeper 的核心是原子广播机制，这个机制保证了各个 server 之间的同步。 实现这个机制的协议叫做 Zab 协议。Zab 协议有两种模式，它们分别是恢复模 式和广播模式。
恢复模式
当服务启动或者在领导者崩溃后，Zab就进入了恢复模式，当领导者被选举出 来，且大多数 server 完成了和 leader 的状态同步以后，恢复模式就结束了。状 态同步保证了
leader 和 server 具有相同的系统状态。
广播模式
一旦 leader 已经和多数的 follower 进行了状态同步后，它就可以开始广播消息 了，即进入广播状态。这时候当一个 server 加入 ZooKeeper 服务中，它会在 恢复模式下启动，
发现 leader，并和 leader 进行状态同步。待到同步结束，它也参与消息广播。ZooKeeper 服务一直维持在 Broadcast 状态，直到 leader 崩溃了或者 leader 失去了大部分的
followers 支持。

#### Zookeeper 崩溃如何进行恢复

在Zookeeper集群服务的运行过程中，如果Leader节点发生故障，无法处理Follower节点提交的事务请求，根据ZAB协议，此时的Zookeeper集群就会暂时停止对外提供服务，进入崩溃恢复。如果此时崩溃的Leader服务故障被排除，加入到Zookeeper集群中，它也会进入Looking状态，参与选举
   1. Leader election
      在Leader选举阶段，Zookeeper服务都为Looking状态，每个Zookeeper服务都会用自身的ZXID和myid值形成选票，第一轮选举和Zookeeper启动时第一轮选举的结果一样，Zookeeper服务的选票信息都是自身的信息，所以不会产生Leader，无Leader产生Zookeeper服务就会更新自身的选票信息，进入下一轮选举，直到选举出Leader。
      这一阶段选举出来的Leader还不能直接作为真正的Leader去处理事务请求，它还需要再次确认自身的数据是最新的，避免网络等原因出现多个Leader情况，接下来进入Discovery发现阶段

   2. Discovery
      在Discovery发现阶段，上一阶段产生的Follower服务会把自身的ZXID中的epoch纪元值发送给Leader服务，Leader服务接收到所有的Follower的epoch纪元值后选出其中最大的epoch纪元值，然后在基础上进行+1，作为最新的epoch纪元值，返回给所有的Follower。
      Follower接收到Leader发送的最新epoch纪元值后，根据此epoch纪元值来更新自己的ZXID，然后再把更新后的ZXID、最新的历史事务日志和ACK确认信息返回给Leader。
      Leader接收到ACK确认信息后，把接收到最新的ZXID和最新的历史事务日志和自身作比较，把最新的更新到自身。然后进入下一个阶段 Synchronization接通弧阶段
      
   3. Synchronization
      Synchronization同步阶段的主要作用是把Leader最新的数据和日志同步到Follower中，当半数以上的Follower同步数据成功后，Leader才能成为真正的Leader，就可以处理事务请求了。