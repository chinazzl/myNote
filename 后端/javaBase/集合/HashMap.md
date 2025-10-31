好的，我来详细给你解释HashMap的原理和put操作的完整流程。

## 一、HashMap的底层数据结构

HashMap在JDK 8+中采用 **数组 + 链表 + 红黑树** 的组合结构：

```
HashMap内部结构示意图：

table数组（桶数组）
+---+
| 0 | → null
+---+
| 1 | → Node(key1, value1) → Node(key2, value2) → null  (链表)
+---+
| 2 | → TreeNode(红黑树根节点)                        (红黑树)
+---+
| 3 | → Node(key3, value3) → null
+---+
...
+---+
|15 | → null
+---+
```

### 核心组成部分：

1. **Node数组（table）**：存储桶的数组，每个数组元素是一个桶
2. **Node节点**：单向链表节点，包含 key、value、hash、next
3. **TreeNode节点**：红黑树节点，当链表过长时转换

## 二、HashMap的关键参数

```java
// 重要的成员变量
transient Node<K,V>[] table;        // 桶数组
transient int size;                  // 实际存储的键值对数量
int threshold;                       // 扩容阈值 = capacity × loadFactor
final float loadFactor;              // 负载因子，默认0.75

// 重要常量
static final int DEFAULT_INITIAL_CAPACITY = 16;  // 默认初始容量
static final float DEFAULT_LOAD_FACTOR = 0.75f;  // 默认负载因子
static final int TREEIFY_THRESHOLD = 8;          // 链表转红黑树阈值
static final int UNTREEIFY_THRESHOLD = 6;        // 红黑树转链表阈值
static final int MIN_TREEIFY_CAPACITY = 64;      // 树化最小容量
```

## 三、put方法的完整执行流程

### 流程图：

```
开始 put(key, value)
    ↓
1. 计算key的hash值
    ↓
2. 判断table是否为空？
    ↓ 是
    调用resize()初始化
    ↓ 否
3. 计算桶索引 i = (n-1) & hash
    ↓
4. 判断table[i]是否为null？
    ↓ 是
    直接创建新节点放入
    → 结束
    ↓ 否
5. 桶中已有节点，检查第一个节点
    ↓
6. 第一个节点的key是否相同？
    ↓ 是
    记录该节点（准备覆盖）
    → 跳到步骤10
    ↓ 否
7. 判断节点类型
    ↓
    是TreeNode？
    ↓ 是
    调用红黑树的插入方法
    → 跳到步骤10
    ↓ 否
8. 遍历链表
    ↓
    找到相同key？
    ↓ 是
    记录该节点
    → 跳到步骤10
    ↓ 否
    遍历到链表尾部
    ↓
9. 在链表尾部插入新节点
    ↓
    链表长度 >= 8？
    ↓ 是
    调用treeifyBin()尝试树化
    ↓
10. 如果找到了相同的key
    ↓
    用新value覆盖旧value
    返回旧value
    → 结束
    ↓ 否
11. size++
    ↓
12. size > threshold？
    ↓ 是
    调用resize()扩容
    ↓
返回null（表示是新插入）
```

### 详细代码逻辑：

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}

// 第1步：计算hash值
static final int hash(Object key) {
    int h;
    // key为null时hash为0，否则高16位与低16位异或（减少hash冲突）
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}

final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    Node<K,V>[] tab; 
    Node<K,V> p; 
    int n, i;
    
    // 第2步：检查table是否初始化
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;  // 初始化或扩容
    
    // 第3步：计算桶索引，(n-1) & hash 等价于 hash % n
    if ((p = tab[i = (n - 1) & hash]) == null)
        // 第4步：桶为空，直接创建新节点
        tab[i] = newNode(hash, key, value, null);
    else {
        // 第5步：桶不为空，需要处理冲突
        Node<K,V> e; 
        K k;
        
        // 第6步：检查第一个节点是否匹配
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;  // 找到相同的key
        
        // 第7步：如果是红黑树节点
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        
        // 第8步：遍历链表
        else {
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {
                    // 第9步：到达链表尾部，插入新节点
                    p.next = newNode(hash, key, value, null);
                    
                    // 链表长度达到阈值，尝试树化
                    if (binCount >= TREEIFY_THRESHOLD - 1)
                        treeifyBin(tab, hash);
                    break;
                }
                
                // 在链表中找到相同的key
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                
                p = e;  // 继续遍历
            }
        }
        
        // 第10步：如果找到了相同的key，更新value
        if (e != null) {
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;  // 覆盖旧值
            afterNodeAccess(e);
            return oldValue;  // 返回旧值
        }
    }
    
    ++modCount;
    // 第11-12步：检查是否需要扩容
    if (++size > threshold)
        resize();
    
    afterNodeInsertion(evict);
    return null;  // 返回null表示是新插入
}
```

## 四、关键操作详解

### 1. hash值计算（扰动函数）

```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

