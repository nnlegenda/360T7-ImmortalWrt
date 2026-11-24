#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
sed -i 's/192.168.6.1/192.168.233.1/g' package/base-files/files/bin/config_generate

# 已移除 OpenClash（改用 PassWall2），以下 OpenClash 备份优化脚本已注释。
# 若以后重新启用 OpenClash，取消下面整段注释即可。
: <<'DISABLED_OPENCLASH_BLOCK'
# Limit OpenClash sysupgrade backups to persistent user data. Downloadable
# runtime assets such as the core and GeoIP/GeoSite databases can otherwise
# make the backup too large to restore safely on devices with small flash.
OPENCLASH_DEFAULTS="feeds/luci/applications/luci-app-openclash/root/etc/uci-defaults/luci-openclash"
python3 - "$OPENCLASH_DEFAULTS" <<'PYTHON'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = '''cat > "/lib/upgrade/keep.d/luci-app-openclash" <<-EOF
/etc/openclash/
EOF'''
new = '''cat > "/lib/upgrade/keep.d/luci-app-openclash" <<-EOF
/etc/openclash/config/
/etc/openclash/custom/
/etc/openclash/overwrite/
/etc/openclash/proxy_provider/
/etc/openclash/rule_provider/
/etc/openclash/game_rules/
/etc/openclash/backup/
EOF'''

if old not in text:
    raise SystemExit(f"OpenClash sysupgrade keep block not found in {path}")

path.write_text(text.replace(old, new, 1))
PYTHON
DISABLED_OPENCLASH_BLOCK

# ============================================================
# 修复 MT7981 5G 射频初始化失败（phy_freq_adjust failed）
#
# 根因：上游 commit 87f9199 revert 了 84449c9（feat: read eeprom from factory），
# 导致驱动不再从 Factory 分区读取出厂校准数据，改用 mt7981-default-eeprom/e2p
# 这个通用默认文件（里面是别的设备的 MAC 和校准值）。
# 2.4G 靠运行时校准能兜住，5G（80/160MHz + DPD 线性化）必须用出厂校准，
# 所以 5G 射频抛 "eeprom 0x19a bit 0 is 0, do runtime cal" 后
# phy_freq_adjust 失败，接口 RX/TX 恒为 0。
#
# 修复：恢复 001-eeprom-flash-api.patch（让驱动走 mt_mtd_read_nm_wifi("Factory")），
# 并移除那个放错校准数据的默认 e2p 文件。
# ============================================================
MT_WIFI_DIR="package/mtk/drivers/mt_wifi"

if [ -d "$MT_WIFI_DIR" ]; then
	echo "=== Fixing MT7981 5G eeprom calibration ==="

	# 1) 恢复 eeprom-flash-api patch（从 Factory 分区读校准）
	PATCH_URL="https://raw.githubusercontent.com/padavanonly/immortalwrt-mt798x-6.6/a4b7ac044302ec155454c9e2a291617426c54074/package/mtk/drivers/mt_wifi/patches/001-eeprom-flash-api.patch"
	mkdir -p "$MT_WIFI_DIR/patches"
	if [ ! -f "$MT_WIFI_DIR/patches/001-eeprom-flash-api.patch" ]; then
		wget -q -O "$MT_WIFI_DIR/patches/001-eeprom-flash-api.patch" "$PATCH_URL" || \
			curl -fsSL -o "$MT_WIFI_DIR/patches/001-eeprom-flash-api.patch" "$PATCH_URL"
	fi
	if [ -s "$MT_WIFI_DIR/patches/001-eeprom-flash-api.patch" ]; then
		echo "  001-eeprom-flash-api.patch restored"
	else
		echo "  WARNING: failed to fetch eeprom patch"
	fi

	# 2) 移除放错校准数据的默认 e2p（改用 Factory 分区真实数据）
	if [ -f "$MT_WIFI_DIR/files/mt7981-default-eeprom/e2p" ]; then
		rm -f "$MT_WIFI_DIR/files/mt7981-default-eeprom/e2p"
		echo "  removed bogus default e2p"
	fi
fi
# ============================================================

# Modify hostname
#sed -i 's/OpenWrt/360T7/g' package/base-files/files/bin/config_generate
