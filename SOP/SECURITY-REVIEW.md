# HRMS Module - Security Review & Vulnerability Assessment

**Date:** November 25, 2026  
**Reviewer:** Security Review Agent  
**Module:** Human Resource Management System (HRMS)  
**Status:** ⚠️ **VULNERABILITIES FOUND - ACTION REQUIRED**  
**Overall Security Score:** 6.5/10

---

## Executive Summary

A comprehensive security review of the HRMS module identified **7 vulnerabilities** across input validation, data access control, and business logic. While the overall architecture has solid security foundations (RLS policies, role-based access, secure storage), the module has significant **input validation gaps** that could allow data integrity issues and exploitation.

**Critical Finding:** 1 path traversal vulnerability that could allow unauthorized document access.

**Risk Level:** ⚠️ **HIGH** - Requires immediate remediation before production deployment or in next sprint.

---

## Vulnerability Summary Table

| # | Severity | File | Lines | Vulnerability | Confidence | CVSS |
|---|----------|------|-------|---------------|------------|------|
| 1 | 🟠 **HIGH** | `lib/features/hrms/data/datasources/employee_remote_datasource.dart` | 349-357 | Path traversal in document selection - unauthorized document access | 8/10 | 7.5 |
| 2 | 🟡 **MEDIUM** | `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart` | 125 | PAN field has NO format validation - accepts any string | 8/10 | 5.3 |
| 3 | 🟡 **MEDIUM** | `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart` | 94 | Bank Account has NO format/length validation | 7/10 | 5.1 |
| 4 | 🟡 **MEDIUM** | `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart` | 108-115 | Negative salary values allowed (annualCtc, monthlyCtc, monthlyRate) | 8/10 | 5.4 |
| 5 | 🟡 **MEDIUM** | `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart` | 94 | UAN field has NO format validation - no 12-digit check | 7/10 | 4.9 |
| 6 | 🟡 **MEDIUM** | `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart` | 124 | Personal Email NOT validated for format | 7/10 | 4.8 |
| 7 | 🟡 **MEDIUM** | `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart` | 122 | Contact Phone has NO format validation - accepts any string | 7/10 | 4.7 |

---

## Detailed Vulnerability Analysis

### 🟠 CRITICAL/HIGH SEVERITY ISSUES

#### Issue #1: Path Traversal Vulnerability in Document Access
**Severity:** 🟠 **HIGH**  
**CVSS Score:** 7.5 (High)  
**Confidence:** 8/10  
**Location:** `lib/features/hrms/data/datasources/employee_remote_datasource.dart`, lines 349-357

**Problem:**
The `setEmployeePhotoFromDocument()` function accepts an untrusted `storagePath` parameter from the client and uses it directly to access files from the storage bucket without validating path ownership.

```dart
Future<void> setEmployeePhotoFromDocument(
  String employeeId,
  String storagePath,  // ⚠️ UNTRUSTED INPUT
) async {
  final path = storagePath.trim();
  if (path.isEmpty) return;  // ⚠️ ONLY EMPTY CHECK
  
  // Uses path directly without ownership validation
  final bytes = await AppStorageUrls.bucketForPath(path).download(path);
  
  // Then uploads to employee's avatar bucket
  await _uploadEmployeePhoto(employeeId, bytes);
}
```

**Exploitation Scenario:**
1. A malicious staff member calls this function with `storagePath = "../../other-employee/documents/sensitive-contract.pdf"`
2. The function downloads files from other employees' document storage
3. The file is then uploaded to the attacker's employee record or could be exfiltrated
4. No audit trail of which file was accessed

**Impact:**
- 📊 **Confidentiality:** HIGH - Access to other employees' sensitive documents
- 🔧 **Integrity:** MEDIUM - Could modify employee records with unauthorized documents
- 🛑 **Availability:** LOW - No direct DoS impact

**Root Cause:**
- No path validation to ensure storagePath belongs to the intended employee
- Only trim() and empty check performed
- Assumption that RLS policy alone provides security (insufficient for client-side path parameter)

**Proof of Concept:**
```
1. Admin/Staff creates two employees: EMP001 and EMP002
2. EMP002 uploads personal document to storage
3. Attacker (staff) calls setEmployeePhotoFromDocument("EMP001", "../emp0002/documents/contract.pdf")
4. EMP002's document is now accessible via EMP001's avatar
```

