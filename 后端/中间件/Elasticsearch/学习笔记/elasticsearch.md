## ES启动

### 启动单节点服务

```shell
# Windows
    #命令行
    cd elasticsearch\bin
    .\elasticsearch -d
    # 图形界面 在bin目录夏双击elasticsearch.bat
    # shell
    start elasticsearch\bin\elasticsearch.bat
#Linux
	#命令行
    cd elasticsearch/bin
    ./elasticsearch -d
# Mac Os
	 #命令行
    cd elasticsearch/bin
    ./elasticsearch -d
   #图形界面 在bin目录下双击elasticsearch
   #shell
   open elasticsearch/bin/elasticsearch
```

### 在单个项目启动多个节点
```shell
#Linux/MACOS
./elasticsearch -E path.data=data1 -E path.logs=log1 -E node.name=node1 -E cluster.name=own-learn
./elasticsearch -E path.data=data2 -E path.logs=log2 -E node.name=node2 -E cluster.name=own-learn
#Windows
.\elasticsearch -E path.data=data1 -E path.logs=log1 -E node.name=node1 -E cluster.name=own-learn
.\elasticsearch -E path.data=data2 -E path.logs=log2 -E node.name=node2 -E cluster.name=own-learn
```

### 倒排索引

倒排索引：

1. 倒排表：int有序数组，存储了匹配某个term的所有id。
   - Roaring Bitmaps 压缩算法
   - Frame Of Reference 压缩算法
   - Trial 前缀树数据结构
   - FST 数据结构
2. 词项字典：
   - tip：词典索引，存放前缀后缀指针，需要内存加载
   - tim：后缀词块，倒排表指针
   - doc：倒排表、词频
3. 词项索引

## 集群、节点、分片

### 集群

- 多个节点（ES实例构）成一个集群
- 原生分布式
- 一个节点≠一台服务器
- 集群状态
  - GREEN：所有一个Primary 和Replica均为active，集群健康。
  - YELLOW：至少有一个Replica不可用，但是所有Primary均为active，数据仍然可以保证完整性
  - RED：至少有一个Primary为不可用状态，数据不完整，集群不可用。

### 节点

1. 每个节点就是一个Elasticsearch实例
2. 一个节点 ≠一台服务器
3. 节点角色
   - master：候选节点
   - data：数据节点
     - data_content: 数据内容节点
     - data_hot: 热节点
     - data_warm: 索引不再定期更新，但扔可查询。
     - data_code: 冷节点，制度索引
   - ingest：预处理节点，作用类似于Logstash中的Filter
   - ml：机器学习节点
   - remote_cluster_client：候选客户端节点
   - transform：转换节点
   - voting_only：仅投票节点

### 分片

- 一个索引包含一个或多个分片，在7.0之前默认五个分片，每个主分片一个副本；在7.0之后默认一个主分片。副本可以在索引创建之后修改数量，但是主分片的数量一旦确定不可修改，只能创建索引
- 每个分片都是一个Luncene实例，有完整的创建索引和处理索引的能力
- 一个doc不可能同时存在于多个主分片中，但是当每个主分片的副本数量不为一时，可以同时存在于多个副本中。
- 每个主分片和其副本分片不能同时存在于同一个节点上，所以最低的可用配置是两个节点互为主备。
