# **Manjaro21(LTS) 个人推荐配置方案**

---
<!-- vscode-markdown-toc -->

<!-- vscode-markdown-toc-config
    numbering=true
    autoSave=true
    /vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## 1. <font color="#66ccdd" size="4"> 配置软件源 </font>

### 由于manjaro默认的软件源在国外，使用默认的软件源会导致安装和更新程序很慢。因此第一件事就是将软件源替换为国内镜像源。

```bash
sudo pacman-mirrors -i -c China -m rank
```

## 2. <font color="#e06c75" size="4"> /home/user 下中文目录改为英文(如果安装时选择语言为中文的话)</font>
终端执行：
```bash	
export LANG=en_US
xdg-user-dirs-gtk-update
```
之后会弹出无标题对话框，`直接点击Update Names按钮`。此时如桌面、下载等目录已经转换为Desktop、Downloads这样的英文名称了。`注意:`如果此操作之前，文件夹不为空，原文件夹不会删除，比如桌面文件夹下有用户自行创建的noteboot.txt文件，那么执行完xdg-user-dirs-gtk-update后，桌面文件夹将保留，新的空的Desktop文件夹会被创建并用于存放桌面内容。需要手动将旧的桌面内容移动到Desktop里。

还没完，如果不执行下一步，下次重启系统，系统还会提示你改回来，我们现在就告诉系统，“记住，我不要使用中文文件夹名，以后也别问我改不改回去了”

继续终端执行：
```bash	
export LANG=zh_CN.UTF-8
xdg-user-dirs-gtk-update
```
这次又弹出了之前的对话框汉语版，选中`不要再次询问我`再点击`保留旧的名称`，以后就都是英文文件夹名了

## 3. <font color="#e06c75" size="4"> 设置su密码;取消sudo密码</font>

```bash	
# 设置su密码
sudo passwd
# 用户username 使用sudo命令时不需要输入sudo密码（确保系统安全）
sudo vi /etc/sudoers
# 以下命令放在 "#includedir /etc/sudoers.d" 上一行，务必检查拼写是否无误!
<username>  ALL=(ALL) NOPASSWD:ALL
```

## 4. <font color="#e06c75" size="4"> 解决时间不对的问题(一般表现为快8小时)</font>
```bash
#ubuntu16(包括16)版本及以后
sudo timedatectl set-local-rtc 1 --adjust-system-clock
#查看主板BIOS时间确认
sudo hwclock -r
```

## 5. <font color="#e06c75" size="4"> 安装Qt (建议安装在 /opt 下) , 记得勾选 gcc </font>
```bash
# cd到有qt安装包的目录, 
chmod +x qt-opensource-linux-x64-5.12.8.run
# 使用sudo命令则默认安装在／opt 下
sudo ./qt-opensource-linux-x64-5.12.8.run
# 安装gcc编译工具包
sudo apt install build-essential 
# qt添加到环境变量（当前用户）
sudo vi ~/.bashrc
# qt添加到环境变量（root）
sudo vi /etc/profile
----------文件末尾追加以下内容-------------
export QTDIR=/opt/Qt5.12.8
export PATH=$QTDIR/5.12.8/gcc_64/bin:$PATH
export MANPATH=$QTDIR/man:$MANPATH
export LD_LIBRARY_PATH=$QTDIR/lib:$LD_LIBRARY_PATH
```

## 6. <font color="#e06c75" size="4"> 安装常用软件包 </font>
```bash
sudo apt install -y vim cmake git 
```

## 7. <font color="#e06c75" size="4"> 若在qtcreator中使用搜狗输入法输入中文，请查看此条 </font>
### (1) 安装
```bash
# 下载fcitx框架
sudo apt install -y fcitx
# 安装搜狗输入法
dpkg -i sogoupinyin_2.4.0.3469_amd64.deb
# 缺少依赖，用以下命令尝试解决
sudo apt -f install
```

### (2) 应用
a.设置->区域与语言->管理已安装的语言->键盘输入法系统->选择 fcitx->应用到此系统

b.重启系统

### (3) 使qtcreator支持
此时 qtcreator 应该仍然无法使用搜狗输入法输入中文，需要移动库文件到 `QtCreator安装目录/lib/Qt/plugins/platforminputcontexts/`
```bash
# 路径1
sudo cp /usr/lib/x86_64-linux-gnu/qt5/plugins/platforminputcontexts/libfcitxplatforminputcontextplugin.so /opt/Qt5.12.8/Tools/QtCreator/lib/Qt/plugins/platforminputcontexts
# 路径2（可能非必要）
sudo cp /usr/lib/x86_64-linux-gnu/qt5/plugins/platforminputcontexts/libfcitxplatforminputcontextplugin.so /opt/Qt5.12.8/5.12.8/gcc_64/plugins/platforminputcontexts/
```
<font size="4">**重启Qt即可生效**</font>

## 8. <font color="#e06c75" size="4"> 显示器设置添加未含有的分辨率(如:1920x1080) </font>
终端中输入以下命令:
```bash
# 输入命令后，复制输出 Modeline 后边的内容
cvt 1920 1080
# 查看显示器的名称, 记住primary的显示器名称
xrandr 
```

```bash
# 执行命令 xrandr --newmode 复制内容, 例如
xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
# 执行命令 xrandr --addmode 显示器名称 复制内容双引号中的内容
xrandr --addmode Virtual1 "1920x1080_60.00"
# 选择此分辨率
xrandr -s 1920x1080
```
> 重启系统后，此分辨率仍没有，将以上三条命令添加到 /etc/profile 中，即可每次开机都设为此分辨率


----------------------
```bash
```
