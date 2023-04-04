# RabbitMQ

> RabbitMQ是一款开源的，Erlang编写的，基于AMQP协议的消息中间件。

## 使用场景

1. 服务间异步通信 

2. 顺序消费

3. 定时任务

4. 请求削峰

## 基本概念

- Broker：消息队列的服务器实体

- Exchange：消息交换机，它指的是按什么规则，路由到哪个队列

- Queue：消息队列载体，每个消息都会被投入到一个或多个队列

- Binding：绑定，它的作用是吧exchange和queue按照路由规则（`接收什么样子的数据`）绑定起来

- RoutingKey：路由关键字，exchange根据这个关键字进行消息投递

- producer：消息生产者，就是投递消息的程序

- Consumer：消息消费者，就是接受消息的程序

- Channel：消息通道，在客户端的每个连接里，可建立多个channel，每个channel代表一个会话任务。

## RabbitMQ的工作模式：

1. simple模式（简单的收发模式）

2. work工作模式（资源竞争）

3. publish/subcribe发布订阅（共享资源模式）
   
   - 每个消费者监听自己的队列
   
   - 生产者将消息发给broker，由交换机将消息转发到绑定此交换机的每个队列，每个绑定交换机的队列都将接收到消息。