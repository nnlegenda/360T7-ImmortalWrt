#!/bin/bash
#=============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#=============================================================

# fw876/helloworld
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.defaultault

#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

#sed -i 's@coolsnowwolf/packages@P3TERX/packages@' feeds.conf.default

#sed -i '$a src-git passwall https://github.com/xiaorouji/openwrt-passwall' feeds.conf.default

#sed -i '$a src-git helloworld https://github.com/P3TERX/helloworld' feeds.conf.default

# 已移除 nikki feed（改用 PassWall2 作为唯一代理框架）
# echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> "feeds.conf.default"

# --- 用户自定义插件源 ---
# PassWall2（替换 PassWall）
echo "src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git;main" >> "feeds.conf.default"
# EasyTier 异地组网 LuCI
echo "src-git easytier https://github.com/EasyTier/luci-app-easytier.git;main" >> "feeds.conf.default"
