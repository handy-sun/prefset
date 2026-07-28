# prefset

个人偏好设置与实用脚本的备份存档。涵盖 Linux / Windows / macOS 多平台的编辑器配置、终端配色、Shell 环境、系统服务以及常用工具脚本。


---

## 目录结构总览

```
prefset/
├── bat/                  # Windows 批处理脚本
├── clang-format/         # Clang-Format 代码格式化配置与文档
├── CRT-ColorTheme/       # SecureCRT 关键字高亮配色方案
├── manjaro-cfg/          # Manjaro Linux (Arch) 系统配置
├── nix/                  # Nix 开发环境与构建任务
├── pwsh/                 # 独立 PowerShell 工具
├── qtcreator-cfg/        # Qt Creator IDE 配置
├── rc/                   # Bash RC 配置文件（服务器 / 容器）
├── shell/                # Linux Shell 实用脚本集合
├── systemd/              # Systemd 服务单元文件
├── vscode-cfg/           # VS Code 编辑器配置
├── web/                  # Web 工具页与 C++ 面试题库
├── win10/                # Windows 10/11 相关配置与脚本
├── .gitattributes        # Git 文本识别与跨平台行尾规则
├── .gitignore            # 本地工具目录忽略规则
├── mobaxterm-color-schemes.txt   # MobaXterm 终端配色方案
└── QTTabBarConfig-2024-1-16.xml  # QTTabBar 资源管理器插件配置
```

---

## 各模块详细说明

### 🖥️ bat/ — Windows 批处理脚本

| 文件 | 说明 |
|---|---|
| `Hyper-V.cmd` | 用 DISM 安装并启用 Windows Hyper-V 组件 |
| `addstartup.bat` | 递归查找指定 EXE，并写入系统级 `Run` 注册表启动项 |
| `convert.bat` | 递归查找 MP4，调用 FFmpeg 输出压缩版本 |
| `delbuild.bat` | 从指定目录递归删除名称包含 `build` 的目录 |
| `relapath.bat` | 枚举 JSON/EXE 文件并输出统一为 `/` 的相对路径 |
| `renext.bat` | 将当前目录的 `.wav` 批量改名为 `.flac`（仅改扩展名） |
| `startup.vbs` | 在隐藏窗口中从指定工作目录启动命令的 VBScript 模板 |

---

### 🎨 CRT-ColorTheme/ — SecureCRT 关键字高亮

