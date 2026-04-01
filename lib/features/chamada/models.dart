// lib/features/chamada/models.dart
// Entidades, enums e extensões — sem dependência de Flutter/UI

import 'package:flutter/material.dart';

// ─── Enum de status ───────────────────────────────────────────────────────────

enum AttendanceStatus { presente, atestado, falta, none }

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.presente:
        return 'P';
      case AttendanceStatus.atestado:
        return 'A';
      case AttendanceStatus.falta:
        return 'F';
      case AttendanceStatus.none:
        return '—';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AttendanceStatus.presente:
        return const Color(0xFF4CAF50);
      case AttendanceStatus.atestado:
        return const Color(0xFFFFC107);
      case AttendanceStatus.falta:
        return const Color(0xFFE53935);
      case AttendanceStatus.none:
        return Colors.grey.shade300;
    }
  }

  Color get textColor => Colors.white;

  AttendanceStatus get next {
    switch (this) {
      case AttendanceStatus.none:
        return AttendanceStatus.presente;
      case AttendanceStatus.presente:
        return AttendanceStatus.atestado;
      case AttendanceStatus.atestado:
        return AttendanceStatus.falta;
      case AttendanceStatus.falta:
        return AttendanceStatus.none;
    }
  }
}

// ─── Modelo do aluno ──────────────────────────────────────────────────────────

class StudentRecord {
  final int idAluno; // PK do Supabase
  final String name;

  /// data → lista de status (um por aula/turma no mesmo dia)
  final Map<DateTime, List<AttendanceStatus>> attendance;

  /// data → URL/nome do comprovante de atestado
  final Map<DateTime, String?> atestadoNome;

  StudentRecord({
    required this.idAluno,
    required this.name,
    required this.attendance,
    Map<DateTime, String?>? atestadoNome,
  }) : atestadoNome = atestadoNome ?? {};
}

// ─── Modelo de aula (registro da tabela `aulas`) ──────────────────────────────

class AulaRecord {
  final String id; // UUID
  final DateTime data;

  const AulaRecord({required this.id, required this.data});
}

// ─── Modelo de chamada (registro da tabela `chamadas`) ────────────────────────

class ChamadaRecord {
  final String id;
  final String aulaId;
  final int idAluno;
  final AttendanceStatus status;
  final String? comprovanteUrl;

  const ChamadaRecord({
    required this.id,
    required this.aulaId,
    required this.idAluno,
    required this.status,
    this.comprovanteUrl,
  });
}

// ─── Dados mockados (usados apenas para desenvolvimento sem Supabase) ─────────

List<DateTime> buildMockDatesForMonth(int ano, int mes) {
  final Map<int, List<int>> diasPorMes = {
    1: [4, 11, 18, 25],
    2: [1, 8, 15],
    3: [7, 14, 21],
    4: [4, 11, 18],
    5: [2, 9],
  };
  final dias = diasPorMes[mes] ?? [];
  return dias.map((d) => DateTime(ano, mes, d)).toList();
}

List<StudentRecord> buildMockStudents(List<DateTime> dates) {
  if (dates.isEmpty) {
    return [
      StudentRecord(idAluno: 1, name: 'João Silva', attendance: {}),
      StudentRecord(idAluno: 2, name: 'Maria Oliveira', attendance: {}),
      StudentRecord(idAluno: 3, name: 'Pedro Santos', attendance: {}),
      StudentRecord(idAluno: 4, name: 'Ana Costa', attendance: {}),
    ];
  }

  return [
    StudentRecord(
      idAluno: 1,
      name: 'João Silva',
      attendance: {for (final d in dates) d: [AttendanceStatus.presente]},
    ),
    StudentRecord(
      idAluno: 2,
      name: 'Maria Oliveira',
      attendance: {
        for (int i = 0; i < dates.length; i++)
          dates[i]: [
            i == dates.length - 1
                ? AttendanceStatus.atestado
                : AttendanceStatus.presente,
            AttendanceStatus.presente,
          ],
      },
    ),
    StudentRecord(
      idAluno: 3,
      name: 'Pedro Santos',
      attendance: {
        for (final d in dates)
          d: [AttendanceStatus.presente, AttendanceStatus.presente],
      },
    ),
    StudentRecord(
      idAluno: 4,
      name: 'Ana Costa',
      attendance: {
        for (int i = 0; i < dates.length; i++)
          dates[i]: [
            i >= 2 ? AttendanceStatus.falta : AttendanceStatus.presente,
            i >= 2 ? AttendanceStatus.falta : AttendanceStatus.presente,
          ],
      },
    ),
  ];
}
