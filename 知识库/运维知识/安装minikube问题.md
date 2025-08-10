

stderr:
Unable to find image 'gcr.io/k8s-minikube/kicbase:v0.0.47@sha256:6ed579c9292b4370177b7ef3c42cc4b4a6dcd0735a1814916cbc22c8bf38412b' locally
docker: Error response from daemon: Get "https://gcr.io/v2/": context deadline exceeded

Run 'docker run --help' for more information


❌  Exiting due to GUEST_PROVISION: error provisioning guest: Failed to start host: recreate: creating host: create: creating: setting up container node: preparing volume for minikube container: docker run --rm --name minikube-preload-sidecar --label created_by.minikube.sigs.k8s.io=true --label name.minikube.sigs.k8s.io=minikube --entrypoint /usr/bin/test -v minikube:/var gcr.io/k8s-minikube/kicbase:v0.0.47@sha256:6ed579c9292b4370177b7ef3c42cc4b4a6dcd0735a1814916cbc22c8bf38412b -d /var/lib: exit status 125
stdout:

stderr:
Unable to find image 'gcr.io/k8s-minikube/kicbase:v0.0.47@sha256:6ed579c9292b4370177b7ef3c42cc4b4a6dcd0735a1814916cbc22c8bf38412b' locally
docker: Error response from daemon: Get "https://gcr.io/v2/": context deadline exceeded

Run 'docker run --help' for more information
这个如何解决？

--- ================================================================
太棒了！我们终于走出了本地权限的“新手村”，进入了网络问题的“第二关”。这个错误你绝对不是一个人在战斗，它是国内用户使用 Kubernetes 和 Minikube 时**最常见、最经典**的问题。

恭喜你，你的本地 Docker 环境已经完全配置正确了！

### 错误信息解读

让我们像侦探一样分析这几行关键信息：

1.  `Unable to find image 'gcr.io/k8s-minikube/kicbase:...' locally`
    *   **含义**：Minikube 需要一个叫 `kicbase` 的基础镜像来创建 K8s 节点，它在你的电脑上没找到。这很正常，第一次运行时都需要下载。

2.  `docker: Error response from daemon: Get "https://gcr.io/v2/": context deadline exceeded`
    *   **含义（这是核心！）**：你的 Docker 引擎尝试去 `gcr.io`（Google Container Registry，谷歌的容器镜像仓库）下载那个镜像，但是连接超时了。`context deadline exceeded` 基本上就等于**“我试着连你，但等了半天你都没反应，我放弃了”**。

### 问题根源

**这不是你的配置错误，而是网络连接问题。**

`gcr.io` 是谷歌的服务器，在中国大陆地区由于众所周知的原因，访问极其不稳定或完全无法访问。即使你在国外，公司或学校的防火墙也可能阻止这类连接。

### 解决方案：使用国内镜像加速

解决办法非常简单：我们不直接从 `gcr.io` 下载，而是从国内云服务商提供的“镜像仓库”下载。这些镜像是官方的完美拷贝，但服务器在国内，下载速度飞快。

Minikube 已经为我们考虑到了这一点，并提供了非常方便的解决方案。

---

#### 方案一：在启动命令中临时指定镜像仓库（最推荐）

这是最快、最直接的解决方法。我们只需要在 `minikube start` 命令后面加上一个参数，告诉它去别的地方下载镜像。

1.  **先清理掉之前失败的尝试（很重要）**：
    ```bash
    # 在你的 docker 用户下执行
    minikube delete
    ```

2.  **使用国内镜像重新启动**：
    这里推荐使用阿里云的镜像仓库，它是目前最稳定和常用的。

    ```bash
    # 推荐！这个命令告诉 minikube 使用阿里云的 K8s 镜像仓库
    minikube start --image-repository=registry.aliyuncs.com/google_containers
    ```

    或者，Minikube v1.2.0 以上版本提供了一个更简单的选项：

    ```bash
    # 同样推荐！这个命令会自动为你选择中国区的镜像
    minikube start --image-mirror-country=cn
    ```

执行上述任一命令后，你会看到 `minikube` 开始从 `registry.aliyuncs.com` 拉取镜像，速度会很快，`context deadline exceeded` 错误就会消失。

---

#### 方案二：永久性配置 Minikube（一劳永逸）

如果你不想每次启动都输入长长的参数，可以把它设置为 Minikube 的默认配置。

```bash
# 执行一次这个命令，以后就不用再指定了
minikube config set image-mirror-country cn
```
或者
```bash
minikube config set image-repository registry.aliyuncs.com/google_containers
```
设置完成后，你就可以像往常一样，只用 `minikube start` 来启动了。

---

#### 方案三：为 Docker Daemon 配置全局镜像加速（更通用）

这个方案不仅能加速 Minikube，还能加速你所有 `docker pull` 的操作。它会修改 Docker 引擎的配置文件。

1.  **回到 `root` 或有 `sudo` 权限的用户**。

2.  **编辑或创建 Docker 的配置文件**：
    ```bash
    sudo vim /etc/docker/daemon.json
    ```

3.  **在文件中添加以下内容**。如果文件是空的，就完整复制粘贴；如果里面已经有内容，就在大括号 `{}` 内添加 `"registry-mirrors"` 这一项，注意逗号。

    ```json
    {
      "registry-mirrors": [
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com",
        "https://docker.m.daocloud.io"
      ],
      "exec-opts": ["native.cgroupdriver=systemd"]
    }
    ```
    *   注意：这里提供的加速器是针对 Docker Hub 的，对于 `gcr.io` 的加速，**方案一和方案二更直接有效**。但配置这个对你未来的 Docker 使用总是有好处的。

4.  **重启 Docker 服务使配置生效**：
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    ```

### 总结与操作建议

1.  先执行 `minikube delete` 清理环境。
2.  直接执行 **`minikube start --image-mirror-country=cn`**。
3.  享受成功的喜悦！


## 最后解决：
1. docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:v0.0.44
2. minikube delete ; minikube start --force  --memory=1690mb --base-image='registry.cn-hangzhou.aliyuncs.com/google_containers/kicbase:v0.0.44'
#--force是以root身份启动的docker的必须选项
#--memory=1690mb 是因为资源不足需要添加的限制性参数，可忽略
#--base-image为指定minikube start 采用的基础镜像，上面docker pull拉取了什么镜像，这里就改成什么镜像



你已经跨过了使用 Kubernetes 在国内最常见的两个障碍：本地权限和网络访问。接下来应该会一路顺畅了！