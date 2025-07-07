好的，从 GitHub 下载并编译安装 Redis 到 Ubuntu 是一个非常常见的操作，特别是当你需要最新版本或者特定功能时。这种方式比使用 `apt` 包管理器安装提供了更大的灵活性。

下面是详细的步骤指南，我会将过程分解为几个关键部分：**准备、下载、编译、配置和运行**。

---

### 第 1 步：准备工作 - 安装编译工具和依赖

在编译源码之前，你需要确保系统已经安装了必要的工具，如 `make`、`gcc` 编译器等。

打开你的终端，然后运行以下命令来更新包列表并安装 `build-essential`（一个包含所有编译所需工具的元数据包）、`tcl`（用于运行 Redis 测试套件）和 `git`（用于从 GitHub 下载源码）。

```bash
# 更新软件包列表
sudo apt update

# 安装编译工具、tcl 和 git
sudo apt install -y build-essential tcl git
```

### 第 2 步：从 GitHub 下载 Redis 源码

现在，使用 `git` 从 Redis 的官方 GitHub 仓库克隆源码。建议将其克隆到你的用户主目录或者一个专门存放源码的目录（如 `/usr/local/src`）。这里我们以用户主目录为例。

```bash
# 进入你的主目录
cd ~

# 克隆 Redis 仓库
git clone https://github.com/redis/redis.git

# 进入 redis 目录
cd redis
```

**可选操作：切换到指定版本**
如果你不想用最新的开发版，可以切换到一个稳定的发行版（tag）。你可以先查看所有可用的 tag：

```bash
git tag
```

然后切换到你想要的版本，例如 `7.2.4`：

```bash
git checkout 7.2.4
```

### 第 3 步：编译和测试 Redis

在源码目录中，现在可以开始编译了。

1.  **编译源码**
    运行 `make` 命令。这个过程会利用你之前安装的 `build-essential` 工具将 `.c` 源码文件编译成可执行的二进制文件。

    ```bash
    make
    ```

2.  **（强烈推荐）运行测试**
    编译完成后，运行测试套件以确保在你当前的系统环境下，编译出的版本是稳定和正确的。

    ```bash
    make test
    ```
    如果所有测试都通过，你会看到 `\o/ All tests passed without errors!` 的提示。

### 第 4 步：安装 Redis

编译成功后，`src` 目录下会生成 `redis-server`、`redis-cli` 等可执行文件。`make install` 命令会将这些文件复制到系统的标准路径下（默认为 `/usr/local/bin`），以便你可以从任何地方直接调用它们。

```bash
sudo make install
```

执行后，以下几个关键程序会被安装：
*   `redis-server`: Redis 服务器
*   `redis-cli`: Redis 命令行客户端
*   `redis-benchmark`: Redis 性能测试工具
*   `redis-check-aof`: AOF 文件修复工具
*   `redis-check-rdb`: RDB 文件检查工具

你可以通过运行以下命令来验证是否安装成功：
```bash
redis-server --version
redis-cli --version
```

### 第 5 步：配置 Redis 以实现后台运行

仅仅安装好二进制文件还不够，为了在生产环境中稳定运行，我们需要进行一些标准化的配置。

1.  **创建配置和数据目录**
    我们将配置文件统一放在 `/etc/redis`，数据文件放在 `/var/lib/redis`。

    ```bash
    sudo mkdir /etc/redis
    sudo mkdir /var/lib/redis
    ```

2.  **复制配置文件**
    从源码目录中复制一份默认的配置文件模板到我们刚创建的目录。

    ```bash
    # 确保你还在 redis 源码目录中
    sudo cp redis.conf /etc/redis/
    ```

3.  **编辑配置文件**
    这是最关键的一步。你需要修改配置文件，让 Redis 以守护进程（后台）模式运行，并指定日志和数据文件的位置。

    使用你喜欢的编辑器（如 `nano` 或 `vim`）打开配置文件：
    ```bash
    sudo nano /etc/redis/redis.conf
    ```

    找到并修改以下几项：
    *   **以守护进程模式运行**：
        将 `daemonize no` 修改为 `daemonize yes`。

    *   **指定 PID 文件**（进程ID文件）：
        `pidfile /var/run/redis_6379.pid` （这是默认值，通常不需要修改，但要确保 `/var/run` 目录可写）。

    *   **指定日志文件**：
        `logfile /var/log/redis_server.log` (你可以自定义路径)。

    *   **指定数据目录**：
        将 `dir ./` 修改为 `dir /var/lib/redis`。

    *   **（推荐）与 Systemd 协同工作**：
        将 `supervised no` 修改为 `supervised systemd`。这有助于 systemd 更好地管理 Redis 进程。

    保存并关闭文件 (在 `nano` 中是 `Ctrl+X`，然后按 `Y`，再按 `Enter`)。

### 第 6 步：创建 Systemd 服务文件

为了让 Redis 能够开机自启，并使用 `systemctl` 命令来管理（启动、停止、查看状态），我们需要创建一个 systemd 服务文件。

1.  **创建服务文件**

    ```bash
    sudo nano /etc/systemd/system/redis.service
    ```

2.  **粘贴以下内容**
    将下面的配置内容复制并粘贴到文件中。

    ```ini
    [Unit]
    Description=Redis In-Memory Data Store
    After=network.target

    [Service]
    User=redis
    Group=redis
    ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
    ExecStop=/usr/local/bin/redis-cli -p 6379 shutdown
    Restart=always

    [Install]
    WantedBy=multi-user.target
    ```

    **注意**：上面的配置假设 Redis 将以 `redis` 用户运行。这是一个安全最佳实践。我们需要创建这个用户。

3.  **创建 redis 用户和组**

    ```bash
    sudo adduser --system --group --no-create-home redis
    ```

4.  **设置目录权限**
    将我们之前创建的目录所有权交给 `redis` 用户。

    ```bash
    sudo chown redis:redis /var/lib/redis
    sudo chown redis:redis /etc/redis/redis.conf
    ```

### 第 7 步：启动并测试 Redis

现在所有准备工作都已完成，可以启动 Redis 服务了。

1.  **重新加载 systemd 配置**

    ```bash
    sudo systemctl daemon-reload
    ```

2.  **启动 Redis 服务**

    ```bash
    sudo systemctl start redis
    ```

3.  **验证服务状态**

    ```bash
    sudo systemctl status redis
    ```
    如果一切正常，你会看到 `active (running)` 的绿色提示。

4.  **设置开机自启**

    ```bash
    sudo systemctl enable redis
    ```

5.  **最终测试**
    使用 `redis-cli` 连接到服务器并发送一个 `ping` 命令。

    ```bash
    redis-cli
    ```
    进入客户端后，输入：
    ```
    ping
    ```
    如果服务器返回 `PONG`，恭喜你，Redis 已经成功安装并正在运行！

---

### 总结

至此，你已经成功地从 GitHub 源码在 Ubuntu 上编译、安装、配置并启动了 Redis。这种方法虽然步骤比 `apt install` 多，但能让你完全控制 Redis 的版本和配置，是更专业和灵活的方式。