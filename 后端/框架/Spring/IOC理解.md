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

## IOC容器实现

### BeanFactory-框架基础设施

BeanFactory是Spring框架的基础设施，面向Spring本身；ApplicationContext面向使用Spring框架的开发者，几乎所有的应用场合我们都直接使用ApplicationContext而非底层的BeanFactory。

1. Bean Definition Registry注册表
   - Spring配置文件中每一个节点元素在Spring容器里都通过一个BeanDefinition对象表示，它描述了Bean的配置信息。而BeanDefinitionRegistry接口提供了向容器手工注册BeanDefinition对象的方法。

2. BeanFactory 顶层接口
   - 位于类结构树的顶端，它最主要的方法就是igetBean(String beanName)，该方法从容器中返回特定的Bean，BeanFactory的功能通过其他的接口得到不断扩展。

3. ListablebeanFactory
   - 该接口定义了访问容器中Bean基本信息的若干方法，如查看Bean的个数，获取某一类型Bean的配置名、查看容器中是否包括某一Bean等方法。

4. HierarchicalBeanFactory
   - 父子级联IOC容器的接口，子容器可以通过接口方法访问父容器。

5. ConfigurableBeanFactory
   - 是一个重要的接口，增强了IOC容器的可定制性，它定义了设置类装载器、属性编辑器、容器初始化后置处理器等方法。

6. AutowireCapableBeanFactory自动装配
   - 定义了将容貌国企中的Bean按某种规则（如按名字匹配、按类型匹配等）进行自动装配的方法；

7. SingletonBeanRegistry运行期间注册单例Bean
   - 定义了允许在运行期间向容器注册单实例Bean的方法；


