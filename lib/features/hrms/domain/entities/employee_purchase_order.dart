import 'package:equatable/equatable.dart';

class EmployeePurchaseOrder extends Equatable {
  const EmployeePurchaseOrder({
    required this.id,
    required this.employeeId,
    required this.poNumber,
    required this.startDate,
    required this.endDate,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.storagePath,
  });

  final String id;
  final String employeeId;
  final String poNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String storagePath;

  bool get hasFile => storagePath.trim().isNotEmpty;

  int get daysUntilEnd {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(day).inDays;
  }

  bool get isExpired => daysUntilEnd < 0;

  /// POs ending within the next month should be renewed before invoicing.
  bool get needsRenewal => !isExpired && daysUntilEnd <= 30;

  /// Inclusive coverage: invoice/service date must fall in [startDate, endDate].
  bool coversDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    poNumber,
    startDate,
    endDate,
    fileName,
    storagePath,
  ];
}
