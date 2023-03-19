# AOP实现原理
> “横切”的技术，剖开封装的内部对象，并将那些影响了多个类的公共行为封装到一个可重用模块

## 主要应用场景

1. Authentication 权限
2. Caching 缓存
3. Context passing 内容传递
4. Error handling 错误处理
5. Lazy loading 懒加载
6. Debugging 调试
7. loggin tracing 记录跟踪、优化、校准
8. performance optimization 性能优化
9. Persistence 持久化
10. Resource pooling 资源池
11. Synchronization 同步
12. transaction 事务

## AOP核心概念

1. 切面（aspect）：类是对物体特征的抽象，切面就是idui横切关注点的抽象
2. 横切关注点：对哪些方法进行拦截，蓝结构怎么处理，这些关注点称之为横切关注点
3. 连接点（joinpoint）：被拦截到的点，因为Spring只支持方法类型的连接点，所以在Spring中连接点值得就是被拦截到的方法，实际上连接点还可以是字段或者构造器
4. 切入点（pointcut）：对联节点进行拦截的定义
5. 通知（advice）：所谓通知指的就是指拦截到连接点之后要执行的代码，通知分为前置、后置、最终、异常、环绕
6. 目标对象：代理的目标对象
7. 织入（weave）：将切面应用到目标对象并导致代理对象创建的过程
8. 引入（introduction）：在不修改代码的前提下，引入可以在运行期为类动态地太你家一些方法或字段。

## 实现技术
> AOP（这里AOP指的是面向切面编程思想，而不是Spring AOP）主要的实现技术主要有 Spring AOP和AspectJ

1. Aspect的底层技术。 Aspec的底层技术是静态代理，即用一种AspectJ支持的特定语言编写切面，通过一个命令来编译，生成一个新的代理类，该代理类增强了业务类，这是在编译时曾强，相对于下面说的运行时曾强，编译增强的性能更好。
2. Spring AOP：Spring AOP采用的时动态代理，在运行期间对业务方法进行增强，所以不会生成新的类，对于动态代理技术，Spring AOP提供了对JDK动态代理的支持以及CGLib 的支持。
   1. JDK动态代理只能为接口创建动态代理实例，而不能对类创建动态代理。需要获得被目标类的接口信息（应用Java的反射技术），生成一个实现了代理接口的动态代理类（字节码），再通过反射机制获得动态代理类的构造函数，利用构造函数生成动态代理类的实例对象，在调用具体方法前调用InvocationHandler方法来处理。
   2. CGLib动态代理需要依赖asm包，把被代理对象类Class文件加载进来，修改其字节码生成子类，但是Spring AOP基于注解配置的情况下，需要依赖于AspectJ包的标准注解。