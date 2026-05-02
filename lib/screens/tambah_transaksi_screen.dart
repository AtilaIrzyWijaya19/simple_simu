// lib/screens/tambah_transaksi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import '../models/rekening_model.dart';
import '../utils/app_helper.dart';

class TambahTransaksiScreen extends StatefulWidget {
  final TransaksiModel? editData;

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
  String? _rekeningDipilih; // namaBank
  DateTime _tanggal = DateTime.now();
  String? _errorMsg;
  bool _isLoading = false;

  List<RekeningModel> _semuaRekening = [];

  @override
  void initState() {
    super.initState();
    _loadRekening();
    if (widget.editData != null) {
      final d = widget.editData!;
      _tipe = d.tipe;
      _namaCtrl.text = d.nama;
      _jumlahCtrl.text = d.jumlah.toStringAsFixed(0);
      _catatanCtrl.text = d.catatan;
      _kategori = d.kategori;
      _rekeningDipilih = d.rekening;
      _tanggal = d.tanggal;
    }
  }

  Future<void> _loadRekening() async {
    final list = await FirebaseService.getRekening();
    if (mounted) setState(() => _semuaRekening = list);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _jumlahCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  List<String> get _kategoriList => _tipe == 'pengeluaran'
      ? AppHelper.kategoriPengeluaran
      : AppHelper.kategoriPemasukan;

  Future<void> _simpan() async {
    if (_namaCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Nama transaksi wajib diisi.');
      return;
    }
    if (_jumlahCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Jumlah wajib diisi.');
      return;
    }
    if (_kategori == null) {
      setState(() => _errorMsg = 'Pilih kategori terlebih dahulu.');
      return;
    }
    if (_rekeningDipilih == null) {
      setState(() => _errorMsg = 'Pilih rekening terlebih dahulu.');
      return;
    }

    final jumlah = double.tryParse(_jumlahCtrl.text.replaceAll('.', '')) ?? 0;
    if (jumlah <= 0) {
      setState(() => _errorMsg = 'Jumlah harus lebih dari 0.');
      return;
    }

    final rek =
        _semuaRekening.where((r) => r.namaBank == _rekeningDipilih).firstOrNull;
    if (rek == null) {
      setState(() => _errorMsg = 'Rekening tidak ditemukan.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      if (widget.editData != null) {
        // Mode edit
        final transaksiBaru = widget.editData!.copyWith(
          nama: _namaCtrl.text.trim(),
          jumlah: jumlah,
          tipe: _tipe,
          kategori: _kategori,
          rekening: _rekeningDipilih,
          catatan: _catatanCtrl.text.trim(),
          tanggal: _tanggal,
        );
        // Ambil daftar rekening terbaru sebelum batch update
        final rekTerbaru = await FirebaseService.getRekening();
        await FirebaseService.editTransaksi(
            widget.editData!, transaksiBaru, rekTerbaru);
      } else {
        // Mode tambah baru
        final transaksiModel = TransaksiModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nama: _namaCtrl.text.trim(),
          jumlah: jumlah,
          tipe: _tipe,
          kategori: _kategori!,
          rekening: _rekeningDipilih!,
          catatan: _catatanCtrl.text.trim(),
          tanggal: _tanggal,
        );
        await FirebaseService.tambahTransaksi(transaksiModel, rek);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editData != null
                ? 'Transaksi berhasil diperbarui.'
                : 'Transaksi berhasil ditambahkan.'),
            backgroundColor: const Color(0xFF00C48C),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: _tipe == 'pengeluaran'
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                color: _tipe == 'pengeluaran'
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: _tipe == 'pemasukan'
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                color: _tipe == 'pemasukan'
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child:
                    Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
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
                    Text(AppHelper.formatTanggal(_tanggal),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          sel ? const Color(0xFF1A6BFF) : Colors.grey.shade100,
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
            if (_semuaRekening.isEmpty)
              const Text('Belum ada rekening. Tambah rekening dulu.',
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
                    value: _rekeningDipilih,
                    items: _semuaRekening
                        .map((r) => DropdownMenuItem(
                              value: r.namaBank,
                              child: Text(
                                  '${r.namaBank} — ${AppHelper.formatRupiah(r.saldo)}'),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() {
                      _rekeningDipilih = val;
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
                onPressed: _isLoading ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.editData != null
                            ? 'Simpan Perubahan'
                            : 'Simpan Transaksi',
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A6BFF), width: 2),
      ),
    );
  }
}
