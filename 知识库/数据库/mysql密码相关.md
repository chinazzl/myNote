在 MySQL 中创建用户时提示“Your password does not satisfy the current policy requirements”，说明您设置的密码不符合 MySQL 的密码策略要求。以下是针对 MySQL 的具体解决步骤和建议：

### 1. **检查 MySQL 密码策略**
MySQL 通过 `validate_password` 插件控制密码强度，具体策略由以下变量决定：
- **`validate_password_length`**：密码最小长度（默认通常为 8）。
- **`validate_password_number_count`**：至少需要的数字数量。
- **`validate_password_mixed_case_count`**：至少需要的大写和小写字母数量。
- **`validate_password_special_char_count`**：至少需要的特殊字符数量。
- **`validate_password_policy`**：密码策略级别，分为：
  - `LOW`：仅检查长度。
  - `MEDIUM`（默认）：要求长度、大小写字母、数字和特殊字符。
  - `STRONG`：更严格，可能包括检查字典词或重复字符。

**查看当前密码策略**：
在 MySQL 命令行中运行以下命令，检查当前密码策略设置：
```sql
SHOW VARIABLES LIKE 'validate_password%';
```
输出示例：
```
+--------------------------------------+-------+
| Variable_name                        | Value |
+--------------------------------------+-------+
| validate_password_length             | 8     |
| validate_password_mixed_case_count   | 1     |
| validate_password_number_count       | 1     |
| validate_password_policy             | MEDIUM|
| validate_password_special_char_count | 1     |
+--------------------------------------+-------+
```
这表示密码需要至少 8 个字符，包含 1 个大写字母、1 个小写字母、1 个数字和 1 个特殊字符。

### 2. **创建符合策略的密码**
根据上述策略，创建一个符合要求的密码。例如：
- 满足 `MEDIUM` 策略的密码：`MyPass#2025`
  - 包含大写（`M`, `P`）、小写（`y`, `a`, `s`, `s`）、数字（`2025`）、特殊字符（`#`）。
- 避免使用：
  - 用户名或数据库名的一部分。
  - 简单模式（如 `1234` 或 `aaaa`）。
  - 常见单词（如 `password`）。

**创建用户示例**：
```sql
CREATE USER 'new_user'@'localhost' IDENTIFIED BY 'MyPass#2025';
```
确保密码符合策略要求。

### 3. **临时修改密码策略（可选）**
如果您无法创建符合要求的复杂密码，可以临时降低密码策略：
- **降低密码策略级别**：
  ```sql
  SET GLOBAL validate_password_policy = LOW;
  SET GLOBAL validate_password_length = 6; -- 调整为较短的长度
  ```
  然后再次尝试创建用户：
  ```sql
  CREATE USER 'new_user'@'localhost' IDENTIFIED BY 'simple123';
  ```

- **禁用密码验证插件**：
  如果您在测试环境且不需要严格的密码策略，可以禁用 `validate_password` 插件：
  ```sql
  UNINSTALL PLUGIN validate_password;
  ```
  禁用后，MySQL 将不检查密码强度，允许简单密码。

**注意**：在生产环境中，建议保留默认的 `MEDIUM` 或 `STRONG` 策略以确保安全性。

### 4. **验证用户创建**
创建用户后，验证是否成功：
```sql
SELECT user, host FROM mysql.user;
```
确保新用户出现在列表中。

### 5. **常见问题及解决**
- **错误仍然出现**：
  - 确认输入的密码是否包含不支持的字符（某些特殊字符可能被 MySQL 限制）。
  - 检查是否有额外的空格（复制粘贴密码时可能引入）。
- **权限问题**：
  - 确保您有创建用户的权限（需要 `CREATE USER` 权限）。
  - 使用以下命令检查当前用户权限：
    ```sql
    SHOW GRANTS FOR CURRENT_USER;
    ```
  - 如果无权限，需以管理员账户（如 `root`）登录执行操作。
- **MySQL 版本差异**：
  - 不同 MySQL 版本（5.7、8.0 或更高）对 `validate_password` 的实现可能略有不同。确保检查您使用的版本文档。
  - MySQL 8.0 默认启用了 `validate_password`，而 5.7 可能需要手动启用。

### 6. **恢复密码策略**
如果您临时降低了密码策略，完成后建议恢复默认设置：
```sql
SET GLOBAL validate_password_policy = MEDIUM;
SET GLOBAL validate_password_length = 8;
```

### 7. **安全建议**
- **生产环境**：始终使用强密码，并启用 `MEDIUM` 或 `STRONG` 策略。
- **备份密码**：将密码存储在安全的地方（如密码管理器），避免遗忘。
- **权限控制**：为新用户分配最小权限，例如：
  ```sql
  GRANT SELECT, INSERT ON database_name.* TO 'new_user'@'localhost';
  ```

### 示例完整流程
假设当前策略为 `MEDIUM`，您可以：
1. 检查策略：
   ```sql
   SHOW VARIABLES LIKE 'validate_password%';
   ```
2. 创建用户：
   ```sql
   CREATE USER 'test_user'@'localhost' IDENTIFIED BY 'Secure#Pass9';
   GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'localhost';
   FLUSH PRIVILEGES;
   ```
3. 验证：
   ```sql
   SELECT user, host FROM mysql.user;
   ```

如果问题仍未解决，请提供：
- 您使用的 MySQL 版本（运行 `SELECT VERSION();` 查看）。
- 具体的密码策略设置（`SHOW VARIABLES LIKE 'validate_password%';` 的输出）。
- 您尝试的密码（可模糊化，例如 `Abcd#1234`）。
我可以进一步帮您分析！