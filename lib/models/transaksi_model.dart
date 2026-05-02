// lib/models/transaksi_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  String id;
  String nama;
  double jumlah;
  String tipe; // 'pemasukan' | 'pengeluaran'
  String kategori;
  String rekening;
  String catatan;
  DateTime tanggal;

  TransaksiModel({
    required this.id,
    required this.nama,
    required this.jumlah,
    required this.tipe,
    required this.kategori,
    required this.rekening,
    this.catatan = '',
    required this.tanggal,
  });

  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      id: map['id'] as String,
      nama: map['nama'] as String,
      jumlah: (map['jumlah'] as num).toDouble(),
      tipe: map['tipe'] as String,
      kategori: map['kategori'] as String,
      rekening: map['rekening'] as String,
      catatan: map['catatan'] as String? ?? '',
      tanggal: map['tanggal'] is Timestamp
          ? (map['tanggal'] as Timestamp).toDate()
          : DateTime.parse(map['tanggal'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'jumlah': jumlah,
      'tipe': tipe,
      'kategori': kategori,
      'rekening': rekening,
      'catatan': catatan,
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }

  TransaksiModel copyWith({
    String? id,
    String? nama,
    double? jumlah,
    String? tipe,
    String? kategori,
    String? rekening,
    String? catatan,
    DateTime? tanggal,
  }) {
    return TransaksiModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      jumlah: jumlah ?? this.jumlah,
      tipe: tipe ?? this.tipe,
      kategori: kategori ?? this.kategori,
      rekening: rekening ?? this.rekening,
      catatan: catatan ?? this.catatan,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}