**为什么要异或高16位？**
- 假设数组长度为16，索引计算：`hash & 15`，只用到了hash的低4位
- 通过 `h ^ (h >>> 16)` 让高16位也参与运算，减少碰撞

### 2. 计算桶索引

```java
i = (n - 1) & hash  // n是数组长度（必须是2的幂次方）
```

**为什么用位运算？**
- `hash & (n-1)` 等价于 `hash % n`
- 位运算比取模运算快得多
- 前提：n必须是2的幂次方

**举例**：
```
假设 n = 16, hash = 25
n - 1 = 15 = 0000 1111 (二进制)
hash  = 25 = 0001 1001 (二进制)
--------------------------
i = 25 & 15 = 0000 1001 = 9

相当于 25 % 16 = 9
```

### 3. 链表树化条件

```java
if (binCount >= TREEIFY_THRESHOLD - 1)  // 链表长度 >= 8
    treeifyBin(tab, hash);
```

在 `treeifyBin` 方法中：
```java
final void treeifyBin(Node<K,V>[] tab, int hash) {
    int n, index;
    Node<K,V> e;
    
    // 如果数组容量小于64，优先扩容而不是树化
    if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
        resize();
    else if ((e = tab[index = (n - 1) & hash]) != null) {
        // 将链表转换为红黑树
        ...
    }
}
```

**树化条件**：
- 链表长度 ≥ 8
- 且数组容量 ≥ 64

### 4. 扩容机制（resize）

```java
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int newCap = oldCap << 1;  // 新容量 = 旧容量 × 2
    
    // 创建新数组
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab;
    
    // 重新计算每个节点的位置（rehash）
    for (int j = 0; j < oldCap; ++j) {
        Node<K,V> e;
        if ((e = oldTab[j]) != null) {
            // 根据 hash & oldCap 判断节点去向
            // 要么在原位置，要么在 原位置+oldCap
        }
    }
    return newTab;
}
```

**扩容触发**：`size > threshold`（threshold = capacity × 0.75）

**rehash优化**：
- 扩容后容量变为原来的2倍
- 节点要么在原位置，要么在"原位置+旧容量"的位置
- 通过 `hash & oldCap` 的结果判断（0留原地，1去新位置）

## 五、完整示例

```java
HashMap<String, Integer> map = new HashMap<>();

// 第一次put
map.put("apple", 10);

执行流程：
1. hash("apple") = 63476538（假设）
2. table为null，resize()初始化，容量16
3. 索引 = 63476538 & 15 = 10
4. table[10]为null，创建新节点
5. size = 1，threshold = 12，无需扩容

// 第二次put（hash冲突）
map.put("banana", 20);  // 假设也落在索引10

执行流程：
1. hash("banana") = 98765434（假设）
2. 索引 = 98765434 & 15 = 10
3. table[10]不为null
4. 第一个节点key不匹配
5. 不是TreeNode，遍历链表
6. 到达链表尾部，插入新节点
7. 链表长度为2，不需要树化
8. size = 2，无需扩容

// 覆盖已有key
map.put("apple", 30);

执行流程：
1. 定位到table[10]
2. 遍历链表找到key="apple"的节点
3. 用30覆盖旧值10
4. 返回旧值10
5. size不变，仍为2
```

## 六、总结

HashMap的核心思想：
1. **哈希定位**：通过hash值快速定位桶位置，实现O(1)查找
2. **处理冲突**：链表/红黑树解决hash冲突
3. **动态扩容**：负载因子控制扩容时机，保持性能
4. **优化设计**：位运算、扰动函数、树化等优化手段

希望这个详细的解释能帮助你理解HashMap的工作原理！有任何疑问欢迎继续提问。


