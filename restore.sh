#!/system/bin/sh
# =============================================================
# RESTORE — kembalikan semua perubahan apply.sh ke default.
# Aman dijalankan kapan saja. Reboot = restore paling bersih.
#   sh /sdcard/restore.sh
# =============================================================
PKG="com.tencent.ig"
log(){ echo "[restore] $*"; }
echo "=== RESTORE ke default ==="

# 1) Thermal: kembalikan manajemen thermal normal.
log "reset thermalservice (aktifkan lagi thermal management)"
cmd thermalservice reset >/dev/null 2>&1
log "  -> $(dumpsys thermalservice 2>/dev/null | grep -i IsStatusOverride | head -n1) (harus false)"

# 2) Game overlay: balikin ke nilai asli yang disimpan apply.sh.
OLD=$(cat /sdcard/.claude_overlay_backup 2>/dev/null)
if [ -n "$OLD" ] && [ "$OLD" != "null" ]; then
  log "kembalikan game_overlay ke: $OLD"
  cmd device_config put game_overlay "$PKG" "$OLD" >/dev/null 2>&1
else
  log "hapus override game_overlay (balik ke default sistem)"
  cmd device_config delete game_overlay "$PKG" >/dev/null 2>&1
fi

# 3) SF props: kosongkan supaya SF pakai default bawaan (efektif next reboot).
log "netralkan SF props (efektif setelah reboot)"
setprop debug.sf.latch_unsignaled ""
setprop debug.sf.disable_backpressure ""
setprop debug.sf.enable_gl_backpressure ""

# 3.5) resolusi global: balik ke 1080x2400 bawaan.
log "reset resolusi & density ke default"
wm size reset >/dev/null 2>&1
wm density reset >/dev/null 2>&1
log "  -> $(wm size 2>/dev/null | tr -d '\n') | $(wm density 2>/dev/null)"

# 4) power saver dibiarkan 0 (memang default sehatmu; ubah manual bila perlu).

log "SELESAI. Untuk bersih total (SF props benar2 default), REBOOT sekali."
