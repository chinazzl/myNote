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
   - master：候选节点，主节点下的几个节点用来为主节点宕机后的候选节点
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

## Mapping

> Es中的Mapping类似与RDB中“表结构”概念，表结构里包含了字段名称、字段类型还有索引信息等，在Mapping中也包含了一些属性，比如字段名称、类型、字段使用的分词器、是否评分、是否创建索引等属性，并且在ES中一个字段可以有多个类型、分词器、评分等概念。

```http
# 查看mapping
GET /index/_mapping
```

1. #### Es数据类型

   1. 常见类型

      1. 数字类型：long integer byte double float half_float scaled_float unsigned_long
      2. keywords：
         * keyword：适用于索引结构化的字段，可以用于过滤、排序、聚合、keywords类型的字段只能通过精确值（exact value）搜索到，id应该用keyword
         * constant_keyword：是中包含相同值的关键字字段
         * wildcard：可针对类似grep的`通配符查询`优化日志行和类似的关键字值
         * 关键字字段通常用于排序、汇总和Term查询
      3. Dates（时间类型）：包括date和date_nanos
      4. alias：为现有字段定义别名
      5. binary：二进制
      6. range（区间类型）：integer_range float_range long_range double_range date_range
      7. text：当一个字段是要被全文搜索的、比如Email内容、产品描述，这些字段应该使用text类型，设置text类型以后，字段内容会被分析，在生成倒排索引以前，字符串会被分析器分析称一个一个词项，text类型的字段不用于排序，被少用于聚合（解释一下为啥不会为text创建正排索引：大量堆空间，尤其是在加载高基数text字段时，字段数据一旦加载到堆中，就在该字段的生命周期内保持在哪里，同样，加载字段数据试一个昂贵的过程，可能导致用户遇到延迟问题，这就是默认情况下禁用字段数据的原因）

   2. 对象关系类型

      1. object：用于单个json对象
      2. nested：用于json对象数组
      3. flattened：允许将整个JSON对象索引为单个字段

   3. 结构化类型

      1. geo_point：纬度/经度积分
      2. geo_shape：用于多边形等复杂形状
      3. point：笛卡尔坐标点
      4. shape：笛卡尔任意几何图形

   4. 特殊类型：

      1. IP地址：ip用于IPv4和IPv6地址

   5. 两种映射类型

      - Dynamic field mapping：

        - 整数 => long
        - 浮点数 => float
        - true | false => boolean
        - 日期 => date
        - 数组 => 取决于数组中第一个有效值
        - 对象 => object
        - 字符串 => 如果不是数字和日期类型，那会被映射为text和keyword 两个类型

      - Explicit field mapping：手动映射

        ```http
        PUT /product 
        {
        	"mappings": {
        		"properties": {
        			"field": {
        				"mapping_parameters": "parameters value"
        			}
        		}
        	}
        }
        ```

   6. 映射参数

      1. index：是否对创建对当前字段创建倒排索引，默认true，如果不创建索引，该字段不会通过索引被搜索到，但仍然会在source元数据中展示
      2. analyzer：指定分析器（character filter、token filters）
      3. boost：对当前字段相关度的评分权重，默认1
      4. coerce：是否允许强制类型转换 true "1"=> 1 false "1"=< 1
      5. copy_to：该参数允许将多个字段的值复制到组字段中，然后可以将其作为单个字段进行查询
      6. doc_value：为了提升排序和聚合效率，默认true，如果不需要对字段进行排序或聚合，也不需要通过脚本访问字段值，则可以禁用doc值以节省磁盘空间
      7. dynamic：控制是否可以动态添加新字段
         - true 新检索到的字段将添加到映射中
         - false 新检索到的字段将被忽略，这些字段将不会被索引，因此将无法搜索，但仍会出现在_source返回的匹配项中。这些字段不会添加到映射中，必须显式添加新字段
         - strict 如果检测到新字段 则会引发异常并拒绝文档，必须将新字段显式添加到映射中
      8. eager_global_ordinals：英语聚合的字段上，优化聚合性能。
      9. enable：是否创建倒排索引，可以对字段操作，也可以对索引操作，如果不创建索引，当然可以检索并在_source元数据中展示（**谨慎使用，该状态无法修改**）

      ```http
      PUT my_index
      {
      	"mappings":{
      		"enabled":false
      	}
      }
      ```

      10. fielddata：查询时内存数据结构，在首次用当前字段聚合、排序或者宅脚本使用时，需要字段为fielddata数据结构，并且创建倒排索引保存到堆中
      11. fields：给field创建多字段，用于不同目的（全文检索或者聚合分析排序）
      12. format：格式化
      13. ignore_about：超过长度将被忽略
      14. ignore_maiforned：忽略类型错误
      15. index_options：控制将哪些信息添加到反向索引中以进行搜索和突出显示，仅用于text字段
      16. index_phrases：提升exact_value查询速度，但是要小号更多磁盘空间
      17. index_prefixes：前缀搜索
          - min_chars：前缀最小长度
          - max_chars：前缀最大长度
      18. meta：附加辕信息
      19. normalizer
      20. norms：是否禁用评分（在filter和聚合字段上应该禁用）
      21. null_value：为null值设置默认值
      22. position_increment_gap:
      23. properties：除了mapping还可用于object属性设置
      24. search_analyzer: 设置单独的查询分析器
      25. similarity：为字段设置相关度算法，支持BM25 classic（TF-IDF） boolean
      26. store：设置字段是否仅查询
      27. term_vector: 运维参数
