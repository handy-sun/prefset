uname=$USER
filepath=/etc/sudoers.d/${uname}-pass
sudo tee ${filepath}  <<< "${uname} ALL=(ALL) NOPASSWD:ALL"
sudo chmod 440 ${filepath}
