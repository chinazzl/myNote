好的，这是一个在Java面试中非常经典的问题。

直接给出结论：**Java 严格来说只有一种参数传递方式：值传递 (pass-by-value)。**

很多人会误以为Java是“值传递和引用传递”并存，或者认为“基本类型是值传递，对象是引用传递”。这种说法不准确，并且会引起混淆。

为了彻底理解这个问题，我们需要先明确两个概念：

1.  **值 (Value)**：
    *   对于**基本数据类型**（如 `int`, `char`, `double` 等），变量存储的就是数据**本身的值**。例如 `int x = 10;`，变量 `x` 里面存的就是 `10`。
    *   对于**对象类型**（如 `String`, `Person` 等），变量存储的是对象在内存堆（Heap）中的**引用地址 (reference)**。例如 `Person p = new Person();`，变量 `p` 里面存的不是 `Person` 对象本身，而是指向这个对象的内存地址（比如 `@123abc`）。

2.  **值传递 (Pass-by-Value)**：
    *   在方法调用时，实参（调用方）会把自己的**值的副本 (copy)** 传递给形参（方法内部）。
    *   在方法内部，对形参的任何修改，都**不会影响**到方法外部的实参。

下面我们通过两个例子来详细说明，为什么Java只有值传递。

---

### 示例1：基本数据类型的传递

这是最简单、最没有争议的情况。

```java
public class PrimitiveExample {

    public static void main(String[] args) {
        int num = 10;
        System.out.println("调用方法前, num 的值: " + num); // 输出 10
        modify(num);
        System.out.println("调用方法后, num 的值: " + num); // 输出 10
    }

    public static void modify(int value) {
        // value 是 num 的一个副本
        System.out.println("方法内部, 接收到的 value 值: " + value); // 输出 10
        value = 20; // 修改副本的值
        System.out.println("方法内部, 修改后的 value 值: " + value); // 输出 20
    }
}
```

**执行结果：**

```
调用方法前, num 的值: 10
方法内部, 接收到的 value 值: 10
方法内部, 修改后的 value 值: 20
调用方法后, num 的值: 10
```

**分析：**

1.  `main` 方法中的变量 `num` 的值为 `10`。
2.  当调用 `modify(num)` 时，Java创建了 `num` 的一个**副本**，并将这个副本（也就是 `10`）传递给了 `modify` 方法的形参 `value`。
3.  此时，`main` 方法中的 `num` 和 `modify` 方法中的 `value` 是两个完全独立的变量，它们只是恰好初始值相同。
4.  在 `modify` 方法内部，`value` 的值被修改为 `20`。这**完全不影响** `main` 方法中的 `num`。
5.  方法执行完毕后，`value` 变量被销毁。`main` 方法中的 `num` 依然是 `10`。

这清晰地展示了基本类型的值传递。

---

### 示例2：对象类型的传递（这是引起混淆的关键）

现在我们来看对象类型，很多人会在这里误认为是“引用传递”。

首先，我们定义一个简单的 `Person` 类：

```java
class Person {
    private String name;

    public Person(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

然后我们看下面的例子：

```java
public class ObjectExample {

    public static void main(String[] args) {
        Person person = new Person("张三");
        System.out.println("调用方法前, person.name 的值: " + person.getName()); // 输出 "张三"

        modify(person);

        System.out.println("调用方法后, person.name 的值: " + person.getName()); // 输出 "李四"
    }

