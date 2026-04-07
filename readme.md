# prefset.bak

个人偏好设置与实用脚本的备份存档。涵盖 Linux / Windows / macOS 多平台的编辑器配置、终端配色、Shell 环境、系统服务以及常用工具脚本。

> 此项目之后会逐步向其他仓库迁移。之后会在别的项目更新分模块的详细配置。

---

## 目录结构总览

```
prefset.bak/
├── bat/                  # Windows 批处理脚本
├── clang-format/         # Clang-Format 代码格式化配置与文档
├── CRT-ColorTheme/       # SecureCRT 关键字高亮配色方案
├── manjaro-cfg/          # Manjaro Linux (Arch) 系统配置
├── py/                   # Python 实用工具脚本
├── qtcreator-cfg/        # Qt Creator IDE 配置
├── rc/                   # Bash RC 配置文件（服务器 / 容器）
├── shell/                # Linux Shell 实用脚本集合
├── sshd_config.d/        # SSH 服务端配置
├── systemd/              # Systemd 服务单元文件
├── vscode-cfg/           # VS Code 编辑器配置
├── win10/                # Windows 10/11 相关配置与脚本
├── mobaxterm-color-schemes.txt   # MobaXterm 终端配色方案
└── QTTabBarConfig-2024-1-16.xml  # QTTabBar 资源管理器插件配置
```

---

## 各模块详细说明

### 🖥️ bat/ — Windows 批处理脚本

| 文件 | 说明 |
|---|---|
| `Hyper-V.cmd` | Hyper-V 虚拟化管理命令 |
| `addstartup.bat` | 添加开机启动项 |
| `convert.bat` | 文件格式转换 |
| `delbuild.bat` | 清理构建产物 |
| `relapath.bat` | 获取相对路径 |
| `renext.bat` | 批量重命名文件扩展名 |
| `startup.vbs` | VBScript 启动脚本 |

---

### 🎨 CRT-ColorTheme/ — SecureCRT 关键字高亮

- **Keywords/** — SecureCRT 关键字高亮配置文件（`.ini` 格式）
  - `Cisco Words.ini` — Cisco 设备输出关键字高亮
  - `Highlights.ini` — 通用高亮规则
  - `colorful-network.ini` — 网络相关输出着色
- `readme.md` — 使用说明：如何导入配色到 SecureCRT

---

### 📝 clang-format/ — C/C++ 代码格式化

- Clang-Format **Style Options 文档**（Clang 13），含中英文版本 HTML
- 多种格式化风格配置（`.yml` / `.yaml`）：
  - `attach.yml` / `attach5.0.1.yml` — 大括号附着风格
  - `break.yaml` / `break5.0.1.yaml` — 大括号换行风格

---

### 🐧 manjaro-cfg/ — Manjaro Linux 配置

| 文件 | 说明 |
|---|---|
| `.pam_environment` | PAM 环境变量，设置 fcitx 输入法 |
| `.xprofile` | X 会话启动时导出 fcitx 输入法环境变量 |
| `pacman.conf` | Pacman 包管理器配置 |
| `sortpkgsize.sh` | 按安装大小排序列出已安装包 |
| `xfce4_date_format` | XFCE4 面板日期格式 |

---

### 🐍 py/ — Python 工具脚本

| 文件 | 说明 |
|---|---|
| `loadcdll.py` | 使用 ctypes 加载 C 动态链接库 (`.so`) 的示例 |
| `mkicns.py` | macOS `.icns` 图标文件的创建与解压工具（支持 PNG ↔ ICNS 互转） |
| `somajor.py` | 从 `.so` 文件名中提取主版本号（如 `libfoo.so.1`） |

---

### 🛠️ qtcreator-cfg/ — Qt Creator 配置

| 文件 | 说明 |
|---|---|
| `lightgreen_qtc4.8.0.xml` | 浅绿色主题配色（Qt Creator 4.8.0） |
| `qiplus.xml` / `qiplus_qtc5.xml` | 自定义配色主题 |
| `qtc4.10.0.kms` | 键盘快捷键方案 |
| `qtc-desktop.sh` | 生成 Qt Creator 桌面快捷方式 |
| `creator_png_path.txt` | Qt Creator 图标路径记录 |
| `outtool-qtc_inside_var*.txt` | Qt Creator 内置变量参考文档 |

---

### 📟 rc/ — Bash RC 配置

- **`.patch.bashrc`** — 服务器/嵌入式设备用 bashrc 补丁
  - 自定义函数：`dus`（磁盘排序）、`rlip4`（获取 IPv4）、`pgre`/`ppre`（进程查找）
  - 彩色 PS1 提示符（显示时间、磁盘使用率、路径缩写）
  - 常用 alias 和 history 优化
- **`ctn.bashrc`** — 容器环境专用 bashrc
  - 精简版配置，PS1 显示容器 IP 地址

---

### 🐚 shell/ — Linux Shell 工具脚本集

| 文件 | 说明 |
|---|---|
| `checkport.sh` | 检查端口占用 |
| `comparenum.sh` | 数值比较工具 |
| `curltest.sh` | cURL 测试脚本 |
| `debian-setup.sh` | **Debian 系统一键初始化**：配置源、安装开发工具链和现代 CLI 工具 |
| `del0sizefile.sh` | 删除零字节文件 |
| `delbuild.sh` | 清理构建目录 |
| `get-so-major.sh` | 获取动态库主版本号 |
| `ip4range.sh` | IPv4 地址范围计算 |
| `linuxdeployqt.sh` | Linux 上打包 Qt 应用的部署脚本 |
| `mnt-win-disk.sh` | 挂载 Windows 磁盘分区 |
| `nopswd.sh` | 配置免密码 sudo |
| `observe_fd.sh` | 观察进程文件描述符 |
| `out_tbl_stru.sh` | 输出数据库表结构 |
| `relapath.sh` | 获取相对路径 |
| `repairlink.sh` | 修复符号链接 |
| `thermal-protect.sh` | CPU 温控保护脚本 |
| `update-githublab.sh` | 更新 GitHub/GitLab 仓库镜像 |

---

### 🔐 sshd_config.d/ — SSH 服务端配置

- **`zba.conf`** — SSH 安全配置
  - 自定义端口 (3512)
  - 启用 X11 转发
  - 仅允许特定用户/组 (`qi`, `tester`)
  - 指定用户强制公钥认证、禁用密码登录

---

### ⚙️ systemd/ — Systemd 服务单元

| 文件 | 说明 |
|---|---|
| `beszel.service` | Beszel Hub 监控面板服务 |
| `beszel-agent.service` | Beszel Agent 监控采集服务（含安全沙箱配置） |
| `rclone-als.service` | Rclone 挂载 Alist 网盘为本地目录 |
| `demo_need_net.service` | 依赖网络的守护进程服务模板 |

---

### 📘 vscode-cfg/ — VS Code 编辑器配置

- **`settings.json`** — 全局用户设置
  - 深度自定义的 C/C++ 语法高亮配色（基于 Atom One Dark 主题）
  - 编辑器字体、缩进、空白渲染等偏好
  - Nix 语言服务器 (nil) 配置
  - 多语言格式化设置（Python / Lua / JS / C / C++）
  - GitHub Copilot 精细化启停控制
  - 远程 SSH 开发配置
- **`keybindings.json`** — 自定义快捷键
  - F4 绑定为 C++ 头文件/源文件切换
  - Alt+\` 绑定为在终端中打开
- **`snippets/`** — 代码片段
  - `.c.code-snippets` — C 文件头模板
  - `.h.code-snippets` — C 头文件保护宏模板
  - `.hh.code-snippets` — C++ 头文件模板
- **`OneDark(modified).json`** — 自定义 OneDark 配色变体
- **`vsc-json-path.txt`** — VS Code 配置文件路径备忘

---

### 🪟 win10/ — Windows 10/11 配置

| 文件/目录 | 说明 |
|---|---|
| `Microsoft.PowerShell_profile.ps1` | PowerShell 配置文件：oh-my-posh 主题、PSReadLine 智能补全、历史搜索、PATH 管理 |
| `init.ps1` | PowerShell 环境初始化脚本（安装 PSReadLine、posh-git、oh-my-posh） |
| `.wslconfig` | WSL2 配置：内存限制 16GB、镜像网络模式、自动内存回收、稀疏 VHD |
| `windowsterminal.setting.json` | Windows Terminal 设置：配色方案、字体、快捷键、多 profile 配置 |
| `DualSysTimeSync.reg` | 注册表补丁：修复 Windows/Linux 双系统时间同步问题 |
| `chocolatey.config` | Chocolatey 包管理器完整配置 |
| `wsl-ubuntu2004.sh` | WSL Ubuntu 20.04 环境初始化脚本 |
| `pac/` | 代理自动配置 (PAC) 文件 |
| `vs/` | Visual Studio 字体配色设置 (`my_font_color.vssettings`) |

---

### 🎨 独立配置文件

| 文件 | 说明 |
|---|---|
| `mobaxterm-color-schemes.txt` | MobaXterm 终端配色方案集合，包含 5 套主题：Lovelace、Chester、Mariana、Andromeda、AtomOneLight |
| `QTTabBarConfig-2024-1-16.xml` | Windows 资源管理器 QTTabBar 插件完整配置导出（标签设置、快捷键、命令栏、分组等） |