Q：(n-1) & hash 等价于 hash % n
A：好问题！让我详细解释为什么 `(n-1) & hash` 等价于 `hash % n`。

## 前提条件

**这个等价关系成立的前提是：n 必须是 2 的幂次方**（如 2, 4, 8, 16, 32...）

## 数学原理

### 1. 2的幂次方的特点

当 n 是 2 的幂次方时：

```
n = 2    = 0000 0010 (二进制)
n-1 = 1  = 0000 0001

n = 4    = 0000 0100
n-1 = 3  = 0000 0011

n = 8    = 0000 1000
n-1 = 7  = 0000 0111

n = 16   = 0001 0000
n-1 = 15 = 0000 1111

n = 32   = 0010 0000
n-1 = 31 = 0001 1111
```

**规律发现**：
- n 的二进制表示只有一个 1（最高位）
- n-1 的二进制表示是 n 最高位之后全是 1

### 2. 位运算的本质

**与运算（&）的特点**：只保留两个数都为 1 的位

```
hash & (n-1)
```

由于 n-1 的二进制是低位全为 1，所以：
- **保留了 hash 的低位**
- **丢弃了 hash 的高位**

## 详细举例说明

### 例子1：n = 16

```
n = 16 = 0001 0000
n-1 = 15 = 0000 1111  (低4位全是1)

假设 hash = 25 = 0001 1001

25 & 15 的计算过程：
  0001 1001  (25)
& 0000 1111  (15)
-----------
  0000 1001  (9)

25 % 16 = 9  ✓ 结果相同
```

### 例子2：不同的hash值

```
n = 16, n-1 = 15 = 0000 1111

hash = 37 = 0010 0101
37 & 15:
  0010 0101  (37)
& 0000 1111  (15)
-----------
  0000 0101  (5)
37 % 16 = 5  ✓

hash = 100 = 0110 0100
100 & 15:
  0110 0100  (100)
& 0000 1111  (15)
-----------
  0000 0100  (4)
100 % 16 = 4  ✓

hash = 255 = 1111 1111
255 & 15:
  1111 1111  (255)
& 0000 1111  (15)
-----------
  0000 1111  (15)
255 % 16 = 15  ✓
```

## 为什么会等价？

### 数学证明

对于任何整数 hash 和 2的幂次方 n：

```
hash = k × n + r   (其中 0 ≤ r < n)
```

这就是除法的定义：
- k 是商
- r 是余数（即 hash % n）

**关键点**：
- k × n 在二进制中，相当于 k 左移 log₂(n) 位
- r 正好是 hash 的低 log₂(n) 位

例如 n = 16 = 2⁴：
```
hash = k × 16 + r
     = k × (2⁴) + r
     = k << 4 + r
```

r 就是 hash 的低4位，而 `hash & 15` 正好保留了低4位！

### 直观理解

```
n = 16 时，n-1 = 15 = 二进制的 1111

hash & 1111 的效果：
- 只看 hash 的低4位
- 范围正好是 0~15

hash % 16 的效果：
- 余数范围是 0~15
- 取决于 hash 的低4位
```

## 如果 n 不是 2 的幂次方会怎样？

### 反例：n = 10

```
n = 10 = 0000 1010
n-1 = 9 = 0000 1001  (不是低位全为1)

hash = 25
25 & 9:
  0001 1001  (25)
& 0000 1001  (9)
-----------
  0000 1001  (9)

但 25 % 10 = 5  ✗ 不相等！
```

**原因**：n-1 不是低位全为1的形式，位运算结果与取模不等价。

## 性能对比

```java
// 方式1：取模运算
int index = hash % n;  // 涉及除法运算，较慢

// 方式2：位运算
int index = (n - 1) & hash;  // 只有AND运算，极快
```

**性能差异**：
- 取模运算需要进行除法，CPU周期较多
- 位运算只需要一个AND指令，速度快很多倍

## 总结

`(n-1) & hash` 等价于 `hash % n` 的原因：

1. **前提**：n 是 2 的幂次方
2. **原理**：n-1 的二进制形式是低位全为 1
3. **效果**：`& (n-1)` 保留 hash 的低位，等同于取模运算
4. **优势**：位运算比取模运算快得多

这就是为什么 HashMap 要求容量必须是 2 的幂次方的原因——为了用快速的位运算替代慢速的取模运算！