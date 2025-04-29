# 问题背景介绍 :

问题1：很久之前在虚拟机中安装的redis，现使用springBoot项目中使用redis进行连接，启动项目时出现报错提示没有读取到配置文件，还是读取的是redis默认的localhost;
问题2： 解决可以正常读取后，又报错如下：

```txt
org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.redisson.api.RedissonClient]: Factory method 'redisson' threw exception; nested exception is org.redisson.client.RedisConnectionException: Unable to connect to Redis server: 192.168.43.201/192.168.43.201:6379 
```

## 解决方式：

问题1： 原因是我在其他模块中引入redis模块的时候，在当前模块的application.yml的`spring.profile=db`没有设置导致定位不到配置文件，太马虎了

问题2：当排查不是代码的问题后，感觉应该是安装redis的问题，我的redis是安装虚拟机的docker容器中的，排查步骤如下：
1. 执行`docker ps ` 查看redis是否正常启动
2. 执行`docker exec -it <containerID> /bin/bash` 进入容器，查看 `vim /etc/redis/redis.conf/redis.conf`文件的bind是否正常
3. 发现redis.conf文件是空的后，找到执行生成redis容器的命令，`sudo docker run -p 6379:6379 --name redis -v /usr/local/etc/redis.conf:/etc/redis/redis.conf  -v /usr/local/redis/data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes` 
4. 发现应该是执行命令的时候/usr/local/etc中没有redis.conf或者redis.conf是空的，映射到容器内部的时候将正常的redis.conf进行替换掉了导致为空
5. 查看redis中没有多少数据，将容器关闭并移除，在宿主机`/usr/local/etc/redis.conf`加入对应redis版本号的redis.conf内容
6. 重新执行步骤3的命令
7. 执行后发现redis无法启动出现，将 `locale-collate` 和`set-max-listpack-entries` 进行注释掉
    ```txt
        ERROR (Redis 7.0.10)                                                   
    Reading the configuration file, at line 422
    >>> 'locale-collate "C"'
    Bad directive or wrong number of arguments

     FATAL CONFIG FILE ERROR (Redis7.0.10)                                                                             
    Reading the configuration file, at line 1982
    >>> 'set-max-listpack-entries 128'
    Bad directive or wrong number of arguments
    ```
8. 重新执行后又出现，原因是因为redis旨在docker中运行与外界隔离，所以需要将配置文件的`bing 192.168.43.201` 设置为`0.0.0.0`即可
    ```txt
    1:M 29 Apr 2025 08:36:09.654 # Warning: Could not create server TCP listening socket 192.168.43.201:6379: bind: Cannot assign requested address
    1:M 29 Apr 2025 08:36:09.654 # Failed listening on port 6379 (TCP), aborting.
    ```