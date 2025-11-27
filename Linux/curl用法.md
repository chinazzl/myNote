# curl 调用接口基础用法

`curl` 是命令行工具，用于发送 HTTP/HTTPS 请求到服务器。下面给出常用用法与示例。

## 1. 基础语法

```bash
curl [选项] <URL>
```

## 2. 最常用的选项

| 选项 | 说明 | 示例 |
|------|------|------|
| `-X` | 指定 HTTP 方法（GET、POST、PUT、DELETE 等） | `curl -X POST` |
| `-H` | 添加请求头（可多次使用） | `curl -H "Content-Type: application/json"` |
| `-d` | 发送 POST 数据（默认为 form 编码） | `curl -d "name=John&age=30"` |
| `--data-raw` | 发送原始数据（不进行 URL 编码） | `curl --data-raw '{"key":"value"}'` |
| `-j` / `--json` | 自动添加 JSON 请求头并发送数据（curl 7.82+） | `curl --json '{"key":"value"}'` |
| `-F` | 上传文件（multipart/form-data） | `curl -F "file=@/path/to/file"` |
| `-o` | 将响应保存到文件 | `curl -o output.html` |
| `-O` | 将响应保存为远程文件名 | `curl -O http://example.com/file.zip` |
| `-i` | 显示响应头和响应体 | `curl -i` |
| `-I` | 仅显示响应头 | `curl -I` |
| `-v` | 详细输出（包括请求/响应过程） | `curl -v` |
| `-L` | 跟随重定向 | `curl -L` |
| `-b` | 发送 Cookie | `curl -b "session=abc123"` |
| `-c` | 保存 Cookie 到文件 | `curl -c cookies.txt` |
| `-u` | 基本认证（用户名:密码） | `curl -u "user:pass"` |
| `-H "Authorization: Bearer <token>"` | Bearer Token 认证 | `curl -H "Authorization: Bearer xxxtoken"` |
| `--data-binary` | 以二进制方式发送数据 | `curl --data-binary @file.bin` |
| `-s` / `--silent` | 静默模式（不显示进度） | `curl -s` |
| `-w` | 显示格式化的统计信息 | `curl -w "\nStatus: %{http_code}\n"` |

## 3. 常见场景示例

### GET 请求（最简单）
```bash
curl http://httpbin.org/get
```

### GET 请求带查询参数
```bash
curl "http://httpbin.org/get?name=John&age=30"
# 或用 --data-urlencode（自动 URL 编码）
curl --get --data-urlencode "name=John" --data-urlencode "age=30" http://httpbin.org/get
```

### POST 请求（form 编码）
```bash
curl -X POST -d "name=John&age=30" http://httpbin.org/post
```

### POST 请求（JSON 格式，推荐）
```bash
# 方法 1：手动指定 Content-Type（兼容所有 curl 版本）
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"John","age":30}' \
  http://httpbin.org/post

# 方法 2：使用 --json（curl 7.82+，自动处理 Content-Type）
curl --json '{"name":"John","age":30}' http://httpbin.org/post
```

### POST 请求（从文件读取 JSON）
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d @data.json \
  http://httpbin.org/post
```