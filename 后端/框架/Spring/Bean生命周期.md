## Bean生命周期

1. Spring中的bean的生命周期主要包含四个阶段：实例化Bean --＞ Bean属性填充 --＞ 初始化Bean --＞销毁Bean

2. 首先是实例化Bean，当客户向容器请求一个尚未初始化的bean时，或初始化bean的时候需要注入另一个尚末初始化的依赖时，容器就会调用doCreateBean()方法进行实例化，实际上就是通过反射的方式创建出一个bean对象

3. Bean实例创建出来后，接着就是给这个Bean对象进行属性填充，也就是注入这个Bean依赖的其它bean对象

4. 属性填充完成后，进行初始化Bean操作，初始化阶段又可以分为几个步骤：

5. 执行Aware接口的方法

    Spring会检测该对象是否实现了xxxAware接口，通过Aware类型的接口，可以让我们拿到Spring容器的些资源。如实现
    BeanNameAware接口可以获取到BeanName，实现BeanFactoryAware接口可以获取到工厂对象BeanFactory等

6. 执行BeanPostProcessor的前置处理方法postProcessBeforelnitialization()，对Bean进行一些自定义的前置处理
判断Bean是否实现了InitializingBean接口，如果实现了，将会执行lnitializingBean的afeterPropertiesSet()初始化方法；

7. 执行用户自定义的初始化方法，如init-method等；

8. 执行BeanPostProcessor的后置处理方法postProcessAfterinitialization()

9. 初始化完成后，Bean就成功创建了，之后就可以使用这个Bean， 当Bean不再需要时，会进行销毁操作，

10. 首先判断Bean是否实现了DestructionAwareBeanPostProcessor接口，如果实现了，则会执行DestructionAwareBeanPostProcessor后置处理器的销毁回调方法
    其次会判断Bean是否实现了DisposableBean接口，如果实现了将会调用其实现的destroy()方法
11. 最后判断这个Bean是否配置了dlestroy-method等自定义的销毁方法，如果有的话，则会自动调用其配置的销毁方法；