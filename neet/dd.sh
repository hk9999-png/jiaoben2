#!/bin/bash

# 1. 杀死已知木马进程并清理重生脚本
pkill -9 kswpad
pkill -9 systemd-kworkerd
pkill -9 .mod
chattr -i /etc/crontab /.mod /usr/lib/systemd/systemd-kworkerd 2>/dev/null
rm -f /.mod /usr/lib/systemd/systemd-kworkerd
# 彻底从系统级 crontab 中删除每分钟运行的 .mod
sed -i '/\.mod/d' /etc/crontab
crontab -r

# 2. 删除除 root 以外的所有普通用户 (UID >= 1000)
# 这会确保只有 root 这一个入口
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    userdel -r -f $user 2>/dev/null
done

# 3. 强制修改 root 密码
echo "root:b6zzGt@#epkjHXP4a" | chpasswd

# 4. 重置 SSH 密钥 (只保留你提供的那一个)
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chattr -i ~/.ssh/authorized_keys 2>/dev/null
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCRQ3eeLMFa4IkEx1Jc6KexRzPg1EuiQRBfBfaZmI4YleNgDDDT3u7bVXq8WQh/H0ueJk1jl8d0JTTCCf9kdAXDnBaCmnySENnllMXBec9wvFGSI2s7566Ue/XoWEMltfWvE7yz8l1GSp7TjzZmP3j0PcxevJm33OMznyiyivCk1TubbJfi54Qe6rwU8AOJrC85oDe0Nb3DwDhRYPqesyYQ38M0yb30Bny2ZQaAPO+hONum1gyCA65OuJG8GlNJCI8aHiuNwaIjaqrIUMxnHkwG+E8qjVHpCs+eyiFW2AFV56nEhKFK7SA9o5z9//hgswGPeuzDLDzdSIVh0JeImKCRuNzuGDDvtgANsgOEFYNIOViwKApdU74aTHx6MXquIeUaoIX6QdpgptOlI+f2VEp7yGBYdl+lAm2uZQgohljDQObvamOqH+d3N5xlMWLEKqcXkUm518jQ86/isL6EYxHLnNen8E9t4VXzc4WYVpCJry2PuK9ixa+28liS49j03deKcstqkjUa/Lbqtlxvinl3OnkJ+BDAEbVB2GmVNOEPNvptZa8BCjGBR/2UXYXv79f97s143Vwhpoo7XAx5hCTNyF3hGHcQMHIAdqlQEqsHNjf0P6PBYwb+tYIlNHE0zxrDO66RLBHHEcTmZgUg/ZBkdWKAvpwF+gsM0E8QcIHu2w== 81451@anko' > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 5. 重写 SSH 配置: 保持 22 端口，开启密码和密钥双重 root 登录
chattr -i /etc/ssh/sshd_config 2>/dev/null
cat <<EOF > /etc/ssh/sshd_config
# 基础端口
Port 22

# root 登录权限控制
PermitRootLogin yes
StrictModes yes

# 开启密钥登录
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# 开启密码登录
PasswordAuthentication yes
PermitEmptyPasswords no

# 禁用其他非必要验证
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# 6. 重启 SSH 服务应用配置
systemctl restart ssh || service ssh restart

echo "------------------------------------------------"
echo "✅ 加固与重置完成！"
echo "SSH 端口：22"
echo "Root 密码：b6zzGt@#epkjHXP4a"
echo "密钥认证：已开启 (仅保留 81451@anko)"
echo "其他用户：已清理"
echo "------------------------------------------------"
