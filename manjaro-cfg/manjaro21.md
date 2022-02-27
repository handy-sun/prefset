# **Manjaro21.6 配置方案**

---
<!-- vscode-markdown-toc -->

<!-- vscode-markdown-toc-config
    numbering=true
    autoSave=true
    /vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## 〇. <font color="#66ccdd" size="5"> 安装系统前注意 </font>
新的manjaro终端采用了zsh

## 一. <font color="#66ccdd" size="4"> 配置软件源 </font>
由于manjaro默认的软件源在国外，使用默认的软件源会导致安装和更新程序很慢。因此第一件事就是将软件源替换为国内镜像源。
在Terminal中执行命令
```bash
sudo pacman-mirrors -i -c China -m rank
```
测试国内各个镜像源的速度。
选择一个延迟最低的镜像源即可。

sudo pacman -Syy

## 二. <font color="#e06c75" size="4"> 更新软件库、系统  </font>
执行命令，更新本机中软件库缓存：
```bash
#manjaro系统是滚动更新的，所以使用镜像安装出来的系统还需要更新到最新。执行以下命令以更新系统和软件
sudo pacman -Syy
#建议经常执行该命令，以保持系统一直处于最新的状态。终端执行：
# sudo pacman -Syyu
```
### archlinuxcn源的说明
网上很多配置章说要添加archlinuxcn的源。
这一步其实不需要做的，也不建议去做。
因为Arch Linux CN仓库是Arch Linux用户维护的第三方仓库。很多打包的二进制程序只适用于Arch Linux而非Manjaro。如果不注意，可能会出现软件不兼容的情况。

## 三. <font color="#e06c75" size="4"> 主目录文件夹名称改为英文 </font>

(1)先去手动修改文件夹名称，然后在 设置 -> 应用程序 -> 地点 这修改

(2)使用xdg-user-dirs-gtk

```bash
sudo pacman -S xdg-user-dirs-gtk
export LANG=en_US
xdg-user-dirs-gtk-update
```
然后会有个窗口提示语言更改，更新名称即可
```bash
export LANG=zh_CN.UTF-8
```
然后重启电脑如果提示语言更改，保留旧的名称即可,新版可能不生效，在Dolphin左侧侧边栏中进入每个文件夹的 编辑 属性，手动指定下新的英文路径即可


## 四. <font color="#e06c75" size="4"> fcitx框架和搜狗拼音输入法 </font>
```bash
sudo pacman -S yay fcitx-im fcitx-configtool
# 配置文件以实现开机启动fcitx,im
cp .xprofile ~/
cp .pam_environment ~/
```

重启计算机或注销再登录，fcitx配置生效
安装搜狗输入法
```bash
sudo pacman -Sy base-devel
# 第一步选择包时，输入 1 回车,安装完成后在fcitx菜单点击“重新启动”
yay fcitx-sogoupinyin
```

## 五. <font color="#e06c75" size="4"> 用户sudo不需要输入密码 </font>

```bash
# 以普通用户权限执行以下脚本，按提示输入sudo密码
./nopswd.sh
```

## 六. <font color="#e06c75" size="4"> 解决时间不对的问题(一般表现为快8小时)</font>
```bash
# 注意使用 /bin/bash
sudo timedatectl set-local-rtc 1 --adjust-system-clock
# 查看主板BIOS时间确认
sudo hwclock -r
```

## 七. <font color="#e06c75" size="4"> 安装常用软件包 </font>
```bash
sudo pacman -S git vim cmake ninja clang lldb qtcreator qt5-doc qt5-translations

yay visual-studio-code-bin
yay google-chrome

# 安装 timqq、微信（都为wine版）
yay com.qq.tim.spark
yay deepin-wine-wechat
```

## 八. <font color="#e06c75" size="4"> Arch系下QtCreator无法显示qDebug()的输出的解决方案 </font>
这是由于Archlinux的二进制打包者使用了-journald编译参数，而恰好Qt在这方面有个Bug，会导致debug信息不能正常输出，不过可以手动为QtCreator添加QT_LOGGING_TO_CONSOLE=1的环境变量来解决这个问题。

当前此Bug已经提交到了Qt的bugreports网站中，有人建议将QT_LOGGING_TO_CONSOLE=1加入到QtCreator的默认运行环境变量中，此时Bug还未修复

如果你也遇到了相同的问题，可以试试下面几个方法，这些方法是在Archlinux的Bug列表中大家针对此Bug发的一些解决方案：

1. 从命令行启动QtCreator: $ QT_LOGGING_TO_CONSOLE=1 qtcreator.
2. 使用Export将QT_LOGGING_TO_CONSOLE=1加入到环境变量中(.bashrc/.zshrc等等，可能要重启以生效).
3. 编辑qtcreator.desktop启动文件加上QT_LOGGING_TO_CONSOLE=1的环境变量.
4. 重新编译安装Qt，记得不要加-journald参数.
5. 换Qt5.3以下的版本.
   
不过现在新版本的 QtCreator 已经提示废弃了 QT_LOGGING_TO_CONSOLE 环境变量的使用，建议使用 QT_ASSUME_STDERR_HAS_CONSOLE 或者 QT_FORCE_STDERR_LOGGING（可同时都使用）。

<font color="#66ccff" size="4">建议方案</font>

修改 qtcreator的desktop 文件，加入环境变量QT_ASSUME_STDERR_HAS_CONSOLE=1。

修改方法：将 
```
Exec=qtcreator %F 
```
改为 
```
Exec=env QT_ASSUME_STDERR_HAS_CONSOLE=1 qtcreator %F
```


