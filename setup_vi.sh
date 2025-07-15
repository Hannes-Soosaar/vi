#!/bin/bash

# List of package to install with apt name must match the package name in the apt repository
packages=(
    "openssh-server"
    "ufw"
    "build-essential"
    "curl"
    "git"
    "vim"
    "htop"
    "net-tools"
    "nmap"
    "remmina-plugin-rdp"
    "remmina-plugin-secret"
    "remmina"
    )

echo "Welcome to the pre-server setup tool. The setup will install and configure essential packages before you install your server."
echo "Checking internet connectivity..."
# Check for internet connectivity and APT availability to ensure the setup can proceed
if wget -q --spider http://archive.ubuntu.com/ubuntu/dists/focal/Release ; then
    echo "Internet is available. Continuing with the setup..."
else
    echo "No internet connection detected. Please check your connection and try again."
    exit 1
fi
# Checks to ensure the setup can proceed with root privileges
echo "This setup process requires administrative access. You'll be prompted for your password through the setup process."
echo ""
sleep 1
sudo -v || { echo " Authentication failed. Exiting."; exit 1; }
echo "Updating package lists and upgrading installed packages..."
echo ""
# Update the package list and upgrade installed packages
sudo apt update && sudo apt upgrade -y

# Checks to see what is already installed  what is not will be installed and logged
echo "Installing essential packages..."
echo ""
echo "===== Installed on $(date) =====" >> installed_packages.txt
for package in "${packages[@]}"; do
    echo "Checking if $package is installed..."
    if ! dpkg -s "$package" >/dev/null 2>&1; then
        echo "Installing $package..."
       if sudo apt install -y "$package"; then
            echo "$package" >> installed_packages.txt
        else
            echo "Failed to install $package." 
            echo "$package" >> error_log.txt
        fi
    else
        echo "$package is already installed."
        echo "$package" >> installed_packages.txt
    fi
        echo "-----------------------------------"
done
echo " Packages installed: $(wc -l < installed_packages.txt)"
echo " Packages failed:    $(wc -l < error_log.txt 2>/dev/null)"

# UFW setup
echo " "
echo "Setting up ufw firewall..."
echo ""
if dpkg -s ufw >/dev/null 2>&1; then
        declare -A ufw_rules=(
            [SSH]=22
            [HTTP]=80
            [HTTPS]=443
            [RDP]=3389
            [VNC]=5900
            [GWS1]=33334
            [GWS2]=1080
            [GWS3]=9200
            [GWS4]=3000
            [GWS5]=2077
            [GWS6]=8888
        )   
    for service in "${!ufw_rules[@]}"; do
        port=${ufw_rules[$service]}
        if ! sudo ufw status | grep -q "$port/tcp"; then
            sudo ufw allow "$port"/tcp
            echo "Allowed $service on port $port"
            echo "-----------------------------------"
        else
            echo "$service on port $port is already allowed."
        fi
    done

    sudo ufw enable
    sudo ufw status verbose > ufw_rules.txt
    echo "UFW rules have been set up and saved to ufw_rules.txt"
else 
    echo "UFW installation has failed and can not be configured,"
    echo "Please check the error_log.txt for more information."
fi

# SSH server setup
echo "configuring SSH server..." 

if dpkg -s openssh-server > /dev/null 2>&1; then
chmod 700 ~/.ssh 
if [ -f ~/.ssh/authorized_keys ]; then
    chmod 600 ~/.ssh/authorized_keys
fi

sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh > ssh_status.txt
echo "SSH server has been enabled and started. Status saved to ssh_status.txt"
else
    echo "SSH server installation has failed and can not be configured,"
    echo "Please check the error_log.txt for more information."
fi

# Remove the default logon screen from the GUI if a graphical interface is detected
echo "Configuring the user environment..."
if [ -d "/etc/gdm3" ]; then
echo "Enabling auto login for the GUI"
CURRENT_USER=$(whoami)
GMD_CONF="/etc/gdm3/custom.conf"
sudo cp $GMD_CONF "$GMD_CONF.bak.$(date +%s)"
sudo sed -i "s/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/" $GMD_CONF
sudo sed -i "s/#  AutomaticLogin = user/AutomaticLogin = \"$CURRENT_USER\"/" $GMD_CONF
echo "auto login enabled for user $CURRENT_USER"
else
  echo "No GUI detected, skipping auto login."
fi

if [ -f error_log.txt ]; then
    {
        echo "===== Errors logged from run on $(date) ====="
        cat error_log.txt
    } > temp_error_log.txt
    mv temp_error_log.txt error_log.txt
    echo "Setup complete with errors, Please review error_log.txt for details."
else
    echo "Setup complete successfully. You can review the firewall settings from ufw_rules.txt and SSH status from ssh_status.txt."
fi

echo "Some updates may require a system restart to take full effect."
echo "It's recommended to restart now to ensure all changes are applied."
echo "IF you used SSH to run the setup choose YES."

read -p "Would you like to restart the system now? (y/n): " restart_choice
if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
    echo "Restarting system..."
    sleep 2
    sudo reboot
else
    echo "Please remember to manually restart the system later."
fi