    public static void modify(Person p) {
        // p 是 person 变量的值（引用地址）的一个副本
        p.setName("李四"); // 通过副本地址，修改了堆内存中同一个对象的状态
    }
}
```

**执行结果：**

```
调用方法前, person.name 的值: 张三
调用方法后, person.name 的值: 李四
```

**分析（为什么看起来像引用传递？）：**

1.  `main` 方法中，`Person person = new Person("张三");` 创建了一个 `Person` 对象，我们假设它在内存堆中的地址是 `@123abc`。变量 `person` 中存储的**值**就是这个地址 `@123abc`。
2.  当调用 `modify(person)` 时，Java依然遵循**值传递**。它创建了 `person` 变量的**值的副本**，也就是**地址 `@123abc` 的一个副本**，并把这个副本传递给了 `modify` 方法的形参 `p`。
3.  现在，`main` 方法中的 `person` 和 `modify` 方法中的 `p`，它们都是独立的变量，但它们存储的**值（地址）是相同的**，都指向堆内存中同一个 `Person` 对象。
4.  在 `modify` 方法内部，执行 `p.setName("李四");`。`p` 根据它存储的地址 `@123abc` 找到了堆中的 `Person` 对象，并将其 `name` 属性修改为 "李四"。
5.  由于 `main` 方法中的 `person` 变量也指向同一个对象，所以当方法调用结束后，通过 `person.getName()` 访问时，看到的就是被修改后的结果 "李四"。

**类比：** 你有一把房子的钥匙（`person`变量），你复制了一把钥匙（`p`变量）给你的朋友。你的朋友用这把复制的钥匙打开了你的房子，并把墙刷成了蓝色。当你回家时，用你自己的钥匙打开门，看到的墙就是蓝色的。钥匙是复制的（值传递），但房子是同一个。

---

### 示例3：证明它不是引用传递的“铁证”

如果Java是真正的引用传递，那么方法内部应该能够改变外部实参的指向。让我们来验证一下。

```java
public class ObjectExampleProof {

    public static void main(String[] args) {
        Person person = new Person("张三");
        System.out.println("调用方法前, person 指向的对象 name: " + person.getName()); // 输出 "张三"

        modify(person);

        System.out.println("调用方法后, person 指向的对象 name: " + person.getName()); // 仍然输出 "张三"
    }

    public static void modify(Person p) {
        // p 接收到的是 person 的引用地址的副本
        
        // 让 p 指向一个新的对象
        p = new Person("王五"); 
        
        // 这一步仅仅是改变了 p 这个副本变量的指向，
        // 它现在指向了"王五"这个新对象。
        // 原本 main 方法中的 person 变量仍然指向"张三"那个对象。
        System.out.println("方法内部, p 指向的对象 name: " + p.getName()); // 输出 "王五"
    }
}
```

**执行结果：**

```
调用方法前, person 指向的对象 name: 张三
方法内部, p 指向的对象 name: 王五
调用方法后, person 指向的对象 name: 张三
```

**分析（这是决定性的证据）：**

1.  和之前一样，`person` 和 `p` 最初都指向了 "张三" 对象。
2.  在 `modify` 方法内部，`p = new Person("王五");` 这行代码的含义是：**让 `p` 这个变量指向一个新创建的 "王五" 对象**。
3.  这**只改变了 `p` 这个副本变量的指向**，它不再指向 "张三" 对象了。但是，`main` 方法中的 `person` 变量**毫发无损**，它内部存储的地址值没有改变，依然指向最初的 "张三" 对象。
4.  如果Java是引用传递（pass-by-reference），那么在方法内对 `p` 的重新赋值应该会影响到 `person`，`main` 方法最后应该输出 "王五"。但事实并非如此。

**类比：** 你复制了一把房子钥匙给朋友（`p`）。你的朋友没有用它开你的门，而是把这把复制的钥匙扔了，然后自己去买了套新房子，并拿到了新房子的钥匙。这与你和你原来的房子毫无关系。

---

### 总结

1.  **Java 永远是值传递 (Pass-by-Value)。**
2.  当传递**基本类型**时，传递的是**值的副本**。方法内的修改不影响外部。
3.  当传递**对象类型**时，传递的是**引用地址的副本**。
    *   通过这个副本地址，可以修改**堆中同一个对象的内容（状态）**，这会让外部看到变化。
    *   但是，无法让外部的引用变量**指向一个新的对象**，因为方法内操作的只是地址的副本。

为了避免混淆，一种更精确但不官方的说法是 “**按共享传递 (call-by-sharing)**”，它强调了调用方和被调用方共享同一个对象。但从Java语言规范的定义来看，其底层机制就是值传递。