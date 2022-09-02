##### IOC

总：

控制反转：理论思想，原来的对象是由使用者来进行控制，有了 Spring 之后，可以把整个对象交给 spring 来帮我们进行管理。

DI：依赖注入，把对应的属性注入到具体的对象中，例如@Autowire、populateBean 完成属性值注入

容器：存储对象，使用 map 结构进行存储，在 spring 中一般存在三级缓存，singletonObject 存放完整的 bean 对象。整个 bean 的生命周期从创建到销毁的过程全部由容器来管理。

分：

1. ioc 容器要涉及到容器的创建过程(beanFactory,DefaultListableBeanFactory)，向 bean 工厂中设置一些参数（BeanPostProcessor、Aware 接口子类）等属性
2. 加载解析 Bean 对象，准备创建的 bean 对象的定义对象 BeanDefinition（xml，或者注解的解析过程）
3. BeanFactoryPostProcessor 的处理，进行扩展 BeanDefinition，例如处理占位符，placeHolderConfigSupport
4. BeanPostProcessor 的注册功能，方便后续对 Bean 对象的具体扩展功能。
5. 将 BeanDefinition 对象实例化成具体的 bean 对象。
6. bean 对象的初始化过程（填充属性 populateBean，调用 aware 子类方法，调用 BeanpostProcessor 前置处理方法，调用 init-method 方法，调用 BeanProfessor 的后置处理方法）。
7. 生成完整的 bean 对象，通过 getBean 方法可以直接获取。
8. 销毁


