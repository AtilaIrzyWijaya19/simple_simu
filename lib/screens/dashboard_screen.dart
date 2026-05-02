// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import '../models/rekening_model.dart';
import '../utils/app_helper.dart';
import 'tambah_transaksi_screen.dart';
import 'rekening_screen.dart';
import 'recap_screen.dart';
import 'profil_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _bulanFilter = DateTime.now().month;
  int _tahunFilter = DateTime.now().year;

  void _onNavTap(int index) {
    if (index == 2) {
      _bukaFormTransaksi();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _bukaFormTransaksi({TransaksiModel? editData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(editData: editData),
      ),
    );
  }

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (konfirmasi == true) {
      await FirebaseService.logout();
      // AuthGate otomatis redirect ke LoginScreen
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildBeranda();
      case 1:
        return const RekeningScreen(isEmbedded: true);
      case 3:
        return RecapScreen(isEmbedded: true);
      case 4:
        return ProfilScreen(onLogout: _logout);
      default:
        return _buildBeranda();
    }
  }

  Widget _buildBeranda() {
    return StreamBuilder<List<TransaksiModel>>(
      stream: FirebaseService.streamTransaksi(),
      builder: (context, snapTransaksi) {
        return StreamBuilder<List<RekeningModel>>(
          stream: FirebaseService.streamRekening(),
          builder: (context, snapRekening) {
            final transaksiAll = snapTransaksi.data ?? [];
            final rekening = snapRekening.data ?? [];

            final totalSaldo = rekening.fold(0.0, (s, r) => s + r.saldo);

            final transaksiFilter = transaksiAll
                .where((t) =>
                    t.tanggal.month == _bulanFilter &&
                    t.tanggal.year == _tahunFilter)
                .toList()
              ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

            final pemasukan = transaksiFilter
                .where((t) => t.tipe == 'pemasukan')
                .fold(0.0, (s, t) => s + t.jumlah);
            final pengeluaran = transaksiFilter
                .where((t) => t.tipe == 'pengeluaran')
                .fold(0.0, (s, t) => s + t.jumlah);
            final sisa = pemasukan - pengeluaran;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A6BFF), Color(0xFF0A4FCC)],
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selamat datang,',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  FirebaseService.namaUser,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _logout,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.logout,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Keluar',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Total Saldo',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          AppHelper.formatRupiah(totalSaldo),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pilihBulan,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${AppHelper.namaBulan(_bulanFilter)} $_tahunFilter',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildRingkasanCard(
                                'Pemasukan',
                                AppHelper.formatRupiah(pemasukan),
                                Icons.arrow_downward_rounded,
                                const Color(0xFF00C48C),
                                const Color(0xFFE6FFF7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRingkasanCard(
                                'Pengeluaran',
                                AppHelper.formatRupiah(pengeluaran),
                                Icons.arrow_upward_rounded,
                                Colors.redAccent,
                                const Color(0xFFFFEEEE),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    const Color(0xFF1A6BFF).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sisa Bulan Ini',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(
                                AppHelper.formatRupiah(sisa),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: sisa >= 0
                                      ? const Color(0xFF1A6BFF)
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transaksi Terkini',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = 3),
                              child: const Text('Lihat Semua',
                                  style: TextStyle(
                                      color: Color(0xFF1A6BFF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tekan lama untuk edit, geser untuk hapus',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        if (transaksiFilter.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  const Text('Belum ada transaksi bulan ini',
                                      style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  const Text('Tap tombol + untuk menambahkan',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        else
                          ...transaksiFilter.take(5).map(
                                (t) => _buildTransaksiItem(
                                    t, snapRekening.data ?? []),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRingkasanCard(
      String judul, String nilai, IconData icon, Color warna, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: warna, size: 16),
              ),
              const SizedBox(width: 8),
              Text(judul,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(nilai,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: warna)),
        ],
      ),
    );
  }

  /// Kartu transaksi dengan:
  /// - Long press → edit
  /// - Swipe kiri → hapus
  Widget _buildTransaksiItem(TransaksiModel t, List<RekeningModel> rekening) {
    final isPemasukan = t.tipe == 'pemasukan';

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await _konfirmasiHapus(t, rekening);
      },
      onDismissed: (_) {
        // Sudah dihandle di confirmDismiss (batch Firestore)
      },
      child: GestureDetector(
        onLongPress: () => _bukaFormTransaksi(editData: t),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isPemasukan
                      ? const Color(0xFFE6FFF7)
                      : const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPemasukan
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color:
                      isPemasukan ? const Color(0xFF00C48C) : Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      '${t.kategori} · ${AppHelper.formatTanggal(t.tanggal)}',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPemasukan ? '+' : '-'}${AppHelper.formatRupiah(t.jumlah)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isPemasukan ? const Color(0xFF00C48C) : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _konfirmasiHapus(
      TransaksiModel t, List<RekeningModel> rekening) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi'),
        content: Text('Hapus "${t.nama}"? Saldo rekening akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseService.hapusTransaksi(t, rekening);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaksi dihapus'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return true;
    }
    return false;
  }

  void _pilihBulan() {
    int tempBulan = _bulanFilter;
    int tempTahun = _tahunFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pilih Bulan & Tahun',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() => tempTahun--),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('$tempTahun',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => setModalState(() => tempTahun++),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (i) {
                      final b = i + 1;
                      final selected = b == tempBulan;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempBulan = b),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1A6BFF)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppHelper.namaBulan(b).substring(0, 3),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _bulanFilter = tempBulan;
                          _tahunFilter = tempTahun;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(
                  1, Icons.account_balance_wallet_rounded, 'Rekening'),
              GestureDetector(
                onTap: () => _onNavTap(2),
                child: Container(
                  width: 58,
                  height: 58,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A6BFF), Color(0xFF0A4FCC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A6BFF).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
              _buildNavItem(3, Icons.bar_chart_rounded, 'Rekap'),
              _buildNavItem(4, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? const Color(0xFF1A6BFF) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? const Color(0xFF1A6BFF) : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
