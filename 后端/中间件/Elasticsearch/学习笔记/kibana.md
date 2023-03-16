## 启动Kibana

#### windows

```shell
    ##### 命令行
 cd kibana\bin
    .\kibana.bat
    #图形界面  在bin目录夏双击kibana.bat
    #shell
    start kibana\bin\kibana.bat
```

#### #Linux

```shell
 #命令行
    cd kibana/bin
    ./kibana
```

#### #MacOs

```shell
 #命令行
    cd kibana/bin
    ./kibana
    #图形界面  在bin目录夏双击kibana
    #shell
    open kibana/bin/kibana
```

**注意事项**

1. 如果ES服务启动做了配置，例如修改ip端口号或映射域名，则再kibana中也需要进行配置，默认是`localhost:9200`，这个时候需要在`kibana.yml`中进行配置`elasticsearch.hosts:["xxx"]`
2. 普通关闭服务是关闭不了kibana的，linux先使用`ps -ef | grep 5601`或者`ps -ef | grep kibana`或者`lsof -i :5601`获取pid，然后使用`kill -9 pid`结束进程 
3. 关于`Kibana server is nor ready yet`问题的原因和解决方法
   - Kibana和Elasticsearch的版本不兼容，需要保持一致
   - Elasticsearch的服务地址和Kibana配置的`elasticsearch.hosts:["xxx"]`不同，进行修改
   - Elasticsearch中禁止跨域访问，在elasticsearch配置文件中允许跨域
   - 服务器中开启了防火墙，关闭防火墙或者修改服务器的安全策略
   - Elasticsearch所在磁盘剩余空间不足90%，清理磁盘空间，配置监控和报警。
