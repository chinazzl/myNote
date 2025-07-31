# Nginx 请求处理的11个阶段

1. post-read：在完成第一步读取请求行和第二步读取请求头之后就进入多处理阶段，首当其冲的就是post-read阶段。注册在post-read阶段的处理器不多，标准模块的ngx_realip处理器就注册在这个阶段。

2. server-rewrite阶段：server-rewrite阶段，简单地翻译就是server块中的请求地址重写阶段。在进行请求URI与location路由规则匹配之前可以修改请求的URI地址。

3. find-config: 紧接在server-rewrite阶段后面的是find-config阶段，也叫配置查找阶段，主要功能是根据请求URL地址去匹配location路由表达式。

4. rewrite: 由于Nginx已经在find-config阶段完成了当前请求与location的匹配，因此从rewrite阶段开始，location配置块中的指令就可以产生作用。

5. post-rewrite：请求地址URI重写提交（Post）阶段，防止递归修改URI造成死循环（一个请求执行10次就会被Nginx认定为死循环），该阶段只能由Nginx HTTP Core（ngx_http_core_module）模块实现。

6. preaccess：访问权限检查准备阶段，控制访问频率的ngx_limit_req模块和限制并发度的ngx_limit_zone模块的相关指令就注册在此阶段。

7. access：在访问权限检查阶段，配置指令多是执行访问控制类型的任务，比如检查用户的访问权限、检查用户的来源IP地址是否合法等。

8. post-access：访问权限检查提交阶段。如果请求不被允许访问Nginx服务器，该阶段负责就向用户返回错误响应。在access阶段可能存在多个访问控制模块的指令注册，post-access阶段的satisfy配置指令可以用于控制它们彼此之间的协作方式。

9.  try-files：如果HTTP请求访问静态文件资源，那么try-files配置项可以使这个请求按顺序访问多个静态文件资源，直到某个静态文件资源符合选取条件。这个阶段只有一个标准配置指令try-files，并不支持Nginx 模块注册处理程序。

10. content：大部分HTTP模块会介入内容产生阶段，是所有请求处理阶段中重要的阶段。Nginx的echo指令、第三方ngx_lua模块的content_by_lua 指令都注册在此阶段。

11. log：日志模块处理阶段记录日志。


# 总结：

（1）Nginx将一个HTTP请求分为11个处理阶段，这样做让每个HTTP模块可以只专注于完成一个独立、简单的功能。而一个请求的完整处理过程由多个HTTP模块共同合作完成，可以极大地提高多个模块合作的协同性、可测试性和可扩展性。

（2）Nginx请求处理的11个阶段中，有些阶段是必备的，有些阶段是可选的，各个阶段可以允许多个模块的指令同时注册。但是，find-config、post-rewrite、post-access、try-files四个阶段是不允许其他模块的处理指令注册的，它们仅注册了HTTP框架自身实现的几个固定的方法。

（3）同一个阶段内的指令，Nginx会按照各个指令的上下文顺序执行对应的handler处理器方法。