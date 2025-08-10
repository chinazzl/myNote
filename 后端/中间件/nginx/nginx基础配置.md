
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

## 错误页面配置

错误页面的配置指令为error_page，格式如下：
`error_page code ... [=[response]] uri; `
code表示响应码，可以同时配置多个；uri表示错误页面，一般为服务器上的静态资源页面。

```conf
# 例如，下面的例子分别为404、500等错误码设置了错误页面，具体设置如下：
#后台管理服务器demo 
server { 
    listen       80; 
    server_name  admin.crazydemo.com; 
    root /var/www/;  
    location / { 
        default_type 'text/html'; 
        charset utf-8; 
        echo "this is admin server"; 
    } 
    #设置错误页面 
    error_page  404  /404.html; 
    #设置错误页面 
    error_page  500 502 503 504  /50x.html; 
} 
```
为了防止404页面被劫持，也就是被前面的代理服务器换掉，则可以修改响应状态码，参考如下：
`error_page  404  =200  /404.html    #防止404页面被劫持 `

## 长连接配置
配置长连接的有效时长可使用keepalive_timeout指令，格式如下：
`keepalive_timeout timeout [header_timeout]; `

如果要配置长连接的一条连接允许的最大请求数，那么可以使用keepalive_requests指令，格式如下：
`keepalive_requests  number; `

配置项中的number参数用于设置在一条长连接上允许被请求的资源的最大数量，默认为100。
如果要配置向客户端发送响应报文的超时限制，那么可以使用下面的指令：
`send_timeout time; `


## Nginx核心模块——内部变量：

Nginx核心模块ngx_http_core_module中定义了一系列存储HTTP请求信息的变量，例如`$http_user_agent、$http_cookie`等。这些内置变量在Nginx配置过程中使用较多，故对其进行介绍，具体如下：
（1）`$arg_PARAMETER`：请求URL中以PARAMETER为名称的参数值。请求参数即URL的“？”号后面的name=value形式的参数对，变量$arg_name得到的值为value。
另外，`$arg_PARAMETER`中的参数名称不区分字母大小写，例如通过变量$arg_name不仅可以匹配name参数，也可以匹配NAME、Name请求参数，Nginx会在匹配参数名之前自动把原始请求中的参数名调整为全部小写的形式。
（2）`$args`：请求URL中的整个参数串，其作用与$query_string 相同。
（3）`$binary_remote_addr`：二进制形式的客户端地址。
（4）`$body_bytes_sent`：传输给客户端的字节数，响应头不计算在内。
（5）`$bytes_sent`：传输给客户端的字节数，包括响应头和响应体。
（6）`$content_length`：等同于$http_content_length，用于获取请求体body的大小，指的是Nginx从客户端收到的请求头中Content-Length字段的值，不是发送给客户端响应中的Content-Length字段
值，如果需要获取响应中的Content-Length字段值，就使用$sent_http_content_length变量。
（7）`$request_length`：请求的字节数（包括请求行、请求头和请求体）。注意，由于`$request_length`是请求解析过程中不断累加的，如果解析请求时出现异常，那么`$request_length`是已经累加部分的长度，并不是Nginx从客户端收到的完整请求的总字节数（包括请求行、请求头、请求体）。
（8）`$connection`：TCP连接的序列号。
（9）`$connection_requests`：TCP连接当前的请求数量。
（10）`$content_type`：请求中的Content-Type请求头字段值。
（11）`$cookie_name`：请求中名称name的cookie值。
（12）`$document_root`：当前请求的文档根目录或别名。
（13）`$uri`：当前请求中的URI（不带请求参数，参数位于`$args 变量）`。`$uri`变量值不包含主机名，如“/foo/bar.html”。此参数可以修改，可以通过内部重定向。
（14）`$request_uri`：包含客户端请求参数的原始URI，不包含主机名，此参数不可以修改，例如“/foo/bar.html？name=value”。
（15）`$host`：请求的主机名。优先级为：HTTP请求行的主机名>HOST请求头字段>符合请求的服务器名。
（16）`$http_name`：名称为name的请求头的值。如果实际请求头name中包含中画线“-”，那么需要将中画线“-”替换为下画线“_”；如果实际请求头name中包含大写字母，那么可以替换为小写字母。例如获取Accept-Language请求头的值，变量名称为$http_accept_language。
（17）`$msec`：当前的UNIX时间戳。UNIX时间戳是从1970年1月1日（UTC/GMT的午夜）开始所经过的秒数，不考虑闰秒。
（18）`$nginx_version`：获取Nginx版本。
（19）`$pid`：获取Worker工作进程的PID。
（20）`$proxy_protocol_addr`：代理访问服务器的客户端地址，如果是直接访问，那么该值为空字符串。
（21）`$realpath_root`：当前请求的文档根目录或别名的真实路径，会将所有符号连接转换为真实路径。
（22）`$remote_addr`：客户端请求地址。
（23）`$remote_port`：客户端请求端口。
（24）`$request_body`：客户端请求主体。此变量可在location中使用，将请求主体通过proxy_pass、fastcgi_pass、uwsgi_pass和scgi_pass传递给下一级的代理服务器。
（25）`$request_completion`：如果请求成功，那么值为OK；如果请求未完成或者请求不是一个范围请求的最后一部分，那么值为空。
（26）`$request_filename`：当前请求的文件路径，由root或alias指令与URI请求结合生成。
（27）`$request_length`：请求的长度，包括请求的地址、HTTP请求头和请求主体。
（28）`$request_method`：HTTP请求方法，比如GET或POST等。
（29）`$request_time`：处理客户端请求使用的时间，从读取客户端的第一个字节开始计时。
（30）`$scheme`：请求使用的Web协议，如HTTP或HTTPS。
（31）`$sent_http_name：设置任意名称为name的HTTP响应头字段。例如，如果需要设置响应头Content-Length，那么将“-”替换为下画线，大写字母替换为小写字母，变量为$sent_http_content_length。
（32）`$server_addr`：服务器端地址为了避免访问操作系统内核，应将IP地址提前设置在配置文件中。
（33）`$server_name`：虚拟主机的服务器名，如crazydemo.com。
（34）`$server_port`：虚拟主机的服务器端口。
（35）`$server_protocol`：服务器的HTTP版本，通常为HTTP/1.0 或HTTP/1.1。
（36）`$status`：HTTP响应代码。