**Recommended Fix:**
```dart
Future<void> setEmployeePhotoFromDocument(
  String employeeId,
  String storagePath,
) async {
  final path = storagePath.trim();
  if (path.isEmpty) return;
  
  // ✅ VALIDATE path belongs to this employee
  final expectedPrefix = '$employeeId/'; // or 'documents/$employeeId/'
  if (!path.startsWith(expectedPrefix)) {
    throw SecurityException('Path traversal detected: Path must start with employee ID');
  }
  
  // ✅ SANITIZE path - prevent directory traversal
  if (path.contains('..') || path.contains('//')) {
    throw SecurityException('Invalid path characters detected');
  }
  
  final bytes = await AppStorageUrls.bucketForPath(path).download(path);
  await _uploadEmployeePhoto(employeeId, bytes);
}
```

**Timeline:** 🚨 **IMMEDIATE - Fix before next deployment**

---

### 🟡 MEDIUM SEVERITY ISSUES

#### Issue #2: PAN Field - No Format Validation
**Severity:** 🟡 **MEDIUM**  
**CVSS Score:** 5.3  
**Confidence:** 8/10  
**Location:** `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart`, line 125

**Problem:**
PAN (Permanent Account Number) is validated only for being non-empty, not for the correct format. Valid Indian PANs have a strict 10-character format: `AAAAA9999A` (5 letters, 4 numbers, 1 letter).

```dart
if (pan.trim().isEmpty) return 'PAN is required';
// ⚠️ No format validation - accepts "INVALID", "123", "PAN12345678900000" etc.
```

**Impact:**
- 📊 **Data Quality:** HIGH - Invalid PAN data stored in database
- 🔧 **Downstream Systems:** MEDIUM - If PAN used in tax reports, GST filings, or government APIs, will fail or be rejected
- 🛡️ **Security:** LOW - If PAN ever used in dynamic SQL queries, malformed PAN could bypass security controls

**Real-World Scenario:**
- HR staff accidentally enters "PAN123" for an employee
- Later, an automated tax report generator uses this PAN in a database query
- If not properly parameterized, could lead to SQL injection
- Tax filing fails, creating compliance issues

**Recommended Fix:**
```dart
// Validate PAN format: AAAAA9999A (5 letters, 4 numbers, 1 letter)
final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
if (!panRegex.hasMatch(pan.trim())) {
  return 'PAN must be in format: AAAAA9999A (e.g., AAAPA1234A)';
}
```

**Timeline:** 📅 **HIGH - Fix in next sprint**

---

#### Issue #3: Bank Account Number - No Format Validation
**Severity:** 🟡 **MEDIUM**  
**CVSS Score:** 5.1  
**Confidence:** 7/10  
**Location:** `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart`, line 94

**Problem:**
Bank account numbers are accepted as free-form strings with only empty check. Indian bank accounts are typically 10-18 digits but no validation is performed.

**Impact:**
- 💳 **Banking Integration:** HIGH - Invalid account numbers will cause fund transfer failures
- 📊 **Data Quality:** HIGH - Corrupt financial data in system
- 🔧 **Payroll Systems:** MEDIUM - Payroll processing will fail or fund transfers will bounce

**Example Impact:**
- Employee added with bank account "ABC123XYZ"
- Payroll system tries to transfer salary
- Bank API rejects with malformed account error
- Payment fails silently, employee doesn't get paid
- No audit trail of why transfer failed

**Recommended Fix:**
```dart
// Validate bank account for Indian accounts (typically 10-18 digits)
final bankAccountRegex = RegExp(r'^[0-9]{10,18}$');
if (!bankAccountRegex.hasMatch(bankAccount.trim())) {
  return 'Bank account must be 10-18 digits';
}
```

**Timeline:** 📅 **HIGH - Fix in next sprint**

---

#### Issue #4: Compensation Fields - Negative Values Allowed
**Severity:** 🟡 **MEDIUM**  
**CVSS Score:** 5.4  
**Confidence:** 8/10  
**Location:** `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart`, lines 108-115

**Problem:**
Compensation fields (annualCtc, monthlyCtc, monthlyRate) validate that they parse as `double` but NOT that they are positive. This allows negative salaries to be created.

