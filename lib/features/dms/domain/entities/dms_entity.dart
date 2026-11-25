/// Owner type for documents in the DMS.
enum DmsEntityType {
  employee,
  client,
  vendor;

  String get label {
    switch (this) {
      case DmsEntityType.employee:
        return 'Employees';
      case DmsEntityType.client:
        return 'Clients';
      case DmsEntityType.vendor:
        return 'Vendors';
    }
  }

  String get singular {
    switch (this) {
      case DmsEntityType.employee:
        return 'Employee';
      case DmsEntityType.client:
        return 'Client';
      case DmsEntityType.vendor:
        return 'Vendor';
    }
  }

  /// Value stored in `documents.entity_type` / `dms_entities.entity_type`.
  String get storageValue {
    switch (this) {
      case DmsEntityType.employee:
        return 'employee';
      case DmsEntityType.client:
        // Historical DB value is "company".
        return 'company';
      case DmsEntityType.vendor:
        return 'vendor';
    }
  }

  static DmsEntityType fromStorage(String value) {
    switch (value.toLowerCase()) {
      case 'employee':
        return DmsEntityType.employee;
      case 'company':
      case 'client':
        return DmsEntityType.client;
      case 'vendor':
        return DmsEntityType.vendor;
      default:
        return DmsEntityType.employee;
    }
  }
}

/// A browsable DMS owner (employee, client, or vendor).
class DmsEntity {
  const DmsEntity({
    required this.id,
    required this.name,
    required this.type,
    this.subtitle = '',
    this.imageUrl,
  });

  final String id;
  final String name;
  final DmsEntityType type;
  final String subtitle;

  /// Optional profile/logo image URL (employees use photo_path).
  final String? imageUrl;
}

/// Document categories used when attaching / grouping files.
abstract final class DmsDocumentCategories {
  static const List<String> all = [
    'Identity',
    'Tax',
    'Contracts',
    'Compliance',
    'Payroll',
    'General',
  ];

  static const String fallback = 'General';
}
