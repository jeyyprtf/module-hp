# Module Performa PUBG — Realme GT Neo 2 (SD870) NON-ROOT

Dibuat berbasis **pengukuran**, bukan tebakan. Beda dari script komunitas
675 baris yang ~90% no-op, module ini cuma ~5 lever yang device-mu TERBUKTI
baca & izinkan (via probe + captest + benchmark before/after).

## Kondisi device (hasil probe)
- RMX3370, SD870 (kona), Android 13, build `user`, non-root + Shizuku.
- **Panel diganti → fisik 720p 60Hz**, tapi firmware masih render 1080p penuh
  → GPU buang 40% pixel percuma. Ini jadi lever optimasi utama kita.
- Throttling asli = **level kernel** (cap cpufreq saat panas). Non-root TIDAK
  bisa matiin ini; kita serang dari sisi **kurangi panas** biar throttle mundur.

## Strategi FINAL: B (resolusi global 720p)
Terbukti terbaik di benchmark:
| | Sebelum module | Sesudah (Strategi B) |
|---|---|---|
| Suhu max in-game | 88°C (sesi pendek) | **61-64°C** |
| 1% low (Balanced) | 46 | **52** |
| Grafik rata kanan+HDR | drop | **mulus, 58 avg** |

Isi lever aktif:
1. `wm size 720x1600` + density 320 — render sistem pas panel fisik (hemat GPU besar).
2. `cmd thermalservice override-status 0` — game gak self-throttle (ADPF).
3. `compile PUBG -> speed` — hilangkan stutter loading aset (BigJANK 8 → ~0).
4. `low_power 0` — pastikan gak ada penghematan daya.

## Cara pakai
```sh
# Jalankan sekali tiap habis reboot (kamu jarang reboot, jadi jarang perlu):
sh /sdcard/apply.sh
# WAJIB: launch ulang PUBG biar game_overlay kepakai.

# Balik normal kapan pun:
sh /sdcard/restore.sh

# Ukur objektif (jalankan saat PUBG di foreground):
sh /sdcard/bench.sh
```

## Catatan jujur
- Ini **bukan** sulap. Yang membaik: stutter loading, 1% low, suhu → headroom
  buat grafik lebih tinggi. FPS avg emang udah mentok 60 dari awal.
- Sebagian "rasa lebih smooth" di komunitas = efek **restart** (terbukti sendiri
  waktu tes: smooth abis restart padahal belum apply).
- Tembok terakhir (throttle kernel) butuh **root** untuk ditembus. Versi ini
  memaksimalkan yang bisa dicapai tanpa root, aman, dan reversible penuh.
```
