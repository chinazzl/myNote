# 问题：
 我的maven的settings.xml中配置`<localRepository>C:\Users\zl\Desktop\maven\repository</localRepository>，然后 <mirrors> <mirror> <id>maven-public</id> <mirrorOf>*</mirrorOf> <url>file:///${localRepository}</url> </mirror> </mirrors>` 在IDEA中重新同步出现Malformed \uxxx encoding. 异常如何解决？

 1. 坑1: 在localRepository标签内的本地仓库地址有误，使用反斜杠会导致编码错误
 2. 坑2：由于内网的私服有部分依赖有漏洞的原因不允许进行下载，所以项目打包的时候无法从中央仓库下载，导致项目报错。因此使用本地仓库当作镜像
    ```xml
    <mirrors>
        <mirror>
            <id>maven-public</id>
            <mirrorOf>*</mirrorOf>
            <url>file://C:/Users/zl/Desktop/maven/repository</url>
        </mirror>
    </mirrors>
    <!-- 注意的是：url中file 后面的斜杠都要用正斜杠，在网上查的都是用三个斜杠进行转义，排查了好久，其实并不需要 -->
    ```

## 整体复盘：

1. 发现项目无法启动，重新install发现maven进行解析包部分三方包在私服中由于漏洞原因限制下载导致项目无法install
2. 当时并不知情，去私服地址中重新下载settings.xml文件，并且删除了仓库中之前已经打好包的文件，修改settings.xml本地仓库地址，重新install出现 `Malformed \uxxx encoding`
3. 当时一直以为是将本地仓库设置为镜像地址的问题，一直修改`<mirror></mirror>`标签中的url，修改了大半天发现没有用
4. 删除`.idea`文件，无果。新创建一个新的工作空间发现和之前的一模一样，排查项目原因无关联。
5. 进行仔细排查发现`<localRepository>`中的地址换其他的目录的时候会正常下载包，不会报错，感觉应该是仓库的问题，上网找发现是可能是 maven元文件错误导致编码报错
6. 重新创建一个代码仓库，将之前的代码仓库进行备份，从中央仓库中下载已经存在的包，将报错缺失的包从备份仓库中进行查找覆盖
7. 打包成功后 删除新创建的工作空间释放资源，切换到原来的工作空间后进行clean然后install测试，发现还是有问题。出现`grpc-core No version available for io.grpc:grpc-core:jar:[1.50.2] whith specified range` 错误
8. 删除`.lastUpdated`文件，发现还是报错，又删除`remote和grpc的 pom`文件，点击install发现和上面的编码错误又出现了，因此把`grpc`的整个文件全部删除，在`settings.xml`文件进行修改为远程仓库。
9. 修改后使用`mvn dependency:resolve -U` 进行下载依赖包，并且重新生成元文件，执行成功！
10. 切换到IDEA，发现还是不行，灵机一动发现特么的IDEA的maven配置忘记修改了，修改成功后，项目无报错，正常启动!! 

# 撒花*★,°*:.☆(￣▽￣)/$:*.°★* 。