```dart
if (annualCtc.isEmpty || double.tryParse(annualCtc) == null) {
  return 'Annual CTC is required';
}
// ⚠️ Accepts "-50000" or "-0.01" etc.
```

**Impact:**
- 💰 **Financial Integrity:** HIGH - Negative salaries corrupt financial records
- 📊 **Payroll Calculations:** HIGH - Incorrect payroll processing
- 🔧 **Accounting Systems:** MEDIUM - If exported to accounting software, creates invalid GL entries
- 🛡️ **Compliance:** MEDIUM - Tax filings and financial reports become invalid

**Exploitation Scenario:**
1. HR staff (accidentally or maliciously) creates employee with salary "-100000"
2. Payroll system calculates: Actual Pay = Base Pay + Negative = very low or owed
3. Financial reports show negative total payroll
4. Tax filings become invalid
5. No audit trail of who created the malformed record

**Recommended Fix:**
```dart
final ctcDouble = double.tryParse(annualCtc);
if (ctcDouble == null || ctcDouble < 0) {
  return 'Annual CTC must be a positive number';
}
if (ctcDouble > 10000000) { // Business rule: max 1 crore
  return 'Annual CTC exceeds maximum limit';
}
```

**Timeline:** 📅 **IMMEDIATE - Fix in next sprint**

---

#### Issue #5: UAN Field - No Format Validation
**Severity:** 🟡 **MEDIUM**  
**CVSS Score:** 4.9  
**Confidence:** 7/10  
**Location:** `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart`, line 94

**Problem:**
UAN (Unique Account Number) is a 12-digit government ID but is stored as string with no format checks.

**Impact:**
- 📊 **Data Quality:** HIGH - Invalid UAN rejected by ESIC/EPF systems
- 🔧 **Compliance:** MEDIUM - EPF/ESIC integration will fail
- 🛡️ **Government API:** MEDIUM - Invalid UAN will fail when filing with EPFO

**Recommended Fix:**
```dart
// UAN must be exactly 12 digits
final uanRegex = RegExp(r'^[0-9]{12}$');
if (!uanRegex.hasMatch(uan.trim())) {
  return 'UAN must be 12 digits (e.g., 100123456789)';
}
```

**Timeline:** 📅 **HIGH - Fix in next sprint**

---

#### Issue #6: Personal Email - No Format Validation
**Severity:** 🟡 **MEDIUM**  
**CVSS Score:** 4.8  
**Confidence:** 7/10  
**Location:** `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart`, line 124

**Problem:**
Personal email field accepts any string with no email format validation. Email field keyboard type only suggests but doesn't enforce format.

**Impact:**
- 📧 **Email Communications:** HIGH - Invalid emails will bounce when sending notifications
- 🔧 **User Onboarding:** MEDIUM - Automated welcome emails will fail silently
- 🛡️ **Account Recovery:** MEDIUM - If email used for password reset, user can't recover account

**Recommended Fix:**
```dart
// Validate email format using regex or email_validator package
final emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
);
if (!emailRegex.hasMatch(personalEmail.trim())) {
  return 'Please enter a valid email address';
}
```

**Timeline:** 📅 **MEDIUM - Fix in next sprint**

---

#### Issue #7: Contact Phone Number - No Format Validation
**Severity:** 🟡 **MEDIUM**  
**CVSS Score:** 4.7  
**Confidence:** 7/10  
**Location:** `lib/features/hrms/presentation/bloc/add_employee/add_employee_state.dart`, line 122

**Problem:**
Contact phone field validates only implicit empty check via keyboard type. Accepts any string with no format validation for Indian phone numbers.

**Impact:**
- 📱 **SMS Notifications:** HIGH - Invalid numbers will fail silently
- 🔧 **Emergency Contact:** MEDIUM - Can't reach employee in emergencies
- 🛡️ **OTP Delivery:** MEDIUM - If used for 2FA, authentication will fail

**Recommended Fix:**
```dart
// Validate Indian phone number: 10 digits starting with 6-9
final phoneRegex = RegExp(r'^[6-9][0-9]{9}$');
if (!phoneRegex.hasMatch(contactNo.trim().replaceAll(RegExp(r'[^\d]'), ''))) {
  return 'Please enter a valid 10-digit phone number';
}
```

**Timeline:** 📅 **MEDIUM - Fix in next sprint**

---

## Positive Security Findings ✅

The HRMS module demonstrates several security best practices:

### 1. Row-Level Security (RLS) Policies
✅ **Well Implemented**
- Employee data properly restricted: employees can only view their own records
- Compensation data hidden from non-staff users
- Purchase orders restricted to staff access
- Proper role-based filtering in RLS policies

### 2. Field-Level Security Guard
✅ **Properly Configured**
- `employee_self_update_guard()` trigger restricts employees to only update safe fields
- Prevents employees from modifying:
  - Compensation data
  - Designation
  - Date of exit
  - Employment status
- Allows employees to update:
  - Contact information
  - Profile photo
  - Personal details

### 3. Photo Upload Security
✅ **Well Sanitized**
- Filename sanitization using regex: `[^\w.\-]+` → `_`
- Prevents directory traversal in filenames
- Proper file type validation (image MIME types)
- Size limits enforced

### 4. Storage Access Control
✅ **Proper Authorization**
- Private storage buckets for documents and employee POs
- Signed URLs required for access
- Staff-only access enforced at multiple layers (app + database)
- Proper bucket isolation (employees-avatars vs documents vs employee-pos)

### 5. Sensitive Data Masking
✅ **Correctly Implemented**
- Monthly rate hidden from employees' self-view (line 71 in remote datasource)
- Bank account details not exposed to unauthorized users
- Compensation data restricted by RLS policy
- PAN/UAN not shown in employee dashboard

### 6. Data Integrity Features
✅ **Proper Constraints**
- Status management with flags (is_active, is_draft, date_of_exit)
- Soft delete support preserves audit trail
- Date validations in PO (end_date >= start_date)
- Proper CASCADE delete handling

### 7. Parameterized Database Queries
✅ **Supabase Handles Parameterization**
- No SQL injection risk with Supabase REST API
- Proper parameter binding through Dart SDK
- RLS policies provide additional protection layer

---

## Security Architecture Assessment

| Component | Rating | Status | Notes |
|-----------|--------|--------|-------|
| Authentication | 9/10 | ✅ Secure | Proper role-based access control |
| Authorization (RLS) | 9/10 | ✅ Secure | Well-designed policies, field-level guards |
| Input Validation | 3/10 | ⚠️ **CRITICAL GAP** | Multiple format validations missing |
| Data Encryption (Transit) | 9/10 | ✅ Secure | HTTPS/TLS enforced by Supabase |
| Data Encryption (Rest) | 8/10 | ✅ Good | Supabase encryption, sensitive fields in private storage |
| Sensitive Data Masking | 9/10 | ✅ Secure | Proper field restrictions |
| File Upload Security | 7/10 | ⚠️ Has Issues | Filename sanitized, but path traversal possible |
| Error Handling | 8/10 | ✅ Good | Proper error messages without data leakage |
| Audit Logging | 7/10 | ⚠️ Limited | Created_at/updated_at present, but no change audit trail |
| Dependency Security | 8/10 | ✅ Good | Using current Flutter/Dart versions |
| **Overall Score** | **6.5/10** | ⚠️ **MEDIUM** | Input validation gaps require immediate attention |

---

## Remediation Roadmap

### 🚨 IMMEDIATE (This Sprint)
- [ ] Fix path traversal vulnerability in `setEmployeePhotoFromDocument()`
- [ ] Add positive validation for compensation amounts (no negative values)
- [ ] Add format validation for PAN field

**Effort:** 2-3 hours  
**Risk:** Very Low (localized fixes)  
**Priority:** CRITICAL

### 📅 HIGH (Next Sprint)
- [ ] Add format validation for bank account numbers
- [ ] Add format validation for UAN (12 digits)
- [ ] Add email format validation for personal_email
- [ ] Add phone format validation for contactNo
- [ ] Add input formatters to UI for better UX feedback

**Effort:** 4-6 hours  
**Risk:** Low (backward compatible)  
**Priority:** HIGH

### 📌 MEDIUM (Future Sprints)
- [ ] Implement comprehensive audit logging for sensitive field changes
- [ ] Add rate limiting to prevent brute force on employee creation
- [ ] Consider encryption at rest for most sensitive fields (PAN, bank account, Aadhaar)
- [ ] Add data masking in logs for sensitive employee information
- [ ] Implement automated security tests in CI/CD pipeline

**Effort:** 1-2 days  
**Risk:** Medium  
**Priority:** MEDIUM

---

## Compliance & Privacy Assessment

### GDPR Compliance
| Requirement | Status | Notes |
|-------------|--------|-------|
| Data Processing Agreement | ✅ Assumed | Supabase handles DPA |
| Right to Delete | ⚠️ Partial | Soft delete supported, full purge not tested |
| Audit Trails | ⚠️ Limited | Timestamps present, detailed audit missing |
| Consent Management | ✅ Assumed | Should be at org level |

### India-Specific Compliance (DPDP Act, Labor Laws)
| Requirement | Status | Notes |
|-------------|--------|-------|
| PII Protection | ⚠️ Partial | PAN/Aadhaar not encrypted at rest |
| Payroll Accuracy | ⚠️ at Risk | Negative salaries can corrupt payroll |
| Employee Records | ✅ Good | Proper status tracking and history |
| EPF/ESIC Integration | ⚠️ at Risk | UAN format validation missing |
| Tax Compliance | ⚠️ at Risk | PAN format validation missing |

---

## Testing Recommendations

### Security Test Cases to Add

```dart
// Test: Path traversal prevention
test('setEmployeePhotoFromDocument rejects path traversal', () {
  expect(
    () => datasource.setEmployeePhotoFromDocument('EMP001', '../../other/document.pdf'),
    throwsA(isA<SecurityException>()),
  );
});

// Test: Negative salary rejection
test('addEmployee rejects negative CTC', () {
  final employee = EmployeeModel(annualCtc: -50000);
  expect(employee.validate(), contains('positive'));
});

// Test: PAN format validation
test('addEmployee rejects invalid PAN format', () {
  final employee = EmployeeModel(pan: 'INVALID');
  expect(employee.validate(), contains('PAN'));
});

// Test: UAN format validation
test('addEmployee rejects invalid UAN format', () {
  final employee = EmployeeModel(uan: '123');
  expect(employee.validate(), contains('UAN'));
});

// Test: Email format validation
test('addEmployee rejects invalid email', () {
  final employee = EmployeeModel(personalEmail: 'not-an-email');
  expect(employee.validate(), contains('email'));
});

// Test: Phone format validation
test('addEmployee rejects invalid phone', () {
  final employee = EmployeeModel(contactNo: 'ABC123');
  expect(employee.validate(), contains('phone'));
});
```

---

## Deployment Checklist

Before deploying HRMS to production, ensure:

- [ ] Path traversal vulnerability fixed and tested
- [ ] All format validations implemented for PAN, UAN, email, phone, bank account
- [ ] Compensation amount validation (no negative values) implemented
- [ ] Security tests added to CI/CD pipeline
- [ ] Code review completed by security-aware developer
- [ ] Penetration testing for file upload functionality
- [ ] Database RLS policies verified in production environment
- [ ] Sensitive data masking verified with real employee data
- [ ] Audit logging test with employee data modifications
- [ ] User acceptance testing for validation error messages

---

## References & Standards

- **OWASP Top 10 2021:** A01:2021 Broken Access Control, A03:2021 Injection, A07:2021 Identification and Authentication Failures
- **CWE:** CWE-22 (Path Traversal), CWE-20 (Improper Input Validation)
- **CVSS v3.1:** Used for scoring vulnerabilities
- **Indian Compliance:** DPDP Act 2023, PII Protection Rules, Labor Code 2020
- **Banking Standards:** NPCI guidelines for bank account validation

---

## Conclusion

The HRMS module has a solid security foundation with well-implemented RLS policies, role-based access control, and sensitive data protection. However, **input validation gaps present a significant risk** that must be addressed before production deployment.

**Recommendation:** 🚨 **Fix critical path traversal and high-priority format validations in the next sprint.** The module is otherwise production-ready with comprehensive architecture and proper authorization controls.

---

**Security Review Report**  
**Status:** ⚠️ **ACTION REQUIRED**  
**Signed:** Security Review Agent  
**Date:** November 25, 2026

For questions or clarifications, refer to the developer guide or contact the security team.
