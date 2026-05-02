// lib/screens/recap_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import '../models/rekening_model.dart';
import '../utils/app_helper.dart';
import 'tambah_transaksi_screen.dart';

class RecapScreen extends StatefulWidget {
  final bool isEmbedded;
  const RecapScreen({super.key, this.isEmbedded = false});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  int _bulanFilter = DateTime.now().month;
  int _tahunFilter = DateTime.now().year;
  String _tipeFilter = 'semua';

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
    return StreamBuilder<List<TransaksiModel>>(
      stream: FirebaseService.streamTransaksi(),
      builder: (context, snapTransaksi) {
        return StreamBuilder<List<RekeningModel>>(
          stream: FirebaseService.streamRekening(),
          builder: (context, snapRekening) {
            final semuaTransaksi = snapTransaksi.data ?? [];
            final semuaRekening = snapRekening.data ?? [];

            final transaksiFilter = semuaTransaksi
                .where((t) =>
                    t.tanggal.month == _bulanFilter &&
                    t.tanggal.year == _tahunFilter &&
                    (_tipeFilter == 'semua' || t.tipe == _tipeFilter))
                .toList()
              ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

            final pemasukan = semuaTransaksi
                .where((t) =>
                    t.tipe == 'pemasukan' &&
                    t.tanggal.month == _bulanFilter &&
                    t.tanggal.year == _tahunFilter)
                .fold(0.0, (s, t) => s + t.jumlah);

            final pengeluaran = semuaTransaksi
                .where((t) =>
                    t.tipe == 'pengeluaran' &&
                    t.tanggal.month == _bulanFilter &&
                    t.tanggal.year == _tahunFilter)
                .fold(0.0, (s, t) => s + t.jumlah);

            final sisa = pemasukan - pengeluaran;

            // Rekap per kategori (hanya pengeluaran)
            final perKategori = <String, double>{};
            for (final t in transaksiFilter) {
              perKategori[t.kategori] =
                  (perKategori[t.kategori] ?? 0) + t.jumlah;
            }

            final body = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppHelper.namaBulan(_bulanFilter)} $_tahunFilter',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: _pilihBulan,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6BFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.calendar_month,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Ganti Bulan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          color: const Color(0xFF1A6BFF).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Bulan Ini',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
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
                  if (perKategori.isNotEmpty) ...[
                    const Text('Rekap per Kategori',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...perKategori.entries.map((e) => _buildKategoriBar(
                          e.key,
                          e.value,
                          pengeluaran,
                        )),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat Transaksi',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _buildChipFilter('Semua', 'semua'),
                          const SizedBox(width: 6),
                          _buildChipFilter('Masuk', 'pemasukan'),
                          const SizedBox(width: 6),
                          _buildChipFilter('Keluar', 'pengeluaran'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (transaksiFilter.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Belum ada transaksi',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...transaksiFilter
                        .map((t) => _buildTransaksiItem(t, semuaRekening)),
                ],
              ),
            );

            if (widget.isEmbedded) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A6BFF), Color(0xFF0A4FCC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Text('Rekap Keuangan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: body),
                ],
              );
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF5F7FF),
              appBar: AppBar(
                backgroundColor: const Color(0xFF1A6BFF),
                foregroundColor: Colors.white,
                title: const Text('Rekap Keuangan'),
                elevation: 0,
              ),
              body: body,
            );
          },
        );
      },
    );
  }

  Widget _buildTransaksiItem(TransaksiModel t, List<RekeningModel> rekening) {
    final isPemasukan = t.tipe == 'pemasukan';

    return Dismissible(
      key: Key('recap_${t.id}'),
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
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Transaksi'),
            content: Text('Hapus "${t.nama}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
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
          return true;
        }
        return false;
      },
      onDismissed: (_) {},
      child: GestureDetector(
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TambahTransaksiScreen(editData: t),
            ),
          );
        },
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
                offset: const Offset(0, 2),
              ),
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
                    if (t.catatan.isNotEmpty)
                      Text(
                        t.catatan,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPemasukan ? '+' : '-'}${AppHelper.formatRupiah(t.jumlah)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isPemasukan
                          ? const Color(0xFF00C48C)
                          : Colors.redAccent,
                    ),
                  ),
                  Text(
                    t.rekening,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingkasanCard(
      String judul, String nilai, IconData icon, Color warna, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
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
                  fontWeight: FontWeight.bold, fontSize: 14, color: warna)),
        ],
      ),
    );
  }

  Widget _buildKategoriBar(String kategori, double jumlah, double total) {
    final persen = total > 0 ? (jumlah / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kategori,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(AppHelper.formatRupiah(jumlah),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A6BFF))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: persen,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1A6BFF)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFilter(String label, String value) {
    final isSelected = _tipeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _tipeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A6BFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
