# Git 操作指南

## 一、Git 基础配置

### 安装后首次配置
```bash
# 设置用户名和邮箱
git config --global user.name "你的名字"
git config --global user.email "你的邮箱@example.com"

# 查看配置
git config --list
```

## 二、创建仓库

### 初始化本地仓库
```bash
# 在当前目录初始化
git init

# 或创建新目录并初始化
git init 项目名称
```

### 克隆远程仓库
```bash
git clone https://github.com/用户名/仓库名.git
```

## 三、基本操作流程

### 查看状态
```bash
# 查看工作区状态
git status

# 简洁模式
git status -s
```

### 添加文件到暂存区
```bash
# 添加指定文件
git add 文件名

# 添加所有修改的文件
git add .

# 添加所有 .js 文件
git add *.js
```

### 提交更改
```bash
# 提交暂存区的文件
git commit -m "提交说明"

# 添加并提交(跳过 git add)
git commit -am "提交说明"
```

### 查看提交历史
```bash
# 查看提交记录
git log

# 简洁模式(一行显示)
git log --oneline

# 查看最近 5 条记录
git log -5

# 图形化显示分支
git log --graph --oneline --all
```

## 四、分支管理

### 查看分支
```bash
# 查看本地分支
git branch

# 查看所有分支(包括远程)
git branch -a
```

### 创建分支
```bash
# 创建新分支
git branch 分支名

# 创建并切换到新分支
git checkout -b 分支名
# 或使用新命令
git switch -c 分支名
```

### 切换分支
```bash
git checkout 分支名
# 或使用新命令
git switch 分支名
```

### 合并分支
```bash
# 先切换到目标分支(如 main)
git checkout main

# 合并指定分支到当前分支
git merge 分支名
```

### 删除分支
```bash
# 删除本地分支
git branch -d 分支名

# 强制删除
git branch -D 分支名

# 删除远程分支
git push origin --delete 分支名
```

## 五、远程仓库操作

### 查看远程仓库
```bash
# 查看远程仓库
git remote -v

# 查看远程仓库详细信息
git remote show origin
```

### 添加远程仓库
```bash
git remote add origin https://github.com/用户名/仓库名.git
```

### 推送到远程仓库
```bash
# 推送到远程分支
git push origin 分支名

# 首次推送并设置上游分支
git push -u origin main

# 推送所有分支
git push --all
```

### 拉取远程更新
```bash
# 拉取并合并
git pull origin 分支名

# 仅拉取不合并
git fetch origin
```

## 六、撤销与回退

### 撤销工作区修改
```bash
# 撤销文件修改(恢复到暂存区状态)
git checkout -- 文件名

# 或使用新命令
git restore 文件名
```

### 撤销暂存区文件
```bash
# 取消暂存
git reset HEAD 文件名

# 或使用新命令
git restore --staged 文件名
```

### 回退版本
```bash
# 回退到上一个版本(保留修改)
git reset --soft HEAD^

# 回退到上一个版本(不保留修改)
git reset --hard HEAD^

# 回退到指定版本
git reset --hard 提交ID
```

### 查看历史命令
```bash
# 查看所有操作记录
git reflog
```

## 七、标签管理

### 创建标签
```bash
# 创建轻量标签
git tag v1.0

# 创建附注标签
git tag -a v1.0 -m "版本 1.0"

# 为历史提交打标签
git tag v0.9 提交ID
```

### 查看标签
```bash
# 查看所有标签
git tag

# 查看标签详情
git show v1.0
```

### 推送标签
```bash
# 推送指定标签
git push origin v1.0

# 推送所有标签
git push origin --tags
```

### 删除标签
```bash
# 删除本地标签
git tag -d v1.0

# 删除远程标签
git push origin :refs/tags/v1.0
```

## 八、常用技巧

### 暂存当前工作
```bash
# 暂存当前修改
git stash

# 查看暂存列表
git stash list

# 恢复暂存
git stash pop

# 恢复指定暂存
git stash apply stash@{0}
```

### 查看差异
```bash
# 查看工作区与暂存区差异
git diff

# 查看暂存区与最新提交差异
git diff --cached

# 查看两个提交之间差异
git diff 提交ID1 提交ID2
```

### 忽略文件
创建 `.gitignore` 文件,添加要忽略的文件或目录:
```
# 忽略所有 .log 文件
*.log

# 忽略 node_modules 目录
node_modules/

# 忽略所有 .txt 文件,但保留 important.txt
*.txt
!important.txt
```

## 九、常见问题解决

### 修改最后一次提交
```bash
# 修改提交信息
git commit --amend -m "新的提交信息"

# 添加遗漏的文件到上次提交
git add 遗漏的文件
git commit --amend --no-edit
```

### 合并冲突处理
当合并出现冲突时:
1. 使用 `git status` 查看冲突文件
2. 手动编辑冲突文件,解决冲突标记
3. 使用 `git add 文件名` 标记为已解决
4. 使用 `git commit` 完成合并

### 设置命令别名
```bash
# 设置常用命令别名
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
```

## 十、最佳实践

1. **提交频率**: 经常提交,保持每次提交的改动较小且有明确目的
2. **提交信息**: 使用清晰、描述性的提交信息
3. **分支策略**: 为新功能或修复创建独立分支
4. **代码审查**: 合并前进行代码审查
5. **同步更新**: 定期从远程仓库拉取最新代码
6. **避免提交**: 不要提交敏感信息、大型二进制文件或临时文件

---

这份指南涵盖了 Git 的核心操作。建议从基础命令开始练习,逐步掌握更高级的功能。