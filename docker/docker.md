# Docker

## Docker File

- Dockerfile是要给文本文件，其内包含了一条条的指令，每一条指令构建一层，因此每一条指令的内容，就是描述该层如何构建。

- 包含若干指令的文本文件，可以通过这些指令创建出docker image

- dockerfile文件中的指令 执行后，会创建一个个新的镜像层

- dockerfile文件中的注释以`#`开始

- Dockerfile一般由四部分组成：
  
  - 基础镜像信息
  
  - 维护者信息
  
  - 镜像操作指令
  
  - 容器启动指令

- build context：为镜像后见提供所需的文件或目录。

## Docker 容器生命周期

1. 查看Docker服务状态

```shell
# 查看Docker engine状态 查看docker服务是否正常
systemctl status docker.service
# 2. 运行一个容器
# -d 参数可在后台运行； -p 参数将宿主机8080端口映射到容器80端口
docker run -d -p 8080:80 httpd
# 查看镜像
docker images
# 查看容器运行状态
docker ps 或者 docker container ls
```

2. 容器生命周期管理

```shell
# 停止一个容器
docker stop containerID
# 查看所有状态的容器
docker ps -a 
# 启动一个容器
docker start 'space name'
# 暂停一个容器
docker pause containerID
# 恢复一个容器
docker unpause containerID
# 删除一个容器
docker rm containerID
# 一次性删除指定多个容器，如果希望批量删除所有已经退出的容器
docker rm -v ${dockersps -aq -f status=exited}
```

3. 进入一个容器

```shell
# 使用docker attach进入一个容器，不会打开新的终端，不启动新的进程
docker attach containerID
# 使用exec，会打开新的终端
docker exec -it containerID bash
sps -aq -f status=exited}
进入一个容器

# 使用docker attach进入一个容器，不会打开新的终端，不启动新的进程
docker attach containerID
# 使用exec，会打开新的终端
docker exec -it containerID bash
```

4. 其他常见命令

```shell
# 获取容器/镜像的元数据
docker inspect
# 查看容器中运行的进程信息
docker top mysql
# 从服务器获取实时事件
docker event --since = '13434234'
# 列出指定容器的端口映射
docker port mysql
# 与主机之间进行数据拷贝
docker cp containerID:/tmp/ks-script /root
```


