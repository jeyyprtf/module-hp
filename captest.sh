#!/system/bin/sh
# =============================================================
# CAPABILITY TEST — cek lever mana yang device-mu IZINKAN (non-root)
# Device : RMX3370 / SD870 (kona) / Android 13 / Shizuku UID 2000
# Sifat  : semua tulisan REVERSIBLE (di-restore / hilang saat reboot).
# Tujuan : sebelum bikin module final, pastikan mana yang benar2 jalan.
#
# Jalankan:
#   sh /sdcard/captest.sh 2>&1 | tee /sdcard/captest-report.txt
# Paste captest-report.txt balik ke Claude.
# =============================================================
line(){ echo "----------------------------------------------------------"; }
sect(){ echo; line; echo "## $1"; line; }
echo "CAPABILITY TEST REPORT (paste balik ke Claude)"

# -------------------------------------------------------------
sect "A. THERMAL OVERRIDE — apakah 'override-status' benar2 jalan?"
echo ">> status awal:"
dumpsys thermalservice 2>/dev/null | grep -iE "IsStatusOverride|Thermal Status:" | head -n 2
echo ">> coba override ke 0 (NONE)..."
OUT=$(cmd thermalservice override-status 0 2>&1); echo "   keluaran perintah: '${OUT:-<kosong/ok>}'"
echo ">> status setelah override:"
dumpsys thermalservice 2>/dev/null | grep -iE "IsStatusOverride|Thermal Status:" | head -n 2
echo ">> coba kembalikan (reset)..."
R=$(cmd thermalservice reset 2>&1); echo "   keluaran reset: '${R:-<kosong/ok>}'"
dumpsys thermalservice 2>/dev/null | grep -iE "IsStatusOverride" | head -n 1
echo "   (kalau IsStatusOverride tetap true & reset error -> nanti clear via reboot)"
echo "   KESIMPULAN: kalau IsStatusOverride sempat 'true' -> lever ini JALAN."

# -------------------------------------------------------------
sect "B. BUKTI THERMAL CAPPING — hardware max vs yang diizinkan sekarang"
for pol in policy0 policy4 policy7; do
  P=/sys/devices/system/cpu/cpufreq/$pol
  [ -d "$P" ] || continue
  HW=$(cat $P/cpuinfo_max_freq 2>/dev/null)
  SC=$(cat $P/scaling_max_freq 2>/dev/null)
  echo "$pol : hardware_max=$HW  scaling_max_sekarang=$SC"
done
echo "(kalau scaling_max < hardware_max -> kernel sedang nge-cap = throttling aktif)"

# -------------------------------------------------------------
sect "C. BISA TULIS CPUFREQ? (tes governor, langsung di-restore)"
P=/sys/devices/system/cpu/cpufreq/policy7
if [ -w "$P/scaling_governor" ]; then
  ORIG=$(cat $P/scaling_governor)
  echo "governor asli policy7: $ORIG"
  echo performance > $P/scaling_governor 2>/dev/null
  NOW=$(cat $P/scaling_governor 2>/dev/null)
  echo "setelah coba tulis 'performance': $NOW"
  echo "$ORIG" > $P/scaling_governor 2>/dev/null   # restore
  echo "restore ke: $(cat $P/scaling_governor 2>/dev/null)"
  [ "$NOW" = "performance" ] && echo "HASIL: BISA tulis cpufreq (jarang non-root, tapi bagus!)" \
                             || echo "HASIL: TIDAK bisa (permission denied) — sesuai dugaan non-root"
else
  echo "HASIL: scaling_governor TIDAK writable oleh shell -> cpufreq off-limits non-root"
fi

# -------------------------------------------------------------
sect "D. STATUS KOMPILASI PUBG (target: 'speed' utk hilangkan stutter JIT)"
PKG=com.tencent.ig
echo "package: $PKG"
dumpsys package "$PKG" 2>/dev/null | grep -iE "compilation_filter|status=|dexopt" | head -n 8
echo "(kalau filter='verify' atau 'speed-profile' -> kita bisa naikkan ke 'speed')"
echo ">> tes apakah shell boleh trigger compile (mode speed-profile dulu, ringan):"
C=$(cmd package compile -m speed-profile "$PKG" 2>&1); echo "   keluaran: '${C:-<ok>}'"

# -------------------------------------------------------------
sect "E. GAME MODE / device_config — bisa tulis knob game?"
echo ">> nilai game_overlay PUBG sekarang:"
cmd device_config get game_overlay com.tencent.ig 2>/dev/null
echo ">> tes tulis flag dummy (namespace kita sendiri, lalu dihapus):"
cmd device_config put claude_test probe 1 2>&1
echo "   readback: $(cmd device_config get claude_test probe 2>/dev/null)"
cmd device_config delete claude_test probe 2>/dev/null
echo "   (kalau readback=1 -> kita BISA atur game_overlay downscale/fps)"

# -------------------------------------------------------------
sect "F. SF PROPS yang KINI aktif (konfirmasi mana yang nyangkut)"
for p in debug.sf.latch_unsignaled debug.sf.disable_backpressure \
         debug.sf.enable_gl_backpressure debug.sf.auto_latch_unsignaled \
         debug.sf.use_frame_rate_priority ; do
  printf "  %-38s = '%s'\n" "$p" "$(getprop $p)"
done

# -------------------------------------------------------------
sect "G. REFRESH RATE — bisa paksa 120Hz non-root? (buat mode 90fps PUBG)"
echo "peak (settings): $(settings get system peak_refresh_rate)"
echo "min  (settings): $(settings get system min_refresh_rate)"
echo "(info: PUBG 'Smooth' cap 60fps; 120Hz baru berguna kalau pakai 90fps mode)"

sect "SELESAI"
echo "Paste seluruh output ini. Setelah ini aku susun module final + restore."
