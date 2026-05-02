// lib/screens/tambah_transaksi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_data.dart';

class TambahTransaksiScreen extends StatefulWidget {
  final TransaksiModel? editData; // null = tambah baru, isi = edit

  const TambahTransaksiScreen({super.key, this.editData});

  @override
  State<TambahTransaksiScreen> createState() => _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState extends State<TambahTransaksiScreen> {
  String _tipe = 'pengeluaran';
  final _namaCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String? _kategori;
  String? _rekening;
  DateTime _tanggal = DateTime.now();
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      final d = widget.editData!;
      _tipe = d.tipe;
      _namaCtrl.text = d.nama;
      _jumlahCtrl.text = d.jumlah.toStringAsFixed(0);
      _catatanCtrl.text = d.catatan;
      _kategori = d.kategori;
      _rekening = d.rekening;
      _tanggal = d.tanggal;
    }
  }

  List<String> get _kategoriList => _tipe == 'pengeluaran'
      ? AppData.kategoriPengeluaran
      : AppData.kategoriPemasukan;

  void _simpan() {
    if (_namaCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Nama transaksi wajib diisi!');
      return;
    }
    if (_jumlahCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Jumlah wajib diisi!');
      return;
    }
    if (_kategori == null) {
      setState(() => _errorMsg = 'Pilih kategori terlebih dahulu!');
      return;
    }
    if (_rekening == null) {
      setState(() => _errorMsg = 'Pilih rekening terlebih dahulu!');
      return;
    }
    if (AppData.daftarRekening.isEmpty) {
      setState(() => _errorMsg = 'Belum ada rekening! Tambah rekening dulu.');
      return;
    }

    final jumlah = double.tryParse(_jumlahCtrl.text.replaceAll('.', '')) ?? 0;
    if (jumlah <= 0) {
      setState(() => _errorMsg = 'Jumlah harus lebih dari 0!');
      return;
    }

    // Update saldo rekening
    final rek = AppData.daftarRekening
        .where((r) => r.namaBank == _rekening)
        .firstOrNull;

    if (rek != null) {
      if (widget.editData != null) {
        // Rollback saldo lama
        final old = widget.editData!;
        final oldRek = AppData.daftarRekening
            .where((r) => r.namaBank == old.rekening)
            .firstOrNull;
        if (oldRek != null) {
          if (old.tipe == 'pemasukan') {
            oldRek.saldo -= old.jumlah;
          } else {
            oldRek.saldo += old.jumlah;
          }
        }
        // Update transaksi
        old.nama = _namaCtrl.text.trim();
        old.jumlah = jumlah;
        old.tipe = _tipe;
        old.kategori = _kategori!;
        old.rekening = _rekening!;
        old.catatan = _catatanCtrl.text.trim();
        old.tanggal = _tanggal;
      } else {
        // Tambah baru
        AppData.daftarTransaksi.add(TransaksiModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nama: _namaCtrl.text.trim(),
          jumlah: jumlah,
          tipe: _tipe,
          kategori: _kategori!,
          rekening: _rekening!,
          catatan: _catatanCtrl.text.trim(),
          tanggal: _tanggal,
        ));
      }
      // Terapkan saldo baru
      if (_tipe == 'pemasukan') {
        rek.saldo += jumlah;
      } else {
        rek.saldo -= jumlah;
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editData != null
            ? 'Transaksi berhasil diperbarui!'
            : 'Transaksi berhasil ditambahkan!'),
        backgroundColor: const Color(0xFF00C48C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pilihTanggal() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A6BFF)),
        ),
        child: child!,
      ),
    );
    if (dt != null) setState(() => _tanggal = dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6BFF),
        foregroundColor: Colors.white,
        title: Text(
            widget.editData != null ? 'Edit Transaksi' : 'Tambah Transaksi'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle tipe
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _tipe = 'pengeluaran';
                        _kategori = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tipe == 'pengeluaran'
                              ? Colors.redAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🔴 Pengeluaran',
                          style: TextStyle(
                            color: _tipe == 'pengeluaran'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _tipe = 'pemasukan';
                        _kategori = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tipe == 'pemasukan'
                              ? const Color(0xFF00C48C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🟢 Pemasukan',
                          style: TextStyle(
                            color: _tipe == 'pemasukan'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Error
            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMsg!,
                    style: const TextStyle(color: Colors.red)),
              ),

            _buildLabel('Nama Transaksi'),
            _buildField(
              controller: _namaCtrl,
              hint: 'Contoh: Makan Siang',
              icon: Icons.edit_note,
              onChanged: (_) => setState(() => _errorMsg = null),
            ),
            const SizedBox(height: 16),

            _buildLabel('Jumlah (Rp)'),
            TextField(
              controller: _jumlahCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _errorMsg = null),
              decoration: _inputDeco(
                  hint: '50000', icon: Icons.monetization_on_outlined),
            ),
            const SizedBox(height: 16),

            _buildLabel('Tanggal'),
            GestureDetector(
              onTap: _pilihTanggal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF1A6BFF), size: 20),
                    const SizedBox(width: 12),
                    Text(AppData.formatTanggal(_tanggal),
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel('Kategori'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kategoriList.map((k) {
                final sel = _kategori == k;
                return GestureDetector(
                  onTap: () => setState(() {
                    _kategori = k;
                    _errorMsg = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF1A6BFF)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      k,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _buildLabel('Rekening'),
            if (AppData.daftarRekening.isEmpty)
              const Text('Belum ada rekening. Tambah rekening dulu!',
                  style: TextStyle(color: Colors.red, fontSize: 13))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Pilih Rekening'),
                    value: _rekening,
                    items: AppData.daftarRekening
                        .map((r) => DropdownMenuItem(
                              value: r.namaBank,
                              child: Text(
                                  '${r.icon} ${r.namaBank} - ${AppData.formatRupiah(r.saldo)}'),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() {
                      _rekening = val;
                      _errorMsg = null;
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            _buildLabel('Catatan (Opsional)'),
            _buildField(
              controller: _catatanCtrl,
              hint: 'Tambahkan catatan...',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Text(
                  widget.editData != null ? 'Simpan Perubahan' : 'Simpan Transaksi',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: _inputDeco(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1A6BFF)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1A6BFF), width: 2),
      ),
    );
  }
}