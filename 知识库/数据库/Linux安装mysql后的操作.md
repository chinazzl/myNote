在Ubuntu上使用`apt install mysql-server`安装MySQL后，通常需要进行以下几个重要步骤：

## 1. 启动和启用MySQL服务
```bash
sudo systemctl start mysql
sudo systemctl enable mysql
```

## 2. 运行安全配置脚本
这是最重要的步骤之一：
```bash
sudo mysql_secure_installation
```
这个脚本会引导你：
- 设置root密码（如果还没有设置）
- 移除匿名用户
- 禁止root远程登录
- 删除测试数据库
- 重新加载权限表

## 3. 登录MySQL并进行基本配置
```bash
sudo mysql -u root -p
```

## 4. 创建新用户和数据库（推荐）
避免直接使用root用户，创建专用用户：
```sql
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
CREATE DATABASE mydatabase;
GRANT ALL PRIVILEGES ON mydatabase.* TO 'username'@'localhost';
FLUSH PRIVILEGES;
```

## 5. 检查MySQL状态
```bash
sudo systemctl status mysql
```

## 6. 配置防火墙（如果需要远程访问）
```bash
sudo ufw allow mysql
```

## 7. 编辑配置文件（可选）
如需修改默认配置：
```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

## 8. 测试连接
```bash
mysql -u username -p mydatabase
```

这些步骤完成后，你的MySQL就可以安全地投入使用了。记得定期备份数据库并保持软件更新。 