- **Keywords/** — SecureCRT 关键字高亮配置文件（保留 UTF-8 BOM 与 CRLF）
  - `Cisco Words.ini` — Cisco 设备输出关键字高亮
  - `Highlights.ini` — 通用高亮规则
  - `colorful-network.ini` — 网络相关输出着色
- `readme.md` — 使用说明：如何导入配色到 SecureCRT

---

### 📝 clang-format/ — C/C++ 代码格式化

| 文件 | 说明 |
|---|---|
| `attach-21.1.8/.clang-format` | 面向 Clang-Format 21 的 C++ 配置：Mozilla 大括号、4 空格缩进、160 列 |
| `attach.yml` | 基于 WebKit 的较新附着式配置（Mozilla braces） |
| `attach5.0.1.yml` | 兼容 Clang-Format 5.0.1、基于 LLVM 的附着式配置 |
| `break.yaml` | 基于 Microsoft 的 Allman 换行大括号配置 |
| `break5.0.1.yaml` | 兼容 Clang-Format 5.0.1、基于 LLVM 的 Allman 配置 |

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

### ❄️ nix/ — Nix 开发环境

| 文件 | 说明 |
|---|---|
| `wsl2-kernel/shell.nix` | GCC 13 WSL2 内核编译环境，包含 Kconfig、BTF、OpenSSL、QEMU 等依赖并关闭 hardening |
| `wsl2-kernel/Justfile` | WSL2 内核的配置合并、清理、编译、menuconfig 与模块/头文件安装任务 |

---

### 🪟 pwsh/ — PowerShell 工具

| 文件 | 说明 |
|---|---|
| `Watch-FocusChange.ps1` | 通过 `SetWinEventHook` 监控 Windows 前台窗口切换，输出进程、PID、标题和程序路径 |

---

### 🛠️ qtcreator-cfg/ — Qt Creator 配置

| 文件 | 说明 |
|---|---|
| `creator_png_path.txt` | Qt Creator 图标路径记录 |
| `lightgreen_qtc4.8.0.xml` | Qt Creator 4.8 的浅绿色编辑器配色 |
| `outtool-qtc_inside_var1.txt` | Qt Creator 内置变量参考（构建、文档、设备等变量） |
| `outtool-qtc_inside_var2.txt` | Qt Creator 内置变量参考（运行、环境、会话等变量） |
| `qiplus.xml` | “Qi Plus”深色编辑器配色 |
| `qiplus_qtc5.xml` | 适配 Qt Creator 5 的“Qi Plus”配色 |
| `qtc-desktop.sh` | 复制 desktop 文件、创建 `qtcreator` 链接并安装图标 |
| `qtc4.10.0.kms` | Qt Creator 4.10 导出的键盘映射方案 |

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
| `checkport.sh` | 校验端口号并重复检查 TCP 端口是否被占用 |
| `comparenum.sh` | 交互读取两个整数并比较大小 |
| `curltest.sh` | 用限定 TLS 的 cURL 请求测试多个常用站点连通性 |
| `debian-setup.sh` | 配置 Debian Testing 软件源，升级系统并安装开发工具和现代 CLI |
| `del0sizefile.sh` | 删除当前目录中的零字节普通文件 |
| `delbuild.sh` | 从指定根目录递归删除 `build` 目录 |
| `gen-nix-sb.sh` | 生成 sing-box 服务端/客户端配置、随机凭据和分享链接，并可借助 Nix 自动加载依赖 |
| `get-so-major.sh` | 从版本化 `.so` 文件名提取库名、主版本及剩余版本段 |
| `ip4range.sh` | 根据 IPv4 CIDR 计算网络号、可用地址范围和广播地址 |
| `linuxdeployqt.sh` | 收集 Qt 程序依赖和插件，可生成 desktop 文件并配合 AppImage 工具打包 |
| `mnt-win-disk.sh` | 发现 Microsoft basic data 分区并依次挂载到 `/mnt/c` 等目录 |
| `observe_fd.sh` | 周期记录目标进程的 `/proc/<pid>/fd` 文件描述符列表 |
| `out_tbl_stru.sh` | 从指定 C++ 头文件中截取目标数据表对应的结构体定义 |
| `relapath.sh` | 查找 EXE/JSON 文件并输出相对于输入目录的路径 |
| `repairlink.sh` | 按排序结果重建版本化共享库的 `.so.<major>` 软链接 |
| `thermal-protect.sh` | 监控 CPU 温度并动态调整 Intel P-State 最大性能百分比 |
| `update-githublab.sh` | 批量拉取 GitHub、GitLab、Codeberg 子仓库，并处理有本地改动的仓库 |

---

### ⚙️ systemd/ — Systemd 服务单元

| 文件 | 说明 |
|---|---|
| `beszel.service` | Beszel Hub 监控面板服务 |
| `beszel-agent.service` | Beszel Agent 采集服务，包含 Hub 连接参数和 systemd 安全沙箱配置 |
| `demo_need_net.service` | 依赖网络上线、支持失败自动重启的守护进程模板 |
| `ntf.service` | `/usr/local/bin/ntf` 的简单测试服务单元 |
| `rclone-als.service` | 用 Rclone VFS 缓存将 Alist 远端挂载到 `/mnt/als` |

---

### 📘 vscode-cfg/ — VS Code 编辑器配置

- **`settings.json`** — 全局用户设置
  - 深度自定义的 C/C++ 语法高亮配色（基于 Atom One Dark 主题）
  - 编辑器字体、缩进、空白渲染等偏好
  - Nix 语言服务器 (nil) 配置
  - 多语言格式化设置（Python / Lua / JS / C / C++）
  - 远程 SSH 开发配置
- **`keybindings.json`** — 自定义快捷键
  - F4 绑定为 C++ 头文件/源文件切换
  - Alt+\` 绑定为在终端中打开
- **`snippets/`** — 代码片段
  - `.c.code-snippets` — C 文件头模板
  - `.h.code-snippets` — C 头文件保护宏模板
  - `.hh.code-snippets` — C++ 头文件模板
- **`OneDark(modified).json`** — 将 One Dark 注释色覆盖为深绿色的主题片段
- **`vsc-json-path.txt`** — Windows/Linux 用户配置与 One Dark 扩展路径备忘

---

### 🌐 web/ — Web 工具与题库

| 文件 | 说明 |
|---|---|
| `index.php` | 自动扫描同级目录并生成入口导航页，附随机渐变背景和一言内容 |
| `cpp_interview/index.html` | 可搜索、切换明暗主题、展开答案并记录掌握进度的 C++ 面试题库前端 |
| `cpp_interview/cpp_category_1.js` | C++ 语言核心、C++11～20 特性、语法与 STL 题目 |
| `cpp_interview/cpp_category_2.js` | 操作系统、Linux、进程线程与系统编程题目 |
| `cpp_interview/cpp_category_3.js` | 分布式架构、微服务、存储与一致性题目 |
| `cpp_interview/cpp_category_4.js` | CPU、缓存、NUMA 与性能优化题目 |
| `cpp_interview/cpp_category_5.js` | 嵌入式开发、Qt 与 GUI 机制题目 |
| `cpp_interview/cpp_category_6.js` | 构建系统、工程实践与运维题目 |
| `cpp_interview/cpp_category_7.js` | 网络网关、安全、TLS 与高速转发题目 |

---

### 🪟 win10/ — Windows 10/11 配置

| 文件/目录 | 说明 |
|---|---|
| `Microsoft.PowerShell_profile.ps1` | PowerShell 配置：oh-my-posh、PSReadLine、zoxide、Git 快捷函数、PATH 与系统代理工具 |
| `init.ps1` | 创建 Profile，并安装 PSReadLine、posh-git 和 oh-my-posh 的 PowerShell 初始化脚本 |
| `lnsf-profile.ps1` | 将当前用户 PowerShell Profile 创建为仓库配置的符号链接 |
| `DualSysTimeSync.reg` | 让 Windows 使用 UTC 硬件时钟，修复 Windows/Linux 双系统时间偏移 |
| `chocolatey.config` | Chocolatey 软件源、功能开关和超时等完整导出配置 |
| `handydeMac-mini.local.sgc` | Synergy/Deskflow 类键鼠共享配置：Mac 与 Windows 屏幕布局及修饰键映射 |
| `windowsterminal.setting.json` | Windows Terminal 的 profile、配色、字体、窗口尺寸与快捷键配置 |
| `pac/p-long.pac` | 大型域名规则 PAC，默认使用本地 `10809` 代理并支持直连回退 |
| `pac/proxywatt.pac` | 针对设计、开发与验证服务域名的本地 `26501` 代理规则 |
| `ssh-server/bootstrap-ssh.ps1` | 安装 Scoop OpenSSH Server、启用自启动并创建 TCP 22 防火墙规则 |
| `vs/my_font_color.vssettings` | Visual Studio 12 的 Consolas 字体和 C/C++ 语义高亮配色 |
| `wsl2/.wslconfig` | WSL2 的内存、镜像网络、DNS、自动回收、稀疏 VHD 与端口策略 |
| `wsl2/ubt22-setup.sh` | Ubuntu 22.04 WSL 初始化：配置 TUNA 源并安装常用开发/CLI 工具 |
| `wsl2/wsl-arch.sh` | Arch Linux WSL2 一键初始化：用户、systemd、sudo、镜像、locale 和基础包 |
| `wsl2/wsl-arch.md` | Arch WSL2 手工初始化记录、问题分析与推荐执行顺序 |

---

### 🎨 独立配置文件

| 文件 | 说明 |
|---|---|
| `.gitattributes` | Git 文本与 EOL 策略：Linux/跨平台文件使用 LF，Windows 脚本使用 CRLF，并原样保留 SecureCRT UTF-8 BOM 导出文件及注册表文件 |
| `.gitignore` | 忽略本地 `.playwright-mcp` 工具目录 |
| `mobaxterm-color-schemes.txt` | MobaXterm 终端配色方案集合，包含 5 套主题：Lovelace、Chester、Mariana、Andromeda、AtomOneLight |
| `QTTabBarConfig-2024-1-16.xml` | Windows 资源管理器 QTTabBar 插件完整配置导出（标签设置、快捷键、命令栏、分组等） |
