// lib/services/firebase_service.dart
// SiMu - Sistem Keuangan Mahasiswa
// Kelompok 6 - Universitas Negeri Gorontalo

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaksi_model.dart';
import '../models/rekening_model.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;
  static String get namaUser => _auth.currentUser?.displayName ?? 'Pengguna';
  static String get emailUser => _auth.currentUser?.email ?? '';

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<UserCredential> register(
    String nama,
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await cred.user?.updateDisplayName(nama.trim());

    // Paksa refresh token agar Firestore Security Rules
    // langsung mengenali user baru — tanpa ini bisa PERMISSION_DENIED
    await cred.user?.getIdToken(true);

    // Inisialisasi data default rekening untuk user baru
    await _initDefaultRekening(cred.user!.uid);
    return cred;
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── INISIALISASI DATA DEFAULT ─────────────────────────────────────────────

  static Future<void> _initDefaultRekening(String uid) async {
    final col = _db.collection('users').doc(uid).collection('rekening');
    final snap = await col.limit(1).get();
    if (snap.docs.isNotEmpty) return; // sudah ada data, skip

    final batch = _db.batch();
    batch.set(col.doc('r1'), {
      'id': 'r1',
      'namaBank': 'BRI',
      'nomorRekening': '1234-5678-9012',
      'saldo': 500000.0,
      'icon': 'bank',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(col.doc('r2'), {
      'id': 'r2',
      'namaBank': 'Dana',
      'nomorRekening': '0812-3456-7890',
      'saldo': 150000.0,
      'icon': 'phone',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ─── REKENING ──────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _rekeningCol() {
    return _db.collection('users').doc(uid).collection('rekening');
  }

  static Stream<List<RekeningModel>> streamRekening() {
    return _rekeningCol()
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RekeningModel.fromMap(d.data())).toList());
  }

  static Future<List<RekeningModel>> getRekening() async {
    final snap =
        await _rekeningCol().orderBy('createdAt', descending: false).get();
    return snap.docs.map((d) => RekeningModel.fromMap(d.data())).toList();
  }

  static Future<void> tambahRekening(RekeningModel rek) async {
    await _rekeningCol().doc(rek.id).set({
      ...rek.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSaldoRekening(String id, double saldoBaru) async {
    await _rekeningCol().doc(id).update({'saldo': saldoBaru});
  }

  static Future<void> hapusRekening(String id) async {
    await _rekeningCol().doc(id).delete();
  }

  // ─── TRANSAKSI ─────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _transaksiCol() {
    return _db.collection('users').doc(uid).collection('transaksi');
  }

  static Stream<List<TransaksiModel>> streamTransaksi() {
    return _transaksiCol()
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransaksiModel.fromMap(d.data())).toList());
  }

  /// Tambah transaksi baru dan update saldo rekening secara atomik
  static Future<void> tambahTransaksi(
    TransaksiModel t,
    RekeningModel rek,
  ) async {
    final batch = _db.batch();

    // Simpan transaksi
    batch.set(_transaksiCol().doc(t.id), {
      ...t.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update saldo rekening
    final saldoBaru =
        t.tipe == 'pemasukan' ? rek.saldo + t.jumlah : rek.saldo - t.jumlah;
    batch.update(_rekeningCol().doc(rek.id), {'saldo': saldoBaru});

    await batch.commit();
  }

  /// Edit transaksi: rollback saldo lama, terapkan saldo baru, update dokumen
  static Future<void> editTransaksi(
    TransaksiModel transaksiLama,
    TransaksiModel transaksiBaru,
    List<RekeningModel> semuaRekening,
  ) async {
    final batch = _db.batch();

    // Rollback saldo rekening lama
    final rekLama = semuaRekening
        .where((r) => r.namaBank == transaksiLama.rekening)
        .firstOrNull;
    if (rekLama != null) {
      final saldoRollback = transaksiLama.tipe == 'pemasukan'
          ? rekLama.saldo - transaksiLama.jumlah
          : rekLama.saldo + transaksiLama.jumlah;
      batch.update(_rekeningCol().doc(rekLama.id), {'saldo': saldoRollback});
      rekLama.saldo = saldoRollback; // update lokal untuk kalkulasi berikut
    }

    // Terapkan saldo rekening baru
    final rekBaru = semuaRekening
        .where((r) => r.namaBank == transaksiBaru.rekening)
        .firstOrNull;
    if (rekBaru != null) {
      final saldoBaru = transaksiBaru.tipe == 'pemasukan'
          ? rekBaru.saldo + transaksiBaru.jumlah
          : rekBaru.saldo - transaksiBaru.jumlah;
      batch.update(_rekeningCol().doc(rekBaru.id), {'saldo': saldoBaru});
    }

    // Update dokumen transaksi
    batch.set(_transaksiCol().doc(transaksiBaru.id), {
      ...transaksiBaru.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Hapus transaksi dan rollback saldo rekening terkait
  static Future<void> hapusTransaksi(
    TransaksiModel t,
    List<RekeningModel> semuaRekening,
  ) async {
    final batch = _db.batch();

    // Hapus dokumen transaksi
    batch.delete(_transaksiCol().doc(t.id));

    // Rollback saldo
    final rek =
        semuaRekening.where((r) => r.namaBank == t.rekening).firstOrNull;
    if (rek != null) {
      final saldoBaru =
          t.tipe == 'pemasukan' ? rek.saldo - t.jumlah : rek.saldo + t.jumlah;
      batch.update(_rekeningCol().doc(rek.id), {'saldo': saldoBaru});
    }

    await batch.commit();
  }
}