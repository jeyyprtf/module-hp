#!/system/bin/sh
# =============================================================
# BENCH — ukur frame-timing & thermal secara OBJEKTIF.
# Jalankan SAAT PUBG di foreground (pakai wireless adb / brevent),
# idealnya tepat setelah selesai 3-5 menit main di tempat ramai.
#
#   sh /sdcard/bench.sh 2>&1 | tee /sdcard/bench-$(date +%s 2>/dev/null).txt
#
# Bandingkan output SEBELUM vs SESUDAH apply.sh di skenario identik.
# Yang penting BUKAN fps rata2 (udah 60), tapi: Janky% kecil & 95/99th
# percentile frame-time mendekati 16.6ms, serta scaling_max tidak jatuh.
# =============================================================
PKG="com.tencent.ig"
line(){ echo "----------------------------------------------------------"; }
echo "BENCH REPORT ($PKG)"

line; echo "## THERMAL SAAT INI (throttling aktif atau tidak?)"
for pol in policy0 policy4 policy7; do
  P=/sys/devices/system/cpu/cpufreq/$pol
  [ -d "$P" ] || continue
  echo "$pol : scaling_max=$(cat $P/scaling_max_freq 2>/dev/null) / hw_max=$(cat $P/cpuinfo_max_freq 2>/dev/null)  (cur=$(cat $P/scaling_cur_freq 2>/dev/null))"
done
echo ">> suhu CPU/GPU/skin:"
dumpsys thermalservice 2>/dev/null | grep -iE "mName=(CPU7|CPU6|GPU0|skin|battery)" | head -n 6
echo ">> override aktif? $(dumpsys thermalservice 2>/dev/null | grep -i IsStatusOverride | head -n1)"

line; echo "## FRAME STATS (gfxinfo) — metrik utama"
dumpsys gfxinfo "$PKG" 2>/dev/null | grep -iE \
  "Total frames|Janky frames|50th|90th|95th|99th|Number Missed Vsync|Number High input|Number Slow" \
  | head -n 20
echo "(kalau kosong: PUBG tidak di foreground / belum render frame)"

line; echo "## SELESAI — simpan file ini, kirim yang SEBELUM & SESUDAH ke Claude"
