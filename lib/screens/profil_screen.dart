// lib/screens/profil_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import '../models/rekening_model.dart';
import '../utils/app_helper.dart';

class ProfilScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const ProfilScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return StreamBuilder<List<TransaksiModel>>(
      stream: FirebaseService.streamTransaksi(),
      builder: (context, snapT) {
        return StreamBuilder<List<RekeningModel>>(
          stream: FirebaseService.streamRekening(),
          builder: (context, snapR) {
            final transaksi = snapT.data ?? [];
            final rekening = snapR.data ?? [];

            final pemasukan = transaksi
                .where((t) =>
                    t.tipe == 'pemasukan' &&
                    t.tanggal.month == now.month &&
                    t.tanggal.year == now.year)
                .fold(0.0, (s, t) => s + t.jumlah);

            final pengeluaran = transaksi
                .where((t) =>
                    t.tipe == 'pengeluaran' &&
                    t.tanggal.month == now.month &&
                    t.tanggal.year == now.year)
                .fold(0.0, (s, t) => s + t.jumlah);

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A6BFF), Color(0xFF0A4FCC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          FirebaseService.namaUser,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FirebaseService.emailUser,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistik Bulan Ini',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Pemasukan',
                                AppHelper.formatRupiah(pemasukan),
                                Icons.arrow_downward_rounded,
                                const Color(0xFF00C48C),
                                const Color(0xFFE6FFF7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Transaksi',
                                '${transaksi.length} data',
                                Icons.receipt_long_outlined,
                                const Color(0xFF1A6BFF),
                                const Color(0xFFF0F5FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Rekening',
                                '${rekening.length} aktif',
                                Icons.account_balance_wallet_outlined,
                                Colors.orange,
                                const Color(0xFFFFF8EC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Informasi Akun',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.person_outline,
                          label: 'Nama Lengkap',
                          value: FirebaseService.namaUser,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: FirebaseService.emailUser,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.school_outlined,
                          label: 'Aplikasi',
                          value: 'SiMu — Sistem Keuangan Mahasiswa',
                        ),
                        const SizedBox(height: 24),
                        const Text('Tentang Aplikasi',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A6BFF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('SiMu',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1A6BFF))),
                                      Text('Sistem Keuangan Mahasiswa',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 14),
                              const Text(
                                'Aplikasi pencatatan keuangan yang dirancang khusus '
                                'untuk mahasiswa. Mencatat pemasukan, pengeluaran, '
                                'dan memantau saldo rekening secara real-time.',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Kelompok 6  ·  Universitas Negeri Gorontalo',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.red.shade200),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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

  Widget _buildStatCard(
    String judul,
    String nilai,
    IconData icon,
    Color warna,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: warna.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: warna, size: 16),
          ),
          const SizedBox(height: 10),
          Text(nilai,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: warna)),
          const SizedBox(height: 2),
          Text(judul,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1A6BFF), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
