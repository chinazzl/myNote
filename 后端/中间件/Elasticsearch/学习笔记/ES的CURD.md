## ES的CURD

### 新增

```http
# 创建索引
PUT /product?pretty
# 插入数据
PUT /product/_doc/1
{
  "name": "xiaoMi",
  "desc": "diao si ",
  "price": 2099,
  "tags": ["性价比","game"]
}
```

### 删除

```http
# 删除索引
DELETE /product
# 删除数据
DELETE /product/_doc/1
```

### 修改

```http
# 修改
# 1. 全量替换使用put
# 2. 指定字段替换
# 过时了
POST /product/_doc/1/_update
{
  "doc":{
    "price":1099
  }
}
POST /product/_update/1 
{
  "doc": {
    "price":3099
  }
}
```

### 查询

```http
# 查询索引
# 获取健康值
GET _cat/health?v
GET _cluster/health
GET /product/_search
GET _cat/indices?v
GET /product/_doc/1
```

