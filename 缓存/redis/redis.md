## Redis

#### Redis数据类型

1. 字符串类型

   > 字符串是Redis中最基本的数据类型，它能够存储任何类型的字符串，包含二进制数据。可以用于存储邮箱，JSON化的对象，甚至是一张图片，一个字符串允许存储的最大容量
   > 为512MB。字符串是其他四种类型的基础，与其他几种类型的区别从本质上来说只是组织字符串的方式不同而已。  

   - set/get 设置/获取
   - incr/decr（仅限于数字字符串）递增 /递减
   - incrby/decrby（仅限于数字字符串）递增/递减指定数字
   - append 向尾部拼接数据
   - mset 同时设置 多个key
   - mget 同时获取多个key
   - setnx 如果存在key 则返回0，如果没有则创建key并返回1

2. 散列类型（hash(key,value)）

   > 散列类型相当于Java中的HashMap，他的值是一个字典，保存很多key，value对，每对key，value的值个键都是字符串类型，换句话说，散列类型不能嵌套其他数据类型。一个
   > 散列类型键最多可以包含2的32次方-1个字段。  

   - hset/hget 赋值/获取
   - hmset/hmget 一次赋值/获取多个字段
   - hgetall 一次获取所有字段的值
   - hexists 判断字段是否存在
   - hsetnx 当字段不存在赋值返回1
   - hincrby 增加数字
   - hdel 删除字段
   - hkeys 获取所有的字段名
   - hvalues 获取所有的字段值
   - hlen 获取字段的数量

3. 列表类型（List）

   > 列表类型(list)用于存储一个有序的字符串列表，常用的操作是向队列两端添加元素或者获得列表的某一片段。列表内部使用的是双向链表（double linked list）实现的，所以向
   > 列表两端添加元素的时间复杂度是O(1),获取越接近列表两端的元素的速度越快。但是缺点是使用列表通过索引访问元素的效率太低（需要从端点开始遍历元素）。所以列表的使
   > 用场景一般如：朋友圈新鲜事，只关心最新的一些内容。借助列表类型，Redis还可以作为消息队列使用。  

   - lpush/rpush 向列表左端/右端添加元素
   - lpop/rpop 从左端/右端弹出元素
   - llen  获取列表中元素的个数
   - lrange 获取列表中某一片段的数据
   - lset 设置指定索引的元素值

4. 集合类型 

   > 集合中每个元素都是不同的，集合中的元素个数最多为2的32次方-1个，集合中的元素师没有顺序的  

   - sadd 添加元素
   - srem 删除元素
   - smembers 获得集合中所有的元素
   - sismember 判断元素是否在集合中
   - scard 获得集合中元素的个数
   - sdiff/sunion 对集合做差集/并集运算

5. 有序集合类型

   > 有序集合类型与集合类型的区别就是他是有序的。有序集合是在集合的基础上为每一个元素关联一个分数，这就让有序集合不仅支持插入，删除，判断元素是否存在等操作外，
   > 还支持获取分数最高/最低的前N个元素。有序集合中的每个元素是不同的，但是分数却可以相同。有序集合使用散列表和跳跃表实现，即使读取位于中间部分的数据也很快，时
   > 间复杂度为O(log(N))，有序集合比列表更费内存。  

   - ZADD 添加元素，用法： ZADD key score1 value1 [score2 value2 score3 value3 ...]

   - ZSCORE 获取元素的分数，用法： ZSCORE key value

   - ZRANGE 获取排名在某个范围的元素，用法： ZRANGE key start stop [WITHSCORE] ，按照元素从小到大的顺序排序，从0开始编号，包含start和stop对应的元素，
     WITHSCORE选项表示是否返回元素分数

   - ZREVRANGE 获取排名在某个范围的元素，用法： ZREVRANGE key start stop [WITHSCORE] ，和上一个命令用法一样，只是这个倒序排序的。

     ZRANGEBYSCORE 获取指定分数范围内的元素，用法： ZRANGEBYSCORE key min max ，包含min和max， (min 表示不包含min， (max 表示不包含max， +inf 表示无穷
     大

   - ZINCRBY 增加某个元素的分数，用法： ZINCRBY key increment value

   - ZCARD 获取集合中元素的个数，用法： ZCARD key

   - ZCOUNT 获取指定分数范围内的元素个数，用法： ZCOUNT key min max ，min和max的用法和5中的一样

   - ZREM 删除一个或多个元素，用法： ZREM key value1 [value2 ...]

   - ZREMRANGEBYRANK 按照排名范围删除元素，用法： ZREMRANGEBYRANK key start stop

   - ZREMRANGEBYSCORE 按照分数范围删除元素，用法： ZREMRANGEBYSCORE key min max ，min和max的用法和4中的一样

   - ZRANK 获取正序排序的元素的排名，用法： ZRANK key value

   - ZREVRANK 获取逆序排序的元素的排名，用法： ZREVRANK key value

   - ZINTERSTORE 计算有序集合的交集并存储结果，用法： ZINTERSTORE destination numbers key1 key2 [key3 key4 ...] WEIGHTS weight1 weight2 [weight3
     weight4 ...] AGGREGATE SUM | MIN | MAX ，numbers表示参加运算的集合个数，weight表示权重，aggregate表示结果取值

   - ZUNIONSTORE 计算有序几个的并集并存储结果，用法和14一样，不再赘述。  

