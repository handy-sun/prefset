# Arch Linux WSL2 初始化记录

## 操作步骤总结

1. **首次启动 Arch WSL 实例**
   - 自动生成 pacman 密钥并填充 keyring
   - 提示建议首次启动后运行 `pacman -Syu`

2. **创建用户和组**
   - `groupadd qi`
   - `useradd -g qi -m qi -d /home/qi -s /bin/bash`
   - **配置 sudoers**：添加用户到 wheel 组前，先创建 sudoers.d drop-in 文件，否则 wheel 组有权限却无法 sudo
     ```shell
     # 通过 /etc/sudoers.d/ 添加，不动主文件，无语法风险
     cat > /etc/sudoers.d/wheel << 'EOF'
     %wheel ALL=(ALL:ALL) NOPASSWD: ALL
     EOF
     chmod 0440 /etc/sudoers.d/wheel
     ```
     > 文件权限必须为 0440，否则 sudo 会忽略此文件。WSL 个人开发环境推荐 NOPASSWD 版，多用户环境改用 `%wheel ALL=(ALL:ALL) ALL`。
   - `usermod -aG wheel qi`

3. **设置密码**
   - `passwd`（root 密码）
   - `passwd qi`（普通用户密码）

4. **配置 wsl.conf**
   ```ini
   [boot]
   systemd=true
   [user]
   default=qi
   [interop]
   enabled=false
   appendWindowsPath=false
   [network]
   generateHosts=true
   generateResolvConf=true
   hostname=archnix
   ```

5. **配置镜像源**
   - 备份原 mirrorlist
   - 替换为清华 TUNA 镜像

6. **初始化密钥并更新系统**
   - `pacman-key --init && pacman-key --populate`
   - `pacman -Sy archlinux-keyring`
   - `pacman -Syu`（升级 37 个包，总大小 54.18 MiB）

7. **安装基础包**
   - `pacman -Sy vim git`
   - 触发 perl locale 警告（LANG=en_US.UTF-8 但 locale 未生成）

8. **修复 locale**
   - `sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen`
   - `locale-gen`
   - `echo 'LANG=en_US.UTF-8' > /etc/locale.conf`

9. **安装额外包**
   - `pacman -S --needed vim sudo wget man`

## 优化建议

### 1. 先配置 `wsl.conf` 再操作，避免 interop 干扰

当前在 root 环境下操作时，`vi` 按 Tab 补全会显示 Windows 的 exe（`vid.dll`、`virtmgmt.msc` 等），因为此时 interop 仍启用。应 **第一步就创建 wsl.conf**（设置 `interop.enabled=false`、`user.default=qi`），然后 `wsl --terminate arch` 重启实例，后续所有操作以 `qi` 用户完成。

### 2. 合并系统更新和软件包安装

当前：
```
pacman -Syu
pacman -Sy vim git   # 重新同步了数据库，冗余；-Sy 有 partial upgrade 风险
```

应合并为：
```shell
pacman -Syu vim git sudo wget man
```
避免两次同步数据库，也避免 `-Sy` 安装带来的 partial upgrade 风险。

### 3. locale 配置提前到系统更新前

当前 locale 配置在安装 vim/git 之后才做，导致 perl 安装时触发 locale 警告。应在配置完镜像源后立即：
```shell
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```
这样后续所有包安装都不会出现 locale 警告。

### 4. 去掉冗余的 `pacman-key --init && pacman-key --populate`

WSL 镜像首次启动已自动完成密钥初始化和 keyring 填充（日志第 13-17 行）。换源后直接 `pacman -Sy archlinux-keyring` 即可，无需再手动 `pacman-key --init && pacman-key --populate`。

### 5. 用 `/etc/sudoers.d/` drop-in 取代直接编辑主文件

当前用 `sed` 修改 `/etc/sudoers` 解除 wheel 注释。更好的做法是在 `/etc/sudoers.d/` 下创建独立文件：

- **不动主文件**，无语法错误风险
- **权限 0440** 才生效，否则 sudo 静默忽略
- **删除文件即可回滚**，无需恢复备份

```shell
cat > /etc/sudoers.d/wheel << 'EOF'
%wheel ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/wheel
```

WSL 个人开发环境用 NOPASSWD 避免频繁输密码；多用户环境改用 `%wheel ALL=(ALL:ALL) ALL`。

### 6. 用户密码可合并到用户创建后

`passwd`（root）和 `passwd qi` 分别在第 3 步和第 4 步之间插入了 wsl.conf 配置。如果把 passwd qi 提前到 useradd 后立即执行，可以减少在 root 环境下的操作切换。

## 推荐的最优顺序

1. 创建 `wsl.conf`（设置 systemd=true, default=qi, interop 禁用, hostname）
2. `wsl --terminate arch` → 重新进入，自动以 qi 用户登录
3. `sudo groupadd qi && sudo useradd -g qi -m qi -s /bin/bash && sudo passwd qi`
   （如果 wsl.conf 设了 default=qi，需先创建用户；否则首次进入还是 root）
   实际更简单：设 `default=root` 或先不设 default，以 root 完成初始化后再改

**更合理的做法：**

首次进入后立即配置 wsl.conf，然后重启实例。以 root 完成全部初始化，最后再设置 `default=qi`：

- 创建 wsl.conf（boot.systemd=true, interop 禁用, hostname, **不设 default**）
- 重启实例重新进入（仍为 root）
- 创建用户、组
- **配置 sudoers**：`/etc/sudoers.d/wheel` 创建 drop-in 文件（NOPASSWD 版），`chmod 0440`
- `usermod -aG wheel qi`
- 设置 root 和普通用户密码
- 换源
- 配置 locale
- `pacman -Syu vim git sudo wget which openssh nano`
- 将 default 改为 qi
- 重启实例，以 qi 用户使用
