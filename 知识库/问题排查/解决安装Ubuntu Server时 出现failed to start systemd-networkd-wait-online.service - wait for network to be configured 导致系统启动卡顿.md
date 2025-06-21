# 解决安装Ubuntu Server时 出现failed to start systemd-networkd-wait-online.service - wait for network to be configured 导致系统启动卡顿


Insert the following command into the terminal:
将以下命令输入终端：

sudo nano /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service

In the nano editor add "--timeout=5" for the following line:
在 nano 编辑器中，为以下行添加"--timeout=5"：

ExecStart=/lib/systemd/systemd-networkd-wait-online --timeout=5

Press Ctrl+O for saving, enter to confirm. Exit the editor with Ctrl+X, after saving.
按 Ctrl+O 保存，按回车确认。保存后，用 Ctrl+X 退出编辑器。

Reboot the system "sudo reboot", now it will skip the network check :)
重启系统 "sudo reboot"，现在它会跳过网络检查 :)

EDIT: Alternative:    编辑：另一种方法：

apply both in order
按顺序应用两者
sudo systemctl disable systemd-networkd-wait-online.service

sudo systemctl mask systemd-networkd-wait-online.service