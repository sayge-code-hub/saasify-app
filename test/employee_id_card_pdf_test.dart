import 'package:flutter_test/flutter_test.dart';
import 'package:sayge_app/features/hrms/domain/entities/employee.dart';
import 'package:sayge_app/features/modules/data/employee_id_card_pdf_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a two-page Sayge employee ID card PDF', () async {
    final employee = Employee(
      employeeId: 'TEST-ADITYA-001',
      employeeName: 'Aditya Rana',
      dateOfJoining: DateTime(2026, 11, 25),
      designation: 'Developer',
      department: 'Product Testing',
      annualCtc: 0,
      monthlyCtc: 0,
      pfApplicable: false,
      ptApplicable: false,
      medicalInsurance: 0,
      retentionAmount: 0,
      bankAccount: '',
      ifsc: '',
      pan: '',
      uan: '',
      contactNo: '+91 - 8788681499',
      isActive: true,
      location: 'Nagpur',
      grade: 'L22',
      clientId: 'mahindra-finance',
      client: 'Mahindra Finance',
    );

    final bytes = await EmployeeIdCardPdfBuilder.build(
      employee: employee,
      user: null,
      isSayge: true,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
