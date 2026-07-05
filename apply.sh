#!/system/bin/sh
# =============================================================
# APPLY — module performa PUBG (NON-ROOT / Shizuku, SD870 Android 13)
# Realme GT Neo 2 (RMX3370). Dibuat berbasis DATA probe+captest, bukan tebakan.
#
# FILOSOFI: sedikit, terukur, reversible. Hanya lever yang device-mu
# TERBUKTI baca & izinkan. Sisanya (ratusan debug.* di script lama)
# sengaja DIBUANG karena no-op di build 'user' non-root.
#
# SIFAT PER-SESI: jalankan TIAP HABIS REBOOT, sebelum main.
# (override thermal & debug.* hilang saat reboot — itu normal.)
#
# Jalankan via Shizuku/adb:
#   sh /sdcard/apply.sh
# =============================================================

# ---------------- KONFIG (ubah sesuai selera) ----------------
PKG="com.tencent.ig"          # package PUBG kamu
# CATATAN PANEL 720p: render >720p itu mubazir (panel gak bisa nampilin).
# 0.65 = ideal utk panelmu (hemat GPU, mata nyaris gak lihat beda).
# Turun ke 0.55 = headroom FPS lebih besar. JANGAN 1.0 (buang GPU sia2).
DOWNSCALE="1.0"
GAME_FPS="60"                 # target fps overlay (panelmu 60Hz -> 60 sudah pas)
# === RESOLUSI GLOBAL (khusus HP-mu: render 1080 -> panel fisik 720) ===
# 1 = turunkan render SELURUH sistem ke ~720p. GPU berhenti render pixel
#     yang panelmu gak bisa tampilkan -> lebih dingin -> throttle mundur.
# PENTING: kalau DO_RESSCALE=1, SET DOWNSCALE="1.0" di atas (hindari
# double-downscale yang bikin PUBG kabur). Coba salah satu, bukan dua-duanya.
DO_RESSCALE="1"
RES_W="720"; RES_H="1600"; RES_DENSITY="320"   # 320 = 480*(720/1080), UI tetap proporsional
DO_UIREFLOW="1"               # 1=kill launcher biar icon gak bengkak (pakai am kill, wallpaper AMAN)
DO_COMPILE="1"                # 1=coba compile PUBG ke 'speed' sekali (anti-stutter JIT)
# SF props butuh REBOOT utk efektif & kamu jarang reboot -> default 0.
# Props ini SUDAH aktif dari boot terakhirmu, jadi gak ada yang hilang.
DO_SFPROPS="0"
# -------------------------------------------------------------

log(){ echo "[apply] $*"; }
echo "=== APPLY module performa (non-root) ==="

# 1) THERMAL — lever paling berdampak yang bisa kita sentuh non-root.
#    override-status 0 = framework selalu lapor thermal NONE => game/ADPF
#    tidak self-downclock. Kernel TETAP lindungi hardware (cap freq saat
#    ekstrem) — jadi ini agresif tapi tidak merusak. Hilang saat reboot.
log "set thermalservice override-status 0 (matikan self-throttle framework)"
cmd thermalservice override-status 0 >/dev/null 2>&1
OVR=$(dumpsys thermalservice 2>/dev/null | grep -i IsStatusOverride | head -n1)
log "  -> $OVR (harus true)"

# 2) POWER STATE — pastikan tidak ada penghematan daya yang nahan clock.
log "matikan power saver"
settings put global low_power 0 >/dev/null 2>&1
settings put global low_power_sticky 0 >/dev/null 2>&1

# 3) GAME OVERLAY — knob resolusi render PUBG (device_config, writable).
#    Efektif saat PUBG di-LAUNCH ULANG. Simpan dulu nilai lama utk restore.
OLD_OVERLAY=$(cmd device_config get game_overlay "$PKG" 2>/dev/null)
log "game_overlay lama: $OLD_OVERLAY"
NEW_OVERLAY="mode=2,vulkan=1,downscaleFactor=${DOWNSCALE},fps=${GAME_FPS}"
cmd device_config put game_overlay "$PKG" "$NEW_OVERLAY" >/dev/null 2>&1
log "game_overlay baru: $(cmd device_config get game_overlay "$PKG" 2>/dev/null)"
# simpan nilai lama ke file agar restore.sh tau (kalau berbeda)
echo "$OLD_OVERLAY" > /sdcard/.claude_overlay_backup 2>/dev/null

# 3.5) RESOLUSI GLOBAL — turunkan render sistem agar pas panel fisik 720p.
#      Reversible penuh via restore.sh / 'wm size reset'.
if [ "$DO_RESSCALE" = "1" ]; then
  log "turunkan resolusi render global -> ${RES_W}x${RES_H} density ${RES_DENSITY}"
  wm size ${RES_W}x${RES_H} >/dev/null 2>&1
  wm density ${RES_DENSITY} >/dev/null 2>&1
  log "  -> $(wm size 2>/dev/null | tr -d '\n') | $(wm density 2>/dev/null)"
  # Launcher cache ukuran lama -> icon bengkak. Reflow pakai 'am kill'
  # (kill LEMBUT proses background) BUKAN force-stop, biar WALLPAPER GAK
  # ke-reset (force-stop clear state wallpaper di ColorOS). SystemUI sengaja
  # TIDAK disentuh agar wallpaper aman.
  if [ "$DO_UIREFLOW" = "1" ]; then
    LAUNCHER=$(cmd package resolve-activity -c android.intent.category.HOME --brief 2>/dev/null | tail -1 | cut -d/ -f1)
    log "reflow UI: am kill launcher ($LAUNCHER) — wallpaper aman"
    [ -n "$LAUNCHER" ] && am kill "$LAUNCHER" 2>/dev/null
  fi
fi

# 4) COMPILE PUBG -> speed (AOT penuh, hilangkan stutter JIT saat loading aset).
#    Best-effort: kalau ROM tolak, dibiarkan (speed-profile sudah cukup).
if [ "$DO_COMPILE" = "1" ]; then
  log "compile $PKG -> speed (force)... (bisa makan 30-90 detik)"
  C=$(cmd package compile -m speed -f "$PKG" 2>&1)
  log "  hasil: ${C:-<ok>}"
fi

# 5) SF PROPS — CATATAN: hanya efektif setelah REBOOT berikutnya (SF baca
#    props ini saat start). Diset sekarang supaya siap di boot depan bila
#    kamu pasang script ini sebagai boot-script (mis. via Scene).
if [ "$DO_SFPROPS" = "1" ]; then
  log "set SF props (efektif setelah reboot)"
  setprop debug.sf.latch_unsignaled 1        # latch buffer lebih awal -> frame miss turun
  setprop debug.sf.disable_backpressure 1     # jangan tahan render pipeline
  setprop debug.sf.enable_gl_backpressure 0   # kurangi latency GL
fi

echo
log "SELESAI. Untuk uji: jalankan bench.sh SEBELUM & SESUDAH, di skenario identik."
log "Ingat: LAUNCH ULANG PUBG agar game_overlay kepakai."
log "Balikin semua: sh /sdcard/restore.sh  (atau reboot)."
