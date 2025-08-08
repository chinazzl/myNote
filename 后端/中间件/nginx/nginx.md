# Nginx

## Nginx两种启动方式
1. 单进程启动：此时系统中仅有一个进程，当进程既充当master管理进程角色，又充当Worker工作进程角色
2. 多进程启动：此时系统有且仅有 一个Master管理进程，至少有一个Worker工作进程
   1. Master管理进程主语奥负责调度worker工作进程，比如加载配置、启动工作进程、接受来自外界的信号、向各worker进程发送信号、监听Worker进程的运行状态等。
   2. Master负责创建监听套接口，交由Worker进程进行连接监听
   3. Worker进程主要用来处理网络事件，当一个Worker进程在接收一条连接通道之后，就开始读区请求、解析请求、处理请求，处理完成产生数据后，再返回给客户端，最后断开连接通道。一个请求之可能在一个Worker进程中处理。

## nginx.conf详解

1. main全局配置：影响Nginx全局的指令，一般由运行Nginx度武器的用户组、Nginx进程PID存放路径、日志存放路径、配置文件引入、允许生成的Worker进程数等。
2. events事件处理模式配置块：配置Nginx服务器的IO多路复用模型、客户端的最大连接数限制等。Nginx支持多种IO多路复用模型，可以使用use指令在配置文件中设置IO读写模型
3. HTTP协议配置块：可以配置HTTP协议处理相关的参数，比如keepalive长连接参数、GZIP压缩参数、日志输出参数、minme-type参数、连接超时参数等
4. server虚拟服务器配置块：配置虚拟主机的相关参数，如主机名称、端口等。一个HTTP协议配置块中可以有多个server虚拟服务器配置块。
5. location路由规则块：配置客户端请求的路由匹配规则以及请求过程中的 处理流程。一个server虚拟服务器配置块中一般会有多个location路由规则块。

### 配置文件说明：
1. nginx.conf 应用程序基本配置文件
2. mime.types：与MIME类型关联的扩展配置文件
3. fastcgi.conf：与FastCGI相关的配置文件
4. proxy.conf：与Proxy相关的配置文件
5. sites.conf：单独配置Nginx提供的虚拟机主机