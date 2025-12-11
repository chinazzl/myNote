# Nginx安装
> 安装Nginx：https://nginx.org/en/download.html


## Linux:

1. 安装编译依赖：
    ```sh
    # 安装编译依赖
    sudo apt-get update
    sudo apt-get install -y build-essential libpcre3 libpcre3-dev \
        zlib1g zlib1g-dev libssl-dev libgd-dev libgeoip-dev
    ```
2. 执行.configure
    ```sh
        #!/bin/bash

        # Nginx 编译配置脚本
        # 使用前请先安装必要的依赖：
        # sudo apt-get update
        # sudo apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libgeoip-dev

        ./configure \
            # === 基础路径配置 ===
            --prefix=/usr/local/nginx \                      # Nginx 安装根目录
            --sbin-path=/usr/local/nginx/sbin/nginx \        # 可执行文件路径
            --conf-path=/usr/local/nginx/conf/nginx.conf \   # 主配置文件路径
            --error-log-path=/var/log/nginx/error.log \      # 错误日志路径
            --http-log-path=/var/log/nginx/access.log \      # 访问日志路径
            --pid-path=/var/run/nginx.pid \                  # PID 文件路径
            --lock-path=/var/run/nginx.lock \                # 锁文件路径
            \
            # === 运行用户配置 ===
            --user=nginx \                                   # 运行 Nginx 的用户
            --group=nginx \                                  # 运行 Nginx 的用户组
            \
            # === 临时文件路径配置 ===
            --http-client-body-temp-path=/var/cache/nginx/client_temp \  # 客户端请求体临时文件
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \         # 代理临时文件
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \     # FastCGI 临时文件
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \         # uWSGI 临时文件
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \           # SCGI 临时文件
            \
            # === 核心模块配置 ===
            --with-http_ssl_module \                         # 启用 HTTPS 支持（SSL/TLS）
            --with-http_v2_module \                          # 启用 HTTP/2 协议支持
            --with-http_realip_module \                      # 获取真实客户端 IP（用于反向代理）
            --with-http_addition_module \                    # 在响应前后添加内容
            --with-http_sub_module \                         # 替换响应中的字符串
            --with-http_dav_module \                         # 启用 WebDAV 协议支持
            --with-http_flv_module \                         # 支持 FLV 流媒体
            --with-http_mp4_module \                         # 支持 MP4 流媒体
            --with-http_gunzip_module \                      # 为不支持 gzip 的客户端解压
            --with-http_gzip_static_module \                 # 发送预压缩的 .gz 文件
            --with-http_random_index_module \                # 随机选择目录索引
            --with-http_secure_link_module \                 # 检查请求链接的真实性
            --with-http_stub_status_module \                 # 提供基本状态信息页面
            --with-http_auth_request_module \                # 基于子请求的身份验证
            --with-http_slice_module \                       # 将请求分割成多个子请求
            \
            # === 性能和缓存模块 ===
            --with-http_degradation_module \                 # 在内存不足时返回 204 或 444
            --with-http_image_filter_module \                # 图片处理（裁剪、缩放、旋转）
            --with-http_geoip_module \                       # 根据 IP 获取地理位置信息
            \
            # === Stream 模块（TCP/UDP 代理）===
            --with-stream \                                  # 启用 TCP/UDP 代理功能
            --with-stream_ssl_module \                       # Stream 的 SSL/TLS 支持
            --with-stream_realip_module \                    # Stream 获取真实客户端 IP
            --with-stream_geoip_module \                     # Stream 的 GeoIP 支持
            --with-stream_ssl_preread_module \               # 在不解密的情况下读取 SNI
            \
            # === 邮件代理模块 ===
            --with-mail \                                    # 启用邮件代理功能
            --with-mail_ssl_module \                         # 邮件代理的 SSL 支持
            \
            # === 其他选项 ===
            --with-threads \                                 # 启用线程池支持
            --with-file-aio \                                # 启用异步文件 I/O
            --with-pcre \                                    # 使用 PCRE 正则表达式库
            --with-pcre-jit \                                # 启用 PCRE JIT 编译
            --with-compat \                                  # 启用动态模块兼容性
            --with-debug                                     # 启用调试日志（生产环境可去掉）

        # 编译完成后执行：
        # make
        # sudo make install
        # 
        # 创建 nginx 用户：
        # sudo useradd -r -M -s /sbin/nologin nginx
        #
        # 创建临时目录：
        # sudo mkdir -p /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}
        # sudo chown -R nginx:nginx /var/cache/nginx
    ```
3. 进行编译 `sudo make `
4. 安装 `sudo make install`
5. 创建用户以及临时目录
    ```sh
        #创建 nginx 用户：
        sudo useradd -r -M -s /sbin/nologin nginx
        # 创建临时目录：
        sudo mkdir -p /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}
        sudo chown -R nginx:nginx /var/cache/nginx
    ```
6. 创建软链接 `sudo ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx`
7. 创建必要目录：
    ```sh
        # 创建日志目录
        sudo mkdir -p /var/log/nginx

        # 创建缓存目录
        sudo mkdir -p /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}

        # 设置权限
        sudo chown -R nginx:nginx /var/log/nginx
        sudo chown -R nginx:nginx /var/cache/nginx
    ```
    
8. 创建systemd文件（生产环境）进行通过systemctl进行管理

    ```sh
        #创建systemd文件
        sudo nano /etc/systemd/system/nginx.service


        [Unit]
        Description=The NGINX HTTP and reverse proxy server
        After=syslog.target network-online.target remote-fs.target nss-lookup.target
        Wants=network-online.target

        [Service]
        Type=forking
        PIDFile=/var/run/nginx.pid
        ExecStartPre=/usr/local/nginx/sbin/nginx -t
        ExecStart=/usr/local/nginx/sbin/nginx
        ExecReload=/bin/kill -s HUP $MAINPID
        ExecStop=/bin/kill -s QUIT $MAINPID
        PrivateTmp=true

        [Install]
        WantedBy=multi-user.target

        ## # 重载 systemd 配置
        sudo systemctl daemon-reload

        # 启动 nginx
        sudo systemctl start nginx

        # 查看状态
        sudo systemctl status nginx

        # 设置开机自启动
        sudo systemctl enable nginx
    ```
9. 测试：
    ```sh
        # 方法1：使用 curl 测试
        curl http://localhost

        # 方法2：检查端口是否监听
        sudo netstat -tlnp | grep nginx
        # 或者
        sudo ss -tlnp | grep nginx

        # 方法3：查看进程
        ps aux | grep nginx
    ```

10. 常用命令：
    ```sh
        # 启动
        sudo systemctl start nginx

        # 停止
        sudo systemctl stop nginx

        # 重启
        sudo systemctl restart nginx

        # 重新加载配置（不中断服务）
        sudo systemctl reload nginx

        # 查看状态
        sudo systemctl status nginx

        # 查看日志
        sudo journalctl -u nginx -f

        # 测试配置文件
        sudo nginx -t
    ```