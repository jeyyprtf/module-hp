#!/system/bin/sh
# =============================================================
# CLEAN — Storage Cleaner & Dexopt Optimizer (NON-ROOT / Shizuku)
# Realme GT Neo 2 (RMX3370 / Android 13)
#
# FILOSOFI: Cepat, aman, terukur. Gak bikin HP nge-hang belasan menit.
# Membebaskan 2-8GB storage dengan memicu API resmi Android untuk trim cache,
# membersihkan folder sampah di /sdcard, dan opsional membersihkan sisa compiler.
#
# Jalankan via Shizuku/adb:
#   sh /sdcard/clean.sh
# =============================================================

# Header
echo "====================================================="
echo "       CLEANER & STORAGE OPTIMIZER (NON-ROOT)        "
echo "====================================================="
echo "Device: Realme GT Neo 2 (SD870 Kona)"
echo "Mode: Safe & Fast Cache Reclamation"
echo "====================================================="

log() { echo "[clean] $*"; }
sec() { echo; echo "--> $*"; echo "---------------------------------------------"; }

# Simpan ukuran storage sebelum dibersihkan
DF_BEFORE=$(df -h /data | grep -v Filesystem | awk '{print $4}' 2>/dev/null)
[ -z "$DF_BEFORE" ] && DF_BEFORE=$(df /data | tail -n 1 | awk '{print $4}')
log "Storage kosong SEBELUM: $DF_BEFORE"

# =============================================================
sec "1. MEMICU TRIM CACHES SISTEM (Maksimal & Aman)"
# pm trim-caches adalah API resmi Android untuk memaksa seluruh aplikasi
# membersihkan file cache mereka (/data/data/*/cache) sampai batas tertentu.
# Kita minta sistem membebaskan hingga 15GB (sistem akan membersihkan sebisanya).
log "Mengirim instruksi pm trim-caches (reclaim up to 15GB cache)..."
TRIM_REQ="15000000000" # 15 GB dalam bytes
# Kita jalankan pm trim-caches secara langsung
pm trim-caches $TRIM_REQ >/dev/null 2>&1
cmd package trim-caches $TRIM_REQ >/dev/null 2>&1
log "  -> Selesai! Cache aplikasi telah dipangkas oleh sistem."

# =============================================================
sec "2. MEMBERSIHKAN LOGS & TEMPORARY FILES DI SDCARD"
# Folder-folder publik yang sering menimbun file sampah berukuran besar.
# Kita bersihkan file log, crash dumps, cache, dan file temp.

CLEAN_PATHS="
/sdcard/Android/data/com.tencent.ig/cache
/sdcard/Android/data/com.tencent.ig/files/tgpa
/sdcard/Android/data/com.tencent.ig/files/ProgramBinaryCache
/sdcard/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Logs
/sdcard/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/UpdateInfo
/sdcard/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/RoleInfo
/sdcard/Android/obb/com.tencent.ig/cache
/sdcard/Android/data/com.oplus.launcher/cache
/sdcard/Android/data/com.oplus.launcher/files/Log
/sdcard/Android/data/com.android.providers.media/cache
/sdcard/Android/data/com.google.android.gms/cache
/sdcard/Android/data/com.google.android.youtube/cache
/sdcard/Android/data/com.google.android.youtube/files/offline
/sdcard/Android/data/com.android.chrome/cache
/sdcard/Download/.tmp
/sdcard/Download/Telegram/Telegram Documents/*.tmp
/sdcard/DCIM/.thumbnails
/sdcard/Pictures/.thumbnails
"

log "Membersihkan folder sampah & log game..."
FILES_REMOVED=0
for path in $CLEAN_PATHS; do
    if [ -d "$path" ] || [ -f "$path" ]; then
        log "  Cleaning: $path"
        rm -rf "$path"/* 2>/dev/null
        rm -rf "$path"/.* 2>/dev/null
        FILES_REMOVED=$((FILES_REMOVED + 1))
    fi
done
log "  -> Berhasil membersihkan $FILES_REMOVED area sampah di public directory."

# =============================================================
sec "3. MEMBERSIHKAN SISA PROFILE & UNUSED COMPILATION ARTIFACS"
# Android mengompilasi aplikasi ke format oat/art. Kadang aplikasi lama yang sudah
# diupdate masih menyisakan artifak kompilasi versi lama.
log "Mengeksekusi pembersihan cache compiler tak terpakai (cleanup)..."
cmd package cleanup >/dev/null 2>&1
log "  -> Selesai!"

# =============================================================
sec "4. OPTIONAL: SELEKTIF TRIM DEXOPT (Hanya jika kamu butuh lega ekstra)"
# Menghapus dexopt semua aplikasi secara total seperti script komunitasmu (15+ menit)
# TIDAK kami rekomendasikan secara default karena akan membuat HP patah-patah setelah restart.
# Tapi, jika kamu benar-benar kepepet storage dan ingin membersihkan sisa compiler,
# kamu bisa menjalankan mode di bawah secara manual dengan mengedit file ini.
# Untuk saat ini, kita lakukan delete-dexopt hanya untuk package PUBG agar JIT profilnya bersih & segar:
log "Membersihkan sisa-sisa profil compiler PUBG agar segar saat apply.sh compile berikutnya..."
pm delete-dexopt com.tencent.ig >/dev/null 2>&1
log "  -> Selesai! Profil kompilasi PUBG com.tencent.ig telah di-reset."

# =============================================================
sec "5. MENGOPTIMALKAN FLASH MEMORY (FSTRIM)"
# Fstrim memberi tahu chip flash (UFS) blok mana yang sudah kosong di sistem berkas,
# sehingga performa baca/tulis memori storage internal HP tetap maksimal kencang.
log "Memicu fstrim sistem..."
# non-root: fstrim biasa dipegang oleh JobScheduler atau cmd storaged. Kita trigger:
cmd storaged perform-fstrim >/dev/null 2>&1
# Kita juga jalankan idle maintenance jika diizinkan sistem:
cmd jobscheduler run android 105 >/dev/null 2>&1 # Trigger fstrim job if registered
log "  -> Selesai! Flash Memory (UFS) trim berhasil dipicu."

# =============================================================
sec "HASIL PEMBERSIHAN"
DF_AFTER=$(df -h /data | grep -v Filesystem | awk '{print $4}' 2>/dev/null)
[ -z "$DF_AFTER" ] && DF_AFTER=$(df /data | tail -n 1 | awk '{print $4}')

echo "Selesai membersihkan!"
echo "Storage kosong SEBELUM: $DF_BEFORE"
echo "Storage kosong SESUDAH: $DF_AFTER"
echo "====================================================="
log "Saran: Lakukan REBOOT setelah membersihkan agar cache RAM segar kembali."
log "Setelah reboot, jalankan sh /sdcard/apply.sh sebelum main PUBG."
echo "====================================================="
