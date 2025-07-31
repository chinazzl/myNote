
# Nginx基础配置

## events事件驱动配置

```conf
events {
    # 使用epoll类型IO多路复用 默认select
    use epoll; 
    # 最大连接数限制为20W work多线程执行
    work_connections 204800;
    # 各个Worker通过锁来获取新连接，默认为on 代表使用互斥锁只允许一个锁进行执行；off会唤醒所有
    accept_mutex on;
}
```
1. worker_connections指令：worker_connections指令用于配置每个Worker进程能够打开的最大并发连接数量，指令参数为连接数的上限。
2. use指令：use指令用于配置IO多路复用模型，有多种模型可配置，常用的有select、epoll两种。
3. accept_mutex指令：accept_mutex指令用于配置各个Worker进程是否通过互斥锁有序接收新的连接请求。on参数表示各个Worker通过互斥锁有序接收新请求；off参数指每个新请求到达时会通知（唤醒）所有的Worker进程参与争抢，但只有一个进程可获得连接。

## 虚拟主机额配置 server指令

1. 使用listen指令直接配置监听端口
```conf
server {
    listen port/ip:port;
}
```
2. 虚拟主机名称配置：虚拟主机名称配置可使用server_name指令。基于微服务架构的分布式平台有很多类型的服务，比如文件服务、后台服务、基础服务等。

```conf
#后台管理服务虚拟主机demo 
server { 
    listen       80; 
    server_name  admin.crazydemo.com;  #后台管理服务的域名前缀为admin 
    location / { 
    default_type 'text/html'; 
    charset utf-8; 
    echo "this is admin server"; 
    } 
    } 
    #文件服务虚拟主机demo 
    server { 
    listen  80; 
    server_name  file.crazydemo.com;  #文件服务的域名前缀为
    admin 
    location / { 
    default_type 'text/html'; 
    charset utf-8; 
    echo "this is file server"; 
    } 
    } 
    #默认服务虚拟主机demo 
    server { 
    listen  80  default; 
    server_name  crazydemo.com  *.crazydemo.com;  #如果没有前缀，这就是默认访问的虚拟主机 
    location / { 
    default_type 'text/html'; 
    charset utf-8; 
    echo "this is default server"; 
    } 
}
```