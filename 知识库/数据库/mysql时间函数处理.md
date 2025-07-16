MySQL提供了丰富的日期处理函数，我来为你详细介绍主要的函数类别和用法：

## 获取当前日期时间

**NOW()** - 返回当前日期和时间
```sql
SELECT NOW();
-- 输出: 2025-07-15 14:30:25
```

**CURDATE() / CURRENT_DATE()** - 返回当前日期
```sql
SELECT CURDATE();
-- 输出: 2025-07-15
```

**CURTIME() / CURRENT_TIME()** - 返回当前时间
```sql
SELECT CURTIME();
-- 输出: 14:30:25
```

## 日期格式化

**DATE_FORMAT()** - 按指定格式显示日期
```sql
SELECT DATE_FORMAT(NOW(), '%Y年%m月%d日 %H:%i:%s');
-- 输出: 2025年07月15日 14:30:25

SELECT DATE_FORMAT('2025-07-15', '%W, %M %D, %Y');
-- 输出: Tuesday, July 15th, 2025
```

常用格式符号：
- %Y: 4位年份，%y: 2位年份
- %m: 月份(01-12)，%M: 英文月份名
- %d: 日期(01-31)，%D: 带后缀的日期(1st, 2nd等)
- %H: 小时(00-23)，%h: 小时(01-12)
- %i: 分钟(00-59)，%s: 秒(00-59)
- %W: 英文星期名，%w: 星期数字(0-6)

## 日期计算

**DATE_ADD() / DATE_SUB()** - 日期加减运算
```sql
-- 加3天
SELECT DATE_ADD('2025-07-15', INTERVAL 3 DAY);
-- 输出: 2025-07-18

-- 减2个月
SELECT DATE_SUB('2025-07-15', INTERVAL 2 MONTH);
-- 输出: 2025-05-15

-- 加1年半
SELECT DATE_ADD('2025-07-15', INTERVAL 18 MONTH);
-- 输出: 2027-01-15
```

**ADDDATE() / SUBDATE()** - 简化的日期加减
```sql
SELECT ADDDATE('2025-07-15', 30);  -- 加30天
SELECT SUBDATE('2025-07-15', 7);   -- 减7天
```

**DATEDIFF()** - 计算两个日期间的天数差
```sql
SELECT DATEDIFF('2025-07-15', '2025-07-01');
-- 输出: 14 (相差14天)
```

**TIMESTAMPDIFF()** - 计算时间差(可指定单位)
```sql
SELECT TIMESTAMPDIFF(YEAR, '2023-07-15', '2025-07-15');
-- 输出: 2 (相差2年)

SELECT TIMESTAMPDIFF(MONTH, '2025-01-15', '2025-07-15');
-- 输出: 6 (相差6个月)
```

## 日期提取

**YEAR() / MONTH() / DAY()** - 提取年月日
```sql
SELECT YEAR('2025-07-15');   -- 输出: 2025
SELECT MONTH('2025-07-15');  -- 输出: 7
SELECT DAY('2025-07-15');    -- 输出: 15
```

**HOUR() / MINUTE() / SECOND()** - 提取时分秒
```sql
SELECT HOUR('14:30:25');     -- 输出: 14
SELECT MINUTE('14:30:25');   -- 输出: 30
SELECT SECOND('14:30:25');   -- 输出: 25
```

**EXTRACT()** - 通用提取函数
```sql
SELECT EXTRACT(YEAR FROM '2025-07-15');
SELECT EXTRACT(QUARTER FROM '2025-07-15');  -- 输出: 3 (第3季度)
SELECT EXTRACT(WEEK FROM '2025-07-15');     -- 输出: 29 (第29周)
```

## 星期和周相关

**DAYOFWEEK()** - 星期几(1=周日, 7=周六)
```sql
SELECT DAYOFWEEK('2025-07-15');  -- 输出: 3 (周二)
```

**WEEKDAY()** - 星期几(0=周一, 6=周日)
```sql
SELECT WEEKDAY('2025-07-15');    -- 输出: 1 (周二)
```

**DAYNAME()** - 星期名称
```sql
SELECT DAYNAME('2025-07-15');    -- 输出: Tuesday
```

**WEEK()** - 年中第几周
```sql
SELECT WEEK('2025-07-15');       -- 输出: 28
```

## 日期转换

**STR_TO_DATE()** - 字符串转日期
```sql
SELECT STR_TO_DATE('15/07/2025', '%d/%m/%Y');
-- 输出: 2025-07-15

SELECT STR_TO_DATE('2025年7月15日', '%Y年%m月%d日');
-- 输出: 2025-07-15
```

**DATE()** - 从日期时间中提取日期部分
```sql
SELECT DATE('2025-07-15 14:30:25');
-- 输出: 2025-07-15
```

**TIME()** - 从日期时间中提取时间部分
```sql
SELECT TIME('2025-07-15 14:30:25');
-- 输出: 14:30:25
```

## 实用示例

**查询本月数据**
```sql
SELECT * FROM orders 
WHERE MONTH(order_date) = MONTH(NOW()) 
AND YEAR(order_date) = YEAR(NOW());
```

**查询最近30天数据**
```sql
SELECT * FROM orders 
WHERE order_date >= DATE_SUB(NOW(), INTERVAL 30 DAY);
```

**按月份统计销售额**
```sql
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') as month,
    SUM(amount) as total_sales
FROM orders 
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

**计算年龄**
```sql
SELECT 
    name,
    TIMESTAMPDIFF(YEAR, birth_date, NOW()) as age
FROM users;
```

**获取季度信息**
```sql
SELECT 
    QUARTER(order_date) as quarter,
    COUNT(*) as order_count
FROM orders 
GROUP BY QUARTER(order_date);
```

这些函数可以灵活组合使用，满足各种日期处理需求。在实际应用中，建议根据具体业务场景选择合适的函数，并注意时区和日期格式的处理。