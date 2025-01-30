#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${red}致命错误：${plain} 请使用root权限运行此脚本\n" && exit 1

if ! ip addr show lo | grep -q '127.0.0.1'; then
    echo "127.0.0.1 not found, adding it to loopback interface..."
    sudo ip addr add 127.0.0.1/8 dev lo
else
    echo "127.0.0.1 is already configured."
fi

# 检查操作系统并设置发行版变量
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "无法检查系统OS，请联系作者！" >&2
    exit 1
fi
echo "系统发行版：$release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}不支持的CPU架构！${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "架构：$(arch)"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [[ "${release}" == "arch" ]]; then
    echo "您的操作系统是 Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "您的操作系统是 Parch Linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "您的操作系统是 Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "您的操作系统是 Armbian"
elif [[ "${release}" == "alpine" ]]; then
    echo "您的操作系统是 Alpine Linux"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "您的操作系统是 OpenSUSE Tumbleweed"
elif [[ "${release}" == "openEuler" ]]; then
    if [[ ${os_version} -lt 2203 ]]; then
        echo -e "${red}请使用 OpenEuler 22.03 或更高版本${plain}\n" && exit 1
    fi
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 CentOS 8 或更高版本${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 2004 ]]; then
        echo -e "${red}请使用 Ubuntu 20 或更高版本！${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red}请使用 Fedora 36 或更高版本！${plain}\n" && exit 1
    fi
elif [[ "${release}" == "amzn" ]]; then
    if [[ ${os_version} != "2023" ]]; then
        echo -e "${red}请使用 Amazon Linux 2023！${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red}请使用 Debian 11 或更高版本${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 80 ]]; then
        echo -e "${red}请使用 AlmaLinux 8.0 或更高版本${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Rocky Linux 8 或更高版本${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ol" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Oracle Linux 8 或更高版本${plain}\n" && exit 1
    fi
else
    echo -e "${red}此脚本不支持您的操作系统。${plain}\n"
    echo "请确保您使用以下支持的操作系统之一："
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- OpenEuler 22.03+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 8.0+"
    echo "- Rocky Linux 8+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    echo "- Amazon Linux 2023"
    exit 1
fi

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
    local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local server_ip=$(curl -s https://api.ipify.org)

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -p "是否要自定义面板端口设置？（如果不需要，将使用随机端口）[y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -p "请设置面板端口：" config_port
                echo -e "${yellow}您的面板端口是：${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}生成的随机端口：${config_port}${plain}"
            fi

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "这是一个全新安装，出于安全考虑，正在生成随机登录信息："
            echo -e "###############################################"
            echo -e "${green}用户名：${config_username}${plain}"
            echo -e "${green}密码：${config_password}${plain}"
            echo -e "${green}端口：${config_port}${plain}"
            echo -e "${green}网页路径：${config_webBasePath}${plain}"
            echo -e "${green}访问地址：http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}如果您忘记了登录信息，可以输入 'x-ui settings' 查看${plain}"
        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}网页路径缺失或太短。正在生成新的...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}新的网页路径：${config_webBasePath}${plain}"
            echo -e "${green}访问地址：http://${server_ip}:${existing_port}/${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}检测到默认凭据。需要进行安全更新...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "已生成新的随机登录凭据："
            echo -e "###############################################"
            echo -e "${green}用户名：${config_username}${plain}"
            echo -e "${green}密码：${config_password}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}如果您忘记了登录信息，可以输入 'x-ui settings' 查看${plain}"
        else
            echo -e "${green}用户名、密码和网页路径已正确设置。退出...${plain}"
        fi
    fi

    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        tag_version=$(curl -Ls "https://api.github.com/repos/admin8800/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$tag_version" ]]; then
            echo -e "${red}获取x-ui版本失败，当前无法访问GitHub API，请稍后再试${plain}"
            exit 1
        fi
        echo -e "获取到x-ui最新版本：${tag_version}，开始安装..."
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/admin8800/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载x-ui失败，请确保您的服务器能够连接GitHub${plain}"
            exit 1
        fi
    else
        tag_version=$1
        tag_version_numeric=${tag_version#v}
        min_version="2.3.5"

        if [[ "$(printf '%s\n' "$min_version" "$tag_version_numeric" | sort -V | head -n1)" != "$min_version" ]]; then
            echo -e "${red}请使用更新的版本（至少v2.3.5）。退出安装。${plain}"
            exit 1
        fi

        url="https://github.com/admin8800/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "开始安装x-ui $1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载x-ui $1 失败，请检查版本是否存在${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    cd x-ui
    chmod +x x-ui

    # 检查系统架构并重命名文件
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv bin/xray-linux-$(arch) bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui bin/xray-linux-$(arch)
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/admin8800/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${tag_version}${plain} 安装完成，面板已启动..."
    echo -e ""
    echo -e "
│  ${blue}x-ui 管理菜单 (子命令):${plain}

│  ${blue}x-ui${plain}              - 管理面板菜单
│  ${blue}x-ui start${plain}        - 启动面板
│  ${blue}x-ui stop${plain}         - 停止面板
│  ${blue}x-ui restart${plain}      - 重启面板
│  ${blue}x-ui status${plain}       - 查看面板状态
│  ${blue}x-ui settings${plain}     - 查看当前设置
│  ${blue}x-ui enable${plain}       - 设置开机自启
│  ${blue}x-ui disable${plain}      - 取消开机自启
│  ${blue}x-ui log${plain}          - 查看面板日志
│  ${blue}x-ui banlog${plain}       - 查看Fail2ban封禁日志
│  ${blue}x-ui update${plain}       - 更新面板
│  ${blue}x-ui legacy${plain}       - 切换到旧版
│  ${blue}x-ui install${plain}      - 安装面板
│  ${blue}x-ui uninstall${plain}    - 卸载面板
   "
}

echo -e "${green}Running...${plain}"
install_base
install_x-ui $1
