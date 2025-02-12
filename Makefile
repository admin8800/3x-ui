# windows版本构建脚本，要使用此构建请安装go环境和make和mingw-w64

GO_FILES := $(shell find . -type f -name '*.go')

# 设置 Xray 内核的版本号
XRAY_VERSION := v25.1.1

# 设置 Xray 内核下载地址
XRAY_URL := https://github.com/XTLS/Xray-core/releases/download/$(XRAY_VERSION)

# 设置 OpenSSL 下载地址
OPENSSL_URL := https://slproweb.com/download/Win64OpenSSL_Light-3_4_1.exe

.PHONY: all build download_xray package

# all 是默认的构建目标，包含构建、下载 Xray 和打包的步骤
all: build download_xray package


# build 目标：创建目标文件夹，并在 Windows 环境下进行 Go 编译
build:
	mkdir -p build/x-ui
	GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc go build -ldflags "-w -s" -o build/x-ui/x-ui.exe .

# download_xray 目标：下载 Xray 的 Windows 版本及相关依赖
download_xray:
	mkdir -p build/x-ui/bin
	wget -q $(XRAY_URL)/Xray-windows-64.zip -O build/x-ui/bin/Xray-windows-64.zip
	unzip -q build/x-ui/bin/Xray-windows-64.zip -d build/x-ui/bin
	rm build/x-ui/bin/Xray-windows-64.zip
	rm build/x-ui/bin/wxray.exe
	rm build/x-ui/bin/README.md
	rm build/x-ui/bin/LICENSE
	rm build/x-ui/bin/geosite.dat
	rm build/x-ui/bin/geoip.dat
	mv build/x-ui/bin/xray.exe build/x-ui/bin/xray-windows-amd64.exe
	wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O build/x-ui/bin/geoip.dat
	wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O build/x-ui/bin/geosite.dat
	wget -q -O build/x-ui/bin/geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
	wget -q -O build/x-ui/bin/geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
	wget -q -O build/x-ui/bin/geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
	wget -q -O build/x-ui/bin/geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
	# 下载 OpenSSL 安装程序并放入 SSL 文件夹
	mkdir -p build/x-ui/SSL
	wget -q $(OPENSSL_URL) -O build/x-ui/SSL/Win64OpenSSL_Light-3_3_0.exe

# 打包整个 x-ui 文件夹为 zip 文件
package:
	cd build && zip -r x-ui-windows-amd64.zip x-ui
