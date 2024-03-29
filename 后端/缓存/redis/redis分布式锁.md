## Redis分布式锁的实现

### 可靠性

1. 互斥性：在任意时刻，我们只有一个客户端能够持有锁

2. 不会发生死锁：即使有一个客户端在持有锁的期间崩溃而没有主动解锁，也能保证后续其他客户端能加锁

3. 具有容错性：只要大部分的Redis节点正常运行，客户端就可以加锁和解锁

4. 解铃还须系铃人：加锁和解锁必须是同一个客户端，客户端自己不能把别人的加的锁给解了。

```java
public static boolean wrongGetLock2(Jedis jedis, String lockKey, int expireTime) { 
   long expires = System.currentTimeMillis() + expireTime;
   String expiresStr = String.valueOf(expires); 
    try {
         // 如果当前锁不存在，返回加锁成功
   if (jedis.setnx(lockKey, expiresStr) == 1) { 
       return true;
     }
   // 如果锁存在，获取锁的过期时间
   String currentValueStr = jedis.get(lockKey);
   if (currentValueStr != null && Long.parseLong(currentValueStr) < System.currentTimeMillis()) { 
       // 锁已过期，获取上一个锁的过期时间，并设置现在锁的过期时间
       String oldValueStr = jedis.getSet(lockKey, expiresStr);
      if (oldValueStr != null && oldValueStr.equals(currentValueStr)) { 
          // 考虑多线程并发的情况，只有一个线程的设置值和当前值相同，它才有权利加锁 
          return true;
     } 
 }
   // 其他情况，一律返回加锁失败
    }catch (Exception e) {
        logger.error("{}",e);
    }
}    
```

这一种错误示例就比较难以发现问题，而且实现也比较复杂。实现思路：使用 jedis.setnx() 命令实现加锁，其中key是锁，value是锁的过期时间。执行过程：1. 通过setnx()方法尝试加锁，如果当前锁不存在，返回加锁成功。2. 如果锁已经存在则获取锁的过期时间，和当前时间比较，如果锁已经过期，则设置新的过期时间，返回加锁成功。代码如下：
那么这段代码问题在哪里？

1. 由于是客户端自己生成过期时间，所以需要强制要求分布式下每个客户端的时间必须同步。 
2. 当锁过期的时候，如果多个客户端同时执行jedis.getSet() 方法，那么虽然最终只有一个客户端可以加锁，但是这个客户端的锁的过期时间可能被其他客户端覆盖。
3. 锁不具备拥有者标识，即任何客户端都可以解锁

#### 解锁：

```java
public static void wrongReleaseLock2(Jedis jedis, String lockKey, String requestId) { 
   // 判断加锁与解锁是不是同一个客户端
   if (requestId.equals(jedis.get(lockKey))) { 
       // 若在此时，这把锁突然不是这个客户端的，则会误解锁 
       jedis.del(lockKey);
 } 
}
```

如代码注释，问题在于如果调用 jedis.del() 方法的时候，这把锁已经不属于当前客户端的时候会解除他人加的锁。那么是否真的有这种场景？答案是肯定的，比如客户端A加锁，一段时间之后客户端A解锁，在执行jedis.del() 之前，锁突然过期了，此时客户端B尝试加锁成功，然后客户端A再执行del()方法，则将客户端B的锁给解除了。

#### 正解：

```java
public class RedisTool {
   private static final Long RELEASE_SUCCESS = 1L; 
   /**
    * 释放分布式锁
    * @param jedis Redis客户端 
    * @param lockKey 锁
    * @param requestId 请求标识 
    * @return 是否释放成功
    */
   public static boolean releaseDistributedLock(Jedis jedis, String lockKey, String requestId) {
       String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end"; 
       Object result = jedis.eval(script, Collections.singletonList(lockKey), Collections.singletonList(requestId));
       if (RELEASE_SUCCESS.equals(result)) { 
           return true;
     }
       return false; 
 }
}
```
