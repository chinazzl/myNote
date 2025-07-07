好的，在 CentOS（或类似 RHEL 的系统，如 Rocky Linux, AlmaLinux）上卸载 Redis 的方法取决于你当初的**安装方式**。主要有两种情况：

1.  **通过包管理器 `yum` 或 `dnf` 安装**
2.  **从源码编译安装**

我会分别详细介绍这两种情况的卸载步骤，并提供一个通用的“彻底清理”步骤。

---

### 如何判断你的安装方式？

在开始之前，你可以通过一个简单的命令来判断 Redis 是如何安装的。

打开终端，运行：
```bash
which redis-server
```

*   如果输出是 `/usr/bin/redis-server` 或 `/usr/sbin/redis-server`，那么它很可能是通过 `yum` / `dnf` 安装的。
*   如果输出是 `/usr/local/bin/redis-server`，那么它几乎可以肯定是**从源码编译安装**的。

---

### 场景一：卸载通过 `yum` / `dnf` 安装的 Redis

这是最简单直接的方法。

#### 第 1 步：停止并禁用 Redis 服务

在卸载软件之前，先停止正在运行的服务，并禁止它开机自启。

```bash
# 停止 Redis 服务
sudo systemctl stop redis

# 禁用 Redis 开机自启
sudo systemctl disable redis
```

#### 第 2 步：卸载 Redis 软件包

使用 `yum` (CentOS 7) 或 `dnf` (CentOS 8及更高版本) 来移除 Redis 包。

对于 CentOS 7:
```bash
sudo yum remove redis
```

对于 CentOS 8 / Stream 或更高版本:
```bash
sudo dnf remove redis
```
系统会提示你将要卸载的包和依赖，输入 `y` 确认即可。

#### 第 3 步：清理残留文件（可选，但推荐）

`yum`/`dnf` 卸载通常会保留配置文件和数据，以便你将来重新安装。如果你想彻底清除，需要手动删除它们。

**警告：执行此步会永久删除所有 Redis 数据和配置，请务必提前备份！**

```bash
# 删除配置文件目录
sudo rm -rf /etc/redis/

# 删除数据目录
sudo rm -rf /var/lib/redis/
```
默认的配置文件是 `/etc/redis.conf`，数据目录是 `/var/lib/redis`。如果你修改过，请删除对应的路径。

---

### 场景二：卸载从源码编译安装的 Redis

从源码安装的 Redis 没有自动卸载脚本，需要手动反向操作。

#### 第 1 步：停止并禁用 Redis 服务

如果你为它创建了 `systemd` 服务文件，请先停止并禁用它。

```bash
# 停止服务
sudo systemctl stop redis

# 禁用服务
sudo systemctl disable redis
```

#### 第 2 步：删除 `systemd` 服务文件

删除你之前创建的 `redis.service` 文件，并重新加载 `systemd`。

```bash
# 删除服务文件
sudo rm /etc/systemd/system/redis.service

# 重新加载 systemd 配置
sudo systemctl daemon-reload
```

#### 第 3 步：删除 Redis 可执行文件

`make install` 命令通常会将二进制文件复制到 `/usr/local/bin`。你需要手动删除它们。

```bash
sudo rm /usr/local/bin/redis-server
sudo rm /usr/local/bin/redis-cli
sudo rm /usr/local/bin/redis-benchmark
sudo rm /usr/local/bin/redis-check-aof
sudo rm /usr/local/bin/redis-check-rdb
sudo rm /usr/local/bin/redis-sentinel

# 或者更方便地使用通配符（请小心确认路径）
# sudo rm /usr/local/bin/redis-*
```

#### 第 4 步：删除配置文件、数据和日志

**警告：执行此步会永久删除所有 Redis 数据和配置，请务必提前备份！**

如果你遵循了标准的配置实践，文件通常在以下位置：

```bash
# 删除配置文件目录
sudo rm -rf /etc/redis/

# 删除数据目录
sudo rm -rf /var/lib/redis/

# 删除日志文件（如果配置了的话）
sudo rm /var/log/redis_server.log
```

#### 第 5 步：删除 Redis 用户和组（如果创建过）

为了安全，通常会为 Redis 创建一个专门的系统用户。现在可以删掉它。

```bash
# 删除 redis 用户
sudo userdel redis

# 如果 redis 组是专用的，也可以删除（通常 userdel 会处理）
# sudo groupdel redis
```

#### 第 6 步：删除源码目录

最后，删除你从 GitHub 克隆并用于编译的源码文件夹。

```bash
# 假设源码在你的主目录下
rm -rf ~/redis
```

---

### 总结

| 操作步骤 | `yum`/`dnf` 安装 | 源码编译安装 |
| :--- | :--- | :--- |
| **1. 停止服务** | `sudo systemctl stop/disable redis` | `sudo systemctl stop/disable redis` |
| **2. 卸载程序** | `sudo yum/dnf remove redis` | 手动删除 `/usr/local/bin/redis-*` 等文件 |
| **3. 删除服务文件** | (自动) | 手动删除 `/etc/systemd/system/redis.service` |
| **4. 清理数据/配置** | 手动删除 `/etc/redis`, `/var/lib/redis` | 手动删除 `/etc/redis`, `/var/lib/redis` 等 |
| **5. 清理用户** | (通常不创建) | 手动 `userdel redis` |
| **6. 清理源码** | (无) | 手动删除源码文件夹 |

无论哪种方式，**清理残留的数据和配置文件**都是一个独立且需要特别小心的步骤。请务必在操作前确认不再需要这些数据。