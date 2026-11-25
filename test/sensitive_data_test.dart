import 'package:flutter_test/flutter_test.dart';
import 'package:sayge_app/core/security/sensitive_data.dart';

void main() {
  group('SensitiveData', () {
    test('masks all but the requested suffix', () {
      expect(SensitiveData.mask('1234567890'), '••••••7890');
    });

    test('accepts only the exact employee document prefix', () {
      expect(
        SensitiveData.isEmployeeDocumentPath(
          'documents/employee/EMP001/photo.png',
          'EMP001',
        ),
        isTrue,
      );
      expect(
        SensitiveData.isEmployeeDocumentPath(
          'documents/employee/EMP002/photo.png',
          'EMP001',
        ),
        isFalse,
      );
      expect(
        SensitiveData.isEmployeeDocumentPath(
          'documents/employee/EMP001/../secret.pdf',
          'EMP001',
        ),
        isFalse,
      );
    });
  });
}
