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

```shell
# dockerfile 构建容器镜像touch dockerfile
touch /root/dockerfile

# 编辑dockerfile
FROM centos:centos7
MAINTAINER Iris@huawei.com
ENV HOSTNAME webserver
EXPOSE 80
RUN yum install -y httpd vi && yum clean all
VIOLUME ["/var/www/html"]
CMD["/usr/sbin/httpd","D","FOREGROUND"]


# docker build 命令构建容器镜像
docker build -t httpd-centos -f dockerfile /root
```

- 搭建私有镜像仓库

```shell
# 运行私有镜像仓库registry容器
docker run -d -p 5000:5000 registry

# 例子：修改一个镜像名称
docker tag httpd-centos localhost:5000/http:V1
# 将本地镜像上传至私有镜像仓库
docker push localhost:5000/http:V1
# 查看私有镜像仓库registry镜像信息
# 列出所有的本地registry仓库镜像
curl -X GET http://localhost:5000/v2/_catalog
curl -X GET http://localhost:5000/v2/tags/list

# 从私有镜像下载 需要提前删除对应容器
docker rmi localhost:5000/http:V1
docker pull localhost:5000/http:V1
```

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

# docker cp 实现宿主机与容器之间的文件拷贝
touch ~/1.txt
docker cp ~/1.txt containerID:/home

# 容器资源限额
docker run -it -m 200M progrium/stress --vm 1 --vm-bytes 150M

# 与主机之间进行数据拷贝
#   运行一个压力测试容器，实现容器内存分配限额
docker cp containerID:/tmp/ks-script /root
#   运行一个压力测试容器，实践容器内存和swap分配限额
docker run -it 300M --memory-swap=400M progrium/stress --vm 2 --vm-bytes 100M
#   运行一个压力测试容器，时间容器CPU使用限额
docker run -it --cpus=0.6 progrium/stress --vm 1
#   实践容器cpu权重限额
docker run -itd --cpu-shares 2048 progrium/stress --cpu 1
docker run -itd --cpu-shares 1024 progrium/stress --cpu 1
docker run -itd --cpu-shares 512 progrium/stress --cpu 1
#   实践IO限额
docker run -it --device-write-bps /dev/vda:50MB centos
#     利用dd命令测试磁盘的写能力
time dd if=/dev/zero of =test.out bs=1M count=200 oflag=direct
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
```

5. Cgroup

6. NameSpace

```shell
# 分别在容器和宿主机验证主机名，为centos 设置主机名
docker run -d -t -h container centos
```

## 容器网格

1. 容器网格模型

```shell
# 设置network和宿主机试一个ip
docker run -itd --network=host centos
# 配置其网络模型为bridge并验证
docker run -itd --network=brige centos
```

2. Docker bridge网格

```shell
# 创建用户自动逸桥并指定子网和网关
docker network create --driver bridge --subnet 173.18.0.0/16 --gateway 173.18.0.1 servicebridge01
docker network inspect 网络ID
# 运行容器并挂载到第一步的自定义网桥
docker run -itd --network=servicebridge01 centos
# 运行一个容器挂在在默认docker0网桥，再挂在到第一步的自定义网桥
docker run -itd centos
docker network connect 网络ID 容器ID
# 验证
docker exec -it 容器ID bash
> ip addr
```

## 容器存储

1. bind mount

```shell
# 运行容器将宿主机的目录挂载到容器
mkdir -p /home/container/htdocs
cd /home/container/htdocs
docker run -d -p 80:80 -v /home/container/htdocs:/usr/local/apache2/htdocs/ httpd
# 验证
docker inspect 容器ID
# 宿主机目录内更新文件，验证容器内读取
cd /home/container/htdocs
echo "this is page from host directory." > index.html
cat index.html
# 验证容器持久化
docker exec -it containerID sh
> ls
> cd htdocs
# this is page from host directory.
> cat index.html

docker rm containerID -f
cd /home/container/htdocs
# this is page from host directory.
> index.html
```

2. Docker managed volume

```shell
# docker managed volume 挂载到容器
docker run -d -p 80:80 -v /usr/local/apache2/htdocs/ httpd
# docker 获取挂载点
docker inspect containerID
# mount:"Source": "/var/lib/docker/volumes/2395d3746b2e895425f815088e91e7b4d1b10a50005f93b44f8fc67acc1ccb75/_data"
# 执行container
docker exec -it containerID bash
> cd htdocs
> echo "this is page from docker managed volume." > index.html
curl localhost:80

# 验证
docker rm containerID -f 
cd 上面的路径
cat index.html
```

3. volume container
   
   创建预备volume container。
   
   说明：volume container可以给其他容器提供bind mount或docker managed volume。volume container不需要处于运行状态，创建出来即可.

```shell
# 在宿主机创建路径和文件，作为bind mount 的源路径
mkdir -p /home/vccontainer/htdocs
cd /home/vccontainer/htdocs
echo " this is page from vccontainer. " > index.html
cat index.html
# 创建volume container
docker create --name vccontainer -v /home/vccontainer/htdocs:/usr/local/apache2/htdocs -v /other/tools/ busybox
# 运行容器，使用上一步volume container提供的卷
docker run -td -p 80:80 --volumes-from vccontainer busybox
docker inspect 容器ID

# 验证容器内路径和宿主机路径信息
docker exec -it 容器ID sh
# 在容器内 docker manage volume挂载路径创建文件，验证宿主机路径信息
cd /other/tools
echo “this is page from container.”> test.out
exit

# 通过第一步中获取的“source” 信息或docker inspect命令获取宿主机挂载源路径。
cd 挂载源路径
cat test.out
```

4. 容器监控和日志管理
   
   1. 容器原生监控管理
   
   ```shell
   # 使用docker ps命令查询正在运行的容器，并选择任意一个容器使用top命令查询容器内进程信息
   docker ps
   docker top containerID 
   # 查询容器资源状态，
   docker stats
   # 如果要专注于某个特定容器，则使用docker stats 容器ID
   docker stats 容器ID
   ```
   
   2. 容器原生日志管理
   
   ```shell
   # 查询容器日志system journal
   journalctl -b CONTAINER_NAME=任意容器名
   # 查询容器日志 docker logs
   docker logs 任意容器ID
   # 查询docker 服务日志
   journalctl -u docker.service
   
   ```
