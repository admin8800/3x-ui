# 定义需要编译的 Go 文件列表
GO_FILES := $(shell find . -type f -name '*.go')

# 设置 Xray 的版本号
XRAY_VERSION := v25.1.1

# 设置 Xray 下载地址
XRAY_URL := https://github.com/XTLS/Xray-core/releases/download/$(XRAY_VERSION)

# 设置 OpenSSL 下载地址
OPENSSL_URL := https://github.com/IndigoUnited/Win64OpenSSL/releases/download/V3.3.0/Win64OpenSSL_Light-3_3_0.exe

# 伪目标，用于定义构建的主要步骤
.PHONY: all clean build download_xray package

# all 是默认的构建目标，包含清理、构建、下载 Xray 和打包的步骤
all: clean build download_xray package

# clean 目标：删除之前的构建文件
clean:
	rm -rf build

# build 目标：创建目标文件夹，并在 Windows 环境下进行 Go 编译
build:
	mkdir -p build/x-ui
	# GOOS=windows 设置目标操作系统为 Windows，GOARCH=amd64 设置为 64 位架构
	# go build 使用 -ldflags "-w -s" 去除调试信息，减少文件大小
	GOOS=windows GOARCH=amd64 go build -ldflags "-w -s" -o build/x-ui/x-ui.exe $(GO_FILES)

# download_xray 目标：下载 Xray 的 Windows 版本及相关依赖
download_xray:
	mkdir -p build/x-ui/bin
	# 下载 Xray Windows 64 位的 zip 文件
	wget -q $(XRAY_URL)/Xray-windows-64.zip -O build/x-ui/bin/Xray-windows-64.zip
	# 解压下载的 zip 文件
	unzip -q build/x-ui/bin/Xray-windows-64.zip -d build/x-ui/bin
	# 删除解压后的不需要的文件
	rm build/x-ui/bin/Xray-windows-64.zip
	rm build/x-ui/bin/Xray.exe
	rm build/x-ui/bin/README.md
	rm build/x-ui/bin/LICENSE
	rm build/x-ui/bin/geosite.dat
	rm build/x-ui/bin/geoip.dat
	# 重命名 Xray 可执行文件
	mv build/x-ui/bin/Xray-windows-64.exe build/x-ui/bin/xray-windows-amd64.exe
	wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O build/x-ui/bin/geoip.dat
	wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O build/x-ui/bin/geosite.dat
	wget -q -O build/x-ui/bin/geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
	wget -q -O build/x-ui/bin/geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
	wget -q -O build/x-ui/bin/geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
	wget -q -O build/x-ui/bin/geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
	# 下载 OpenSSL 安装程序并放入 SSL 文件夹
	mkdir -p build/x-ui/SSL
	wget -q $(OPENSSL_URL) -O build/x-ui/SSL/Win64OpenSSL_Light-3_3_0.exe

# package 目标：打包整个 x-ui 文件夹为 zip 文件
package:
	# 进入 build 目录，并将 x-ui 文件夹打包成 zip 文件
	cd build && zip -r x-ui-windows-amd64.zip x-ui
