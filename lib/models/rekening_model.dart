// lib/models/rekening_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RekeningModel {
  String id;
  String namaBank;
  String nomorRekening;
  double saldo;

  /// Nilai icon: 'bank' | 'phone' | 'card' | 'atm' | 'cash'
  String icon;

  RekeningModel({
    required this.id,
    required this.namaBank,
    required this.nomorRekening,
    required this.saldo,
    required this.icon,
  });

  factory RekeningModel.fromMap(Map<String, dynamic> map) {
    return RekeningModel(
      id: map['id'] as String,
      namaBank: map['namaBank'] as String,
      nomorRekening: map['nomorRekening'] as String,
      saldo: (map['saldo'] as num).toDouble(),
      icon: map['icon'] as String? ?? 'bank',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaBank': namaBank,
      'nomorRekening': nomorRekening,
      'saldo': saldo,
      'icon': icon,
    };
  }

  RekeningModel copyWith({
    String? id,
    String? namaBank,
    String? nomorRekening,
    double? saldo,
    String? icon,
  }) {
    return RekeningModel(
      id: id ?? this.id,
      namaBank: namaBank ?? this.namaBank,
      nomorRekening: nomorRekening ?? this.nomorRekening,
      saldo: saldo ?? this.saldo,
      icon: icon ?? this.icon,
    );
  }
}
