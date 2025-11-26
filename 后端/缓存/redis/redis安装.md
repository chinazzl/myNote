在云服务器上配置 Redis，需要特别注意**安全性**和**网络访问**。以下是完整的配置方案：

## 一、找到配置文件

```bash
# Redis 配置文件位置
sudo nano /etc/redis/redis.conf

# 或者
sudo vim /etc/redis/redis.conf
```

## 二、关键配置项（安全配置）

### 1. 网络绑定配置

```conf
# 【重要】允许外网访问
# 默认只监听 127.0.0.1，需要改为 0.0.0.0 或具体内网IP
bind 0.0.0.0

# 或者绑定到内网IP（更安全）
# bind 10.0.0.5 127.0.0.1

# 端口（默认 6379，建议修改为非标准端口）
port 6379
# port 16379  # 修改端口可以减少扫描攻击
```

### 2. 保护模式（必须关闭或设置密码）

```conf
# 关闭保护模式（不推荐，除非你设置了密码）
protected-mode no

# 或者保持开启，但必须设置密码
protected-mode yes
```

### 3. 设置强密码（强烈推荐）

```conf
# 设置访问密码（必须配置！）
requirepass YourStrongPassword123!@#

# 如果有主从复制，从节点连接主节点的密码
# masterauth YourStrongPassword123!@#
```

### 4. 后台运行

```conf
# 以守护进程方式运行
daemonize yes

# 如果使用 systemd 管理，设置为 no
# daemonize no

# PID 文件位置
pidfile /var/run/redis/redis-server.pid
```

### 5. 日志配置

```conf
# 日志级别：debug, verbose, notice, warning
loglevel notice

# 日志文件位置
logfile /var/log/redis/redis-server.log
```

### 6. 持久化配置

```conf
# RDB 持久化（快照）
save 900 1      # 900秒内至少1个key变化就保存
save 300 10     # 300秒内至少10个key变化就保存
save 60 10000   # 60秒内至少10000个key变化就保存

# RDB 文件名
dbfilename dump.rdb

# 数据目录
dir /var/lib/redis

# AOF 持久化（更安全，推荐开启）
appendonly yes
appendfilename "appendonly.aof"

# AOF 同步策略
# always: 每次写操作都同步（最安全，性能最差）
# everysec: 每秒同步一次（推荐）
# no: 由操作系统决定
appendfsync everysec
```

### 7. 最大内存限制

```conf
# 最大内存限制（根据服务器配置调整）
maxmemory 2gb

# 内存淘汰策略
# noeviction: 不淘汰，内存满了返回错误
# allkeys-lru: 所有key中淘汰最少使用的
# volatile-lru: 只在设置了过期时间的key中淘汰
maxmemory-policy allkeys-lru
```

### 8. 危险命令重命名（安全加固）

```conf
# 禁用或重命名危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_abc123xyz"
rename-command KEYS ""

# 完全禁用命令就设置为空字符串 ""
# 重命名就改成复杂的名字
```

## 三、完整的安全配置示例

```conf
# ========== 网络配置 ==========
bind 0.0.0.0
protected-mode yes
port 6379

# ========== 安全配置 ==========
requirepass YourVeryStrongPassword!@#2024

# ========== 通用配置 ==========
daemonize yes
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log

# ========== 持久化配置 ==========
dir /var/lib/redis
dbfilename dump.rdb
save 900 1
save 300 10
save 60 10000

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

# ========== 内存配置 ==========
maxmemory 2gb
maxmemory-policy allkeys-lru

# ========== 安全加固 ==========
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "MY_CONFIG_CMD_2024"
rename-command KEYS ""

# ========== 性能优化 ==========
tcp-backlog 511
timeout 300
tcp-keepalive 300
```

## 四、云服务器安全组/防火墙配置

### 1. 云服务器安全组规则（阿里云/腾讯云/AWS）

**在云控制台配置：**

- **入方向规则**：
  - 协议：TCP
  - 端口：6379（或你修改后的端口）
  - 源地址：**只允许你信任的IP访问**
    - 推荐：`你的办公网IP/32`
    - 或应用服务器IP
    - ❌ 不要设置为 `0.0.0.0/0`（全网开放非常危险）

### 2. 服务器防火墙配置（UFW）

```bash
# 启用防火墙
sudo ufw enable

# 允许 SSH（先设置这个，否则会断开连接）
sudo ufw allow 22/tcp

# 只允许特定IP访问 Redis
sudo ufw allow from 你的IP地址 to any port 6379

# 或者允许内网访问
sudo ufw allow from 10.0.0.0/8 to any port 6379

# 查看规则
sudo ufw status
```

## 五、重启 Redis 并测试

```bash
# 重启 Redis
sudo systemctl restart redis-server

# 查看状态
sudo systemctl status redis-server

# 查看端口监听
sudo netstat -tlnp | grep redis
# 或
sudo ss -tlnp | grep redis

# 查看日志
sudo tail -f /var/log/redis/redis-server.log
```

## 六、测试连接

### 本地测试

```bash
# 不带密码连接（会失败）
redis-cli

# 带密码连接
redis-cli -a YourStrongPassword123!@#

# 或者先连接再认证
redis-cli
127.0.0.1:6379> AUTH YourStrongPassword123!@#
127.0.0.1:6379> PING
PONG
```

### 远程测试

```bash
# 从本地连接云服务器
redis-cli -h 你的云服务器公网IP -p 6379 -a YourStrongPassword123!@#

# 测试命令
PING
SET test "hello"
GET test
```

## 七、安全检查清单

- ✅ **必须设置强密码** `requirepass`
- ✅ **不要使用默认端口** 6379（改成其他端口）
- ✅ **绑定到内网IP** 或使用防火墙限制访问
- ✅ **禁用危险命令** FLUSHDB, FLUSHALL, CONFIG, KEYS
- ✅ **开启 AOF 持久化**
- ✅ **设置最大内存限制**
- ✅ **云安全组只允许可信IP访问**
- ✅ **定期备份数据**
- ✅ **监控 Redis 日志**

## 八、NAT 转发场景（如果需要）

如果你的云服务器在内网，通过 NAT 转发：

```bash
# 云服务器内网配置
bind 10.0.0.5  # 绑定内网IP
port 6379

# 在 NAT 网关配置端口转发
# 公网IP:6379 -> 10.0.0.5:6379
```

客户端连接时使用**公网IP**，NAT会自动转发到内网Redis。

---

**关键提醒**：
1. **一定要设置密码**，否则会被扫描攻击
2. **不要把 Redis 直接暴露在公网**，最好通过VPN或跳板机访问
3. **定期更新** Redis 版本修复安全漏洞