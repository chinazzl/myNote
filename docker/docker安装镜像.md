
docker:
安装docker：curl -sSL https://get.daocloud.io/docker | sh

提示docker没有启动：
systemctl daemon-reload
systemctl restart docker.service

一键启动所有docker 容器：docker start $(docker ps -a | awk '{ print $1}' | tail -n +2)

一键关闭所有docker 容器：docker stop $(docker ps -a | awk '{ print $1}' | tail -n +2)

一键删除所有docker 容器：docker rm $(docker ps -a | awk '{ print $1}' | tail -n +2)

一键删除所有docker 镜像: docker rmi $(docker images | awk '{print $3}' |tail -n +2)


docker 安装软件：
1. docker下载镜像
2. linux进行端口向外映射，firewall -query-port=xxx/tcp
3. 宿主机设置，docker 容器内部端口映射到外部宿主机的端口
	ROUTE -p add 172.17.0.0 mask 255.255.0.0 192.168.226.134
4. 正常运行docker 镜像生成docker容器。

## redis
docker run -p 6379:6379 --name redis-main -v /home/redis/redis-main/data/redis.conf:/etc/redis/redis.conf  \
-v /home/redis/redis-main/data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes


sudo docker run -p 6379:6379 --name redis -v /root/redis/redis.conf:/etc/redis/redis.conf  -v /root/redis/data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes

## sentinel
docker cp /usr/share/zoneinfo/Asia/Shanghai sentinel:/usr/share/zoneinfo/Asia/Shanghai

docker exec -it sentinel sh -c  'ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime'




java  '-Dserver.port=8858' '-Dcsp.sentinel.dashboard.server=localhost:8858' '-Dproject.name=sentinel-dashboard'  -jar sentinel-dashboard.jar


## nancos
docker run -d -p 8848:8848 -e MODE=standalone -e PREFER_HOST_MODE=hostname -v /root/nacos/init.d/custom.properties:/home/nacos/init.d/custom.properties -v /root/nacos/logs:/home/nacos/logs --env NACOS_AUTH_ENABLE=true --env NACOS_AUTH_TOKEN=17987070c6f2bd94b4a67d4d4df850eb875ae59131b055497b8a81e046edd9e1 --env NACOS_AUTH_IDENTITY_KEY=xxx --env NACOS_AUTH_IDENTITY_VALUE=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjpbeyJ4eHgiOiJoaGgifV0sImlhdCI6MTY4MDI1MzczMCwiZXhwIjoxNzc0ODg2Mzk5LCJhdWQiOiIiLCJpc3MiOiIiLCJzdWIiOiIifQ.k7c3PIQqrNpjHxp3-ZkoHfyBd6IofafdSlr4qcYHJ7w --restart always --name nacos nacos/nacos-server

## rabbitmq
docker run -d -p 5672:5672 -p 15672:15672 --name rabbitmq rabbitmq:management


## MYSQL
docker run -it -d --name mysql --net=host -m 500m -v /root/mysql/data:/var/lib/mysql -v /root/mysql/config:/etc/mysql/conf.d  -e MYSQL_ROOT_PASSWORD=passwd -e TZ=Asia/Shanghai mysql --lower_case_table_names=1


http://localhost:7001/kie-drools-wb/maven2wb/com/testdemo/StudentProject/1.0.0/StudentProject-1.0.0.jar


export JAVA_HOME =/usr/jdk/jdk-1.8.0_321
export PATH=$PATH:$JAVA_HOME/bin

# 开启linux子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
#开启虚拟机平台
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

以管理员身份运行windows terminal
输入netsh winsock reset
重新打开windows terminal


