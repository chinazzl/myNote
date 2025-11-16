# Node_export

Node Exporter是用来监控Linux服务器硬件和操作系统指标的，是Prometheus生态中最常用的exporter。我教你标准安装方法。

## 一、下载Node Exporter

```bash
# 1. 进入临时目录
cd /tmp

# 2. 下载最新版本（检查最新版本：https://github.com/prometheus/node_exporter/releases）
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz

# 3. 解压
tar -xzf node_exporter-1.8.2.linux-amd64.tar.gz

# 4. 移动到标准目录
sudo mv node_exporter-1.8.2.linux-amd64 /opt/node_exporter-1.8.2
```

## 二、创建软链接

```bash
# 创建版本软链接
sudo ln -s /opt/node_exporter-1.8.2 /opt/node_exporter

# 创建可执行文件链接
sudo ln -s /opt/node_exporter/node_exporter /usr/local/bin/node_exporter
```

## 三、创建系统用户

```bash
# 创建node_exporter专用用户
sudo useradd --no-create-home --shell /bin/false node_exporter

# 修改所有权
sudo chown -R node_exporter:node_exporter /opt/node_exporter-1.8.2
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

## 四、创建systemd服务

```bash
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

## 五、启动服务

```bash
# 重新加载systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start node_exporter

# 设置开机自启
sudo systemctl enable node_exporter

# 查看状态
sudo systemctl status node_exporter
```

## 六、验证是否成功

```bash
# 检查端口
ss -tlnp | grep 9100

# 测试访问指标
curl http://localhost:9100/metrics

# 应该看到大量指标输出，类似：
# node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67
# node_memory_MemTotal_bytes 8589934592
# ...
```

## 七、配置Prometheus采集Node Exporter

编辑Prometheus配置文件：

```bash
sudo vim /etc/prometheus/prometheus.yml
```

添加Node Exporter作为监控目标：

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:29091']

  # 添加这部分：监控本机
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'my-server'
```

重新加载Prometheus配置：

```bash
# 因为你启用了 --web.enable-lifecycle，可以热重载
curl -X POST http://localhost:29091/-/reload

# 或者重启服务
sudo systemctl restart prometheus
```

## 八、在Prometheus Web界面验证

1. 打开浏览器访问：`http://你的服务器IP:29091`

2. 点击顶部菜单 **Status** → **Targets**

3. 应该看到两个target：
   - `prometheus` (端口29091) - UP
   - `node` (端口9100) - UP

4. 点击顶部菜单 **Graph**，输入查询：
   ```
   node_cpu_seconds_total
   ```
   应该能看到CPU相关的指标

## 九、常用的Node Exporter指标

试试这些查询：

```promql
# CPU使用率
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 内存使用率
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# 磁盘使用率
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# 网络流量
irate(node_network_receive_bytes_total[5m])
```

## 十、云服务器安全组设置

记得在云服务器控制台开放端口：
- **29091**：Prometheus Web界面
- **9100**：Node Exporter指标接口（可选，如果只给Prometheus用，不需要外网访问）

---

## 完整的目录结构

安装完成后，你的目录应该是这样：

```
/opt/
├── prometheus -> prometheus-3.7.3
├── prometheus-3.7.3/
├── node_exporter -> node_exporter-1.8.2
└── node_exporter-1.8.2/

/usr/local/bin/
├── prometheus -> /opt/prometheus/prometheus
└── node_exporter -> /opt/node_exporter/node_exporter

/etc/systemd/system/
├── prometheus.service
└── node_exporter.service

/etc/prometheus/
└── prometheus.yml
```

## 常用管理命令

```bash
# 查看Node Exporter状态
sudo systemctl status node_exporter

# 查看日志
sudo journalctl -u node_exporter -f

# 重启
sudo systemctl restart node_exporter

# 停止
sudo systemctl stop node_exporter
```