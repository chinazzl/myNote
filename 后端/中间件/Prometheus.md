# Promethus 学习

## 是否能在yml中配置端口服务？
不能，Prometheus的配置文件 `prometheus.yml` **只负责配置监控目标和规则**，不能配置Web服务的端口。

## 为什么不在yml里配置端口？

Prometheus的设计理念是：
- **prometheus.yml**：配置"监控什么"（targets、rules、alerting等）
- **命令行参数**：配置"Prometheus自己怎么运行"（端口、存储路径、日志等）

这种分离设计是为了：
1. 配置文件可以热重载（`kill -HUP` 或 API重载），但端口这种需要重启才能生效
2. 运维参数和业务配置分开管理更清晰

## 云服务器部署的推荐做法

既然你部署在云服务器，我建议用 **systemd** 来管理，这样方便：

### 1. 创建systemd服务文件

```bash
sudo vim /etc/systemd/system/prometheus.service
```

写入以下内容：

```ini
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=prometheus
# 这里指定端口和其他参数
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.listen-address=":9091" \
  --web.enable-lifecycle

Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 2. 创建prometheus用户（如果还没有）

```bash
sudo useradd --no-create-home --shell /bin/false prometheus
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

### 3. 启动服务

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus  # 开机自启
sudo systemctl status prometheus  # 查看状态
```

### 4. 云服务器安全组记得开放端口

如果你用阿里云/腾讯云/AWS等：
- 去控制台的**安全组规则**
- 添加入站规则：允许TCP 9091端口

## 其他有用的命令行参数

既然用systemd，可以一次性配好这些参数：

```ini
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.listen-address=":9091" \
  --web.enable-lifecycle \           # 允许通过API重载配置
  --web.enable-admin-api \           # 启用管理API
  --storage.tsdb.retention.time=15d  # 数据保留15天
```

## 快速验证

```bash
# 查看端口是否监听
ss -tlnp | grep 9091

# 测试访问
curl http://localhost:9091/metrics

# 查看日志
sudo journalctl -u prometheus -f
```
