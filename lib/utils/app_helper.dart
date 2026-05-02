// lib/utils/app_helper.dart
// Menggantikan static class AppData lama — hanya berisi helper murni
// Data sekarang ada di Firestore, bukan di memori statis.

class AppHelper {
  // ─── FORMAT ────────────────────────────────────────────────────────────────

  static String formatRupiah(double angka) {
    final str = angka.toStringAsFixed(0);
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write('.');
      result.write(str[i]);
      count++;
    }
    return 'Rp ${result.toString().split('').reversed.join()}';
  }

  static String formatTanggal(DateTime dt) {
    return '${dt.day} ${namaBulan(dt.month)} ${dt.year}';
  }

  static String namaBulan(int bulan) {
    const bulanList = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return bulanList[bulan];
  }

  // ─── KATEGORI ──────────────────────────────────────────────────────────────

  static const List<String> kategoriPengeluaran = [
    'Makan',
    'Transport',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Tagihan',
    'Lainnya',
  ];

  static const List<String> kategoriPemasukan = [
    'Beasiswa',
    'Kiriman Ortu',
    'Kerja Part-time',
    'Freelance',
    'Lainnya',
  ];

  // ─── IKON REKENING ─────────────────────────────────────────────────────────
  // Menggunakan icon code string, bukan emoji

  static const Map<String, String> iconLabel = {
    'bank': 'Bank',
    'phone': 'Dompet Digital',
    'card': 'Kartu Kredit',
    'atm': 'ATM',
    'cash': 'Tunai',
  };
}
