# fake - Linux 命令快速查询工具

> 忘了命令？用 fake 查！

一个纯 bash 编写的 Linux 命令速查工具。方向键选择，回车复制并自动退出，命令直接可用。

## 特性

- **纯 bash 实现** — 零依赖，所有 Linux 开箱即用
- **330+ 条命令** — 覆盖文件、网络、Docker、Git、MySQL 等常用场景
- **系统自动识别** — 只显示当前发行版可用的命令，不会看到别人的包管理器
- **方向键交互** — ↑↓ 选择、Home/End、PageUp/PageDown、j/k 都支持
- **中英文搜索** — 输入 `tar`、`压缩`、`ssh` 都能找到，退格可修改搜索词
- **数字直达** — 输入数字直接跳到对应编号，支持多位数字（0.35 秒内连续输入）
- **复制即退出** — 回车复制命令后自动退出，不用手动关
- **Ctrl+F 命令行直选** — 在 shell 里按 Ctrl+F 打开选择器，选中的命令直接填入命令行
- **分层界面** — 模块/子分类/命令逐层全屏显示，互不残留
- **最近使用记录** — 常用命令一键复用
- **一键安装** — 一条命令搞定，跨发行版

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/tang7hheng/fake/main/install.sh | sudo bash
```

### 克隆安装

```bash
git clone https://github.com/tang7hheng/fake.git
cd fake
sudo bash install.sh
```

安装完成后：

```bash
source ~/.bashrc    # 或重新打开终端
fake                # 开始使用
```

## 使用方法

### 基本查询

```bash
fake                # 浏览所有模块
fake tar            # 搜索 tar 相关命令
fake 压缩           # 中文关键词搜索
fake 12 4 5         # 快捷跳转 模块>子分类>命令
```

### 交互操作

| 按键 | 功能 |
|------|------|
| `↑` `↓` 或 `j` `k` | 移动光标 |
| `Home` / `End` / `PgUp` / `PgDn` | 快速移动 |
| `Enter` | 复制选中命令到剪贴板并自动退出 |
| `b` | 返回上一级 |
| `q` / `Esc` / `Ctrl+C` | 退出 |
| 直接输入文字 | 实时搜索（退格键修改搜索词） |
| 直接输入数字 | 跳转到对应编号（支持多位） |

### 命令行快捷方式（Ctrl+F）

安装时会注入一个 Shell 绑定，让你**不用先运行 fake 再手动粘贴**：

```bash
# 在 shell 命令行直接按 Ctrl+F：
#   打开命令选择器 → 回车选中 → 命令自动填入当前命令行
#   按 Ctrl+F 前输入的文字会作为搜索关键词
$ ssh              ← 输入关键词
$ [按 Ctrl+F]      ← 打开选择器，只显示 ssh 相关命令
$ 回车选中 scp     ← 命令自动填到命令行
$ scp -r {本地目录} {用户}@{主机}:{路径}    ← 直接回车执行
```

### 系统维护

```bash
fake --detect     # 重新检测系统并更新缓存
fake --inject     # 重新注入 Ctrl+F 命令行绑定
fake --update     # 从 GitHub 更新到最新版本
fake --doctor     # 运行完整诊断
fake -h           # 显示帮助
fake -l           # 列出所有模块
```

## 命令模块

| 模块 | 命令数 | 说明 |
|------|--------|------|
| 文件操作 | 36 | 查看、复制、移动、权限、查找 |
| 文本处理 | 30 | 搜索、替换、排序、统计 |
| 网络管理 | 26 | SSH、SCP、curl、ping、端口 |
| 系统管理 | 23 | 进程、内存、CPU、系统信息 |
| 用户权限 | 16 | 用户管理、组管理、ACL |
| 软件包管理 | 12-14 | apt / dnf / pacman / zypper（按系统） |
| 磁盘与挂载 | 16 | 分区、格式化、挂载 |
| 进程与服务 | 16 | systemctl、journalctl、crontab |
| 压缩解压 | 15 | tar、zip、gzip、bzip2 |
| 防火墙 | 11-12 | ufw / firewalld（按系统） |
| 安全模块 | 4-8 | SELinux / AppArmor（按系统） |
| 开发工具 | 115 | Git、Docker、npm、Python、MySQL、Redis、Nginx、Vim |
| fake 使用帮助 | 7 | fake 自身用法 |

## 系统兼容性

| 发行版 | 支持 | 包管理器 | 防火墙 | 安全模块 |
|--------|------|----------|--------|----------|
| Ubuntu 14.04+ | ✅ | apt | ufw | AppArmor |
| Debian 8+ | ✅ | apt | ufw | AppArmor |
| Linux Mint | ✅ | apt | ufw | AppArmor |
| CentOS 7 | ✅ | yum | firewalld | SELinux |
| CentOS 8+ / Rocky / Alma | ✅ | dnf | firewalld | SELinux |
| Fedora 22+ | ✅ | dnf | firewalld | SELinux |
| Arch / Manjaro | ✅ | pacman | nftables | — |
| openSUSE | ✅ | zypper | firewalld | — |

## 工作原理

```
安装时:
  检测发行版 → 安装 xclip → 安装主程序 → 注入 Ctrl+F 绑定 → 写入缓存

使用时:
  读取缓存 → 解析输入 → 三级搜索(模块名→标签→命令) → 系统过滤 → 方向键选择 → 回车复制并自动退出
  或: Ctrl+F 打开选择器 → 选中 → 命令直接填入命令行
```

### 系统过滤

每条命令带有系统标签，`fake` 启动时读取 `/etc/os-release` 识别发行版，只展示当前系统可用的命令：

```bash
# Ubuntu 用户看到:
apt install {包名}          # 显示 ✅

# CentOS 用户看到:
dnf install {包名}          # 显示 ✅

# Arch 用户看到:
pacman -S {包名}            # 显示 ✅
```

### 自我修复

- 缓存文件丢失 → 自动重新检测
- Shell 函数被删 → `fake --inject` 恢复
- xclip 被卸载 → 自动回退到其他剪贴板工具
- `fake --doctor` 一键诊断所有问题

## 文件说明

| 文件 | 说明 |
|------|------|
| `fake.txt` | 主程序（纯 bash，约 1670 行） |
| `install.sh` | 安装脚本（约 200 行） |

安装后生成的文件：

| 文件 | 说明 |
|------|------|
| `~/.fake.conf` | 系统缓存（发行版、剪贴板工具） |
| `~/.fake_history` | 最近使用记录（最多 5 条） |
| `/tmp/_fake_cmd` | 最后选中的命令（供 Ctrl+F 填入命令行） |

## 性能

- 启动时间：约 5ms（读取缓存，无重复检测）
- 文件大小：约 64KB（主程序 56KB + 安装脚本 8KB）
- 内存占用：极低（纯 bash，无后台进程）

## 更新

```bash
fake --update
```

从 GitHub 拉取最新版本，保留用户配置和历史记录。

## 卸载

```bash
sudo rm /usr/local/bin/fake
rm ~/.fake.conf ~/.fake_history /tmp/_fake_cmd 2>/dev/null
# 手动删除 ~/.bashrc 中的 _fake_pick 函数和 Ctrl+F 绑定
```

## License

MIT
