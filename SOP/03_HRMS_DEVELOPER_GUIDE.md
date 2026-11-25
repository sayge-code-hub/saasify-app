# HRMS Module - Developer Guide & API Reference

## Table of Contents
1. Getting Started
2. Module Architecture Deep Dive
3. Adding New Features
4. API Reference
5. Database Queries
6. Testing Guide
7. Troubleshooting
8. Performance Optimization

---

## 1. Getting Started

### 1.1 Module Dependencies

**External Packages:**
```yaml
flutter_bloc: ^9.1.1        # State management
equatable: ^3.0.0           # Value equality
dartz: ^0.10.1              # Functional programming (Either)
get_it: ^9.3.0              # Dependency injection
supabase_flutter: ^2.18.0   # Backend
```

### 1.2 Setup Instructions

**Register in injection_container.dart:**
```dart
// Repositories
sl.registerSingleton<EmployeeRepository>(
  EmployeeRepositoryImpl(remoteDataSource: sl()),
);

// Usecases
sl.registerSingleton<GetEmployeesUseCase>(
  GetEmployeesUseCase(sl()),
);
sl.registerSingleton<AddEmployeeUseCase>(
  AddEmployeeUseCase(sl()),
);

// BLoCs
sl.registerSingleton<EmployeesBloc>(
  EmployeesBloc(getEmployeesUseCase: sl()),
);
sl.registerSingleton<AddEmployeeBloc>(
  AddEmployeeBloc(
    addEmployeeUseCase: sl(),
    updateEmployeeUseCase: sl(),
    getClientsUseCase: sl(),
    getEmployeesUseCase: sl(),
  ),
);
```

### 1.3 Data Flow Diagram

```
UI (Page/Widget)
    ↓
BLoC (State Management)
    ↓
Usecase (Business Logic)
    ↓
Repository (Data Abstraction)
    ↓
Remote DataSource (Supabase API)
    ↓
PostgreSQL Database
    ↓
RLS Policies (Security)
```

---

## 2. Module Architecture Deep Dive

### 2.1 Data Layer

#### Remote DataSource
```dart
// lib/features/hrms/data/datasources/employee_remote_datasource.dart

abstract class EmployeeRemoteDataSource {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel> addEmployee(EmployeeModel employee);
  Future<EmployeeModel> updateEmployee(EmployeeModel employee);
  Future<void> deleteEmployee(String employeeId);
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  EmployeeRemoteDataSourceImpl(this.supabase);
  
  final SupabaseClient supabase;

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await supabase
        .from('employees')
        .select('*')
        .order('employee_name', ascending: true);
      
      return (response as List)
        .map((e) => EmployeeModel.fromJson(e))
        .toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<EmployeeModel> addEmployee(EmployeeModel employee) async {
    try {
      final response = await supabase
        .from('employees')
        .insert(employee.toJson())
        .select()
        .single();
      
      return EmployeeModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw DuplicateEmployeeIdException();
      }
      throw ServerException();
    }
  }
}
```

**Key Methods:**
- `getEmployees()`: Fetch all employees (RLS applies)
- `addEmployee()`: Create new employee
- `updateEmployee()`: Update existing employee
- `deleteEmployee()`: Hard delete (usually via soft delete flag)
- `uploadEmployeePhoto()`: Upload to storage bucket
- `deleteEmployeePhoto()`: Remove photo from storage

#### Models

```dart
// lib/features/hrms/data/models/employee_model.dart

class EmployeeModel extends Employee {
  const EmployeeModel({
    required String employeeId,
    required String employeeName,
    // ... all fields from Employee
  }) : super(
    employeeId: employeeId,
    employeeName: employeeName,
    // ...
  );

  // JSON serialization
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      dateOfJoining: DateTime.parse(json['date_of_joining']),
      // ... parse all fields
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date_of_joining': dateOfJoining.toIso8601String(),
      // ... all fields
    };
  }
}
```

**Key Points:**
- Extends Employee entity
- Handles JSON conversion (Supabase ↔ Dart)
- Proper date parsing (ISO8601 format)
- Numeric precision maintained

#### Repository Implementation

```dart
// lib/features/hrms/data/repositories/employee_repository_impl.dart

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl({required this.remoteDataSource});

  final EmployeeRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<Employee>>> getEmployees() async {
    try {
      final employees = await remoteDataSource.getEmployees();
      return Right(employees);
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Employee>> addEmployee(Employee employee) async {
    try {
      final model = EmployeeModel(/* ... */);
      final result = await remoteDataSource.addEmployee(model);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

**Purpose:**
- Wraps datasource exceptions
- Maps domain exceptions to failures
- Implements repository interface

### 2.2 Domain Layer

#### Entities

```dart
// lib/features/hrms/domain/entities/employee.dart

class Employee extends Equatable {
  const Employee({
    required this.employeeId,
    required this.employeeName,
    // ... 50+ fields
  });

  final String employeeId;
  final String employeeName;
  // ... all fields

  Employee copyWith({
    String? employeeId,
    String? employeeName,
    // ... named parameters
    bool clearDateOfExit = false,
  }) {
    return Employee(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      // ... with nullable handling
      dateOfExit: clearDateOfExit ? null : this.dateOfExit,
    );
  }

  @override
  List<Object?> get props => [
    employeeId,
    employeeName,
    // ... all fields
  ];
}
```

**Features:**
- Immutability (all final)
- CopyWith for state updates
- Equatable for comparison
- Comprehensive field list

#### Usecases

```dart
// lib/features/hrms/domain/usecases/add_employee.dart

class AddEmployeeUseCase {
  const AddEmployeeUseCase(this._repository);

  final EmployeeRepository _repository;

  /// Add new employee
  /// Returns Either<Failure, Employee>
  /// Failure: ServerFailure, ValidationFailure
  /// Success: Created Employee with ID
  Future<Either<Failure, Employee>> call(Employee employee) {
    return _repository.addEmployee(employee);
  }
}

// Usage in BLoC:
final result = await addEmployeeUseCase(employeeEntity);
result.fold(
  (failure) => emit(state.copyWith(status: AddEmployeeStatus.failure)),
  (employee) => emit(state.copyWith(status: AddEmployeeStatus.success)),
);
```

**All Usecases:**
1. `AddEmployeeUseCase`: Create employee
2. `UpdateEmployeeUseCase`: Modify employee
3. `ExitEmployeeUseCase`: Mark as exited
4. `RehireEmployeeUseCase`: Restore exited employee
5. `GetEmployeesUseCase`: Fetch all
6. `UpdateEmployeePhotoUseCase`: Upload photo
7. `SetEmployeePhotoFromDocumentUseCase`: Use DMS photo
8. `EmployeePurchaseOrderUsecases`: PO management

#### Business Logic Filters

```dart
// lib/features/hrms/domain/employee_list_filters.dart

class EmployeeListFilters {
  /// Filter employees by status
  static bool matchesStatus(
    Employee employee,
    EmployeeListStatusFilter status,
  ) {
    switch (status) {
      case EmployeeListStatusFilter.active:
        return employee.isActive && !employee.isDraft;
      case EmployeeListStatusFilter.draft:
        return employee.isDraft;
      case EmployeeListStatusFilter.exited:
        return !employee.isActive || employee.dateOfExit != null;
    }
  }

  /// Apply all filters
  static List<Employee> apply({
    required List<Employee> employees,
    required EmployeeListStatusFilter status,
    String? client,
    String? query,
  }) {
    return employees
      .where((e) => matchesStatus(e, status))
      .where((e) => client == null || e.clientId == client)
      .where((e) => query == null || 
        e.employeeName.toLowerCase().contains(query.toLowerCase()))
      .toList();
  }
}
```

### 2.3 Presentation Layer

#### BLoC Pattern

```dart
// lib/features/hrms/presentation/bloc/employees/employees_bloc.dart

part 'employees_event.dart';
part 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  EmployeesBloc({required this.getEmployeesUseCase})
      : super(const EmployeesState()) {
    on<EmployeesRequested>(_onRequested);
  }

  final GetEmployeesUseCase getEmployeesUseCase;

  /// Event handler: fetch employees
  Future<void> _onRequested(
    EmployeesRequested event,
    Emitter<EmployeesState> emit,
  ) async {
    // Set loading state
    emit(state.copyWith(status: EmployeesStatus.loading, clearError: true));

    // Call usecase
    final result = await getEmployeesUseCase();

    // Handle result
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EmployeesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (employees) => emit(
        state.copyWith(
          status: EmployeesStatus.success,
          employees: employees,
        ),
      ),
    );
  }
}
```

#### State Management

```dart
// lib/features/hrms/presentation/bloc/employees/employees_state.dart

enum EmployeesStatus { initial, loading, success, failure }

class EmployeesState extends Equatable {
  const EmployeesState({
    this.status = EmployeesStatus.initial,
    this.employees = const [],
    this.errorMessage,
  });

  final EmployeesStatus status;
  final List<Employee> employees;
  final String? errorMessage;

  EmployeesState copyWith({
    EmployeesStatus? status,
    List<Employee>? employees,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeesState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, employees, errorMessage];
}
```

---

## 3. Adding New Features

### 3.1 Adding a New Employee Field

**Example: Add `employmentType` field (Full-time/Part-time/Contract)**

**Step 1: Update Database**
```sql
ALTER TABLE public.employees
ADD COLUMN employment_type TEXT NOT NULL DEFAULT 'full_time';
```

**Step 2: Update Entity**
```dart
// lib/features/hrms/domain/entities/employee.dart
class Employee extends Equatable {
  const Employee({
    // ... existing fields
    required this.employmentType,  // Add field
  });

  final String employmentType;

  Employee copyWith({
    // ... existing fields
    String? employmentType,
  }) {
    return Employee(
      // ... existing fields
      employmentType: employmentType ?? this.employmentType,
    );
  }

  @override
  List<Object?> get props => [
    // ... existing fields
    employmentType,
  ];
}
```

**Step 3: Update Model**
```dart
// lib/features/hrms/data/models/employee_model.dart
class EmployeeModel extends Employee {
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      // ... existing fields
      employmentType: json['employment_type'] ?? 'full_time',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ... existing fields
      'employment_type': employmentType,
    };
  }
}
```

**Step 4: Update Form**
```dart
// Add to employee form
DropdownButton<String>(
  value: state.employmentType,
  items: ['Full-time', 'Part-time', 'Contract']
    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
    .toList(),
  onChanged: (value) =>
    context.read<AddEmployeeBloc>().add(
      AddEmployeeFieldChanged(employmentType: value),
    ),
)
```

**Step 5: Update BLoC**
```dart
// In add_employee_bloc.dart
class AddEmployeeState {
  final String employmentType;
  // ... copyWith, etc.
}
```

### 3.2 Adding a New Business Logic Filter

**Example: Filter by employment type**

```dart
// In employee_list_filters.dart
static List<Employee> apply({
  required List<Employee> employees,
  required EmployeeListStatusFilter status,
  String? client,
  String? query,
  String? employmentType,  // Add parameter
}) {
  return employees
    .where((e) => matchesStatus(e, status))
    .where((e) => client == null || e.clientId == client)
    .where((e) => employmentType == null || e.employmentType == employmentType)
    .where((e) => query == null || 
      e.employeeName.toLowerCase().contains(query.toLowerCase()))
    .toList();
}
```

### 3.3 Adding a Usecase

**Example: Get employees by employment type**

```dart
// lib/features/hrms/domain/usecases/get_employees_by_type.dart

class GetEmployeesByTypeUseCase {
  const GetEmployeesByTypeUseCase(this._repository);

  final EmployeeRepository _repository;

  Future<Either<Failure, List<Employee>>> call(String employmentType) async {
    final result = await _repository.getEmployees();
    return result.fold(
      (failure) => Left(failure),
      (employees) => Right(
        employees.where((e) => e.employmentType == employmentType).toList(),
      ),
    );
  }
}
```

---

## 4. API Reference

### 4.1 Supabase Table Endpoints

**Base URL:**
```
https://[PROJECT_ID].supabase.co/rest/v1
```

**Employees Table**
```
GET    /employees              # List all (with RLS)
GET    /employees?limit=10     # Paginated
GET    /employees?order=employee_name  # Sorted
POST   /employees              # Create
PATCH  /employees?employee_id=eq.E123  # Update
DELETE /employees?employee_id=eq.E123  # Delete
```

**Example GET Request:**
```bash
curl -X GET \
  'https://project.supabase.co/rest/v1/employees?select=*&order=employee_name' \
  -H 'Authorization: Bearer eyJ...' \
  -H 'Content-Type: application/json'
```

**Example POST Request:**
```bash
curl -X POST \
  'https://project.supabase.co/rest/v1/employees' \
  -H 'Authorization: Bearer eyJ...' \
  -H 'Content-Type: application/json' \
  -d '{
    "employee_id": "E001",
    "employee_name": "John Doe",
    "date_of_joining": "2024-01-15",
    "designation": "Engineer",
    "department": "Engineering",
    "annual_ctc": 1200000,
    "monthly_ctc": 100000,
    "pan": "ABCDE1234F",
    "ifsc": "SBIN0001234",
    "bank_account": "1234567890"
  }'
```

### 4.2 Storage Endpoints

**Employee Avatars**
```
POST   /storage/v1/object/employee-avatars/[employee_id]/photo  # Upload
GET    /storage/v1/object/employee-avatars/[path]              # Download
DELETE /storage/v1/object/employee-avatars/[path]              # Delete
```

**Employee Documents (Private)**
```
POST   /storage/v1/object/documents/employee/[employee_id]/...  # Upload
GET    /storage/v1/object/signed-url/documents/...              # Signed URL
```

### 4.3 RPC Functions (If Any)

Currently no custom RPCs for HRMS (uses standard CRUD).

---

## 5. Database Queries

### 5.1 Common Queries

**Get active employees**
```sql
SELECT * FROM employees 
WHERE is_active = true AND is_draft = false
ORDER BY employee_name;
```

**Get employees by client**
```sql
SELECT * FROM employees 
WHERE client_id = 'client-123' 
  AND is_active = true;
```

**Get monthly payroll sum**
```sql
SELECT SUM(monthly_ctc) as total_payroll 
FROM employees 
WHERE is_active = true;
```

**Get employee with POs**
```sql
SELECT 
  e.*,
  COUNT(po.id) as po_count
FROM employees e
LEFT JOIN employee_purchase_orders po ON e.employee_id = po.employee_id
WHERE e.employee_id = 'E001'
GROUP BY e.employee_id;
```

**Search employees**
```sql
SELECT * FROM employees 
WHERE employee_name ILIKE '%john%' 
  AND is_active = true
ORDER BY employee_name;
```

---

## 6. Testing Guide

### 6.1 Unit Tests

**Test File Structure:**
```dart
// test/features/hrms/domain/employee_list_filters_test.dart

void main() {
  group('EmployeeListFilters', () {
    group('matchesStatus', () {
      test('active requires !draft && isActive', () {
        final employee = _employee(isActive: true, isDraft: false);
        expect(
          EmployeeListFilters.matchesStatus(
            employee,
            EmployeeListStatusFilter.active,
          ),
          isTrue,
        );
      });

      // More test cases...
    });

    group('apply', () {
      test('combines status, client, and search', () {
        final employees = [...];
        final filtered = EmployeeListFilters.apply(
          employees: employees,
          status: EmployeeListStatusFilter.active,
          client: 'Acme',
          query: 'ada',
        );
        expect(filtered.length, 1);
      });
    });
  });
}
```

### 6.2 BLoC Tests

**Template:**
```dart
// test/features/hrms/presentation/bloc/employees_bloc_test.dart

void main() {
  group('EmployeesBloc', () {
    late EmployeesBloc employeesBloc;
    late MockGetEmployeesUseCase mockGetEmployeesUseCase;

    setUp(() {
      mockGetEmployeesUseCase = MockGetEmployeesUseCase();
      employeesBloc = EmployeesBloc(
        getEmployeesUseCase: mockGetEmployeesUseCase,
      );
    });

    tearDown(() {
      employeesBloc.close();
    });

    group('EmployeesRequested', () {
      test('emits loading then success when usecase succeeds', () async {
        final employees = [_employee()];
        when(mockGetEmployeesUseCase()).thenAnswer((_) async => Right(employees));

        expect(
          employeesBloc.stream,
          emitsInOrder([
            isA<EmployeesState>()
              .having((s) => s.status, 'status', EmployeesStatus.loading),
            isA<EmployeesState>()
              .having((s) => s.status, 'status', EmployeesStatus.success)
              .having((s) => s.employees, 'employees', employees),
          ]),
        );

        employeesBloc.add(const EmployeesRequested());
      });

      test('emits loading then failure when usecase fails', () async {
        when(mockGetEmployeesUseCase())
          .thenAnswer((_) async => Left(ServerFailure()));

        expect(
          employeesBloc.stream,
          emitsInOrder([
            isA<EmployeesState>()
              .having((s) => s.status, 'status', EmployeesStatus.loading),
            isA<EmployeesState>()
              .having((s) => s.status, 'status', EmployeesStatus.failure),
          ]),
        );

        employeesBloc.add(const EmployeesRequested());
      });
    });
  });
}
```

### 6.3 Integration Tests

**Example:**
```dart
// integration_test/hrms_integration_test.dart

void main() {
  group('HRMS Integration Tests', () {
    testWidgets('User can add and view employee', (tester) async {
      // 1. Build app
      await tester.pumpWidget(const MyApp());

      // 2. Navigate to HRMS
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // 3. Click add employee
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 4. Enter data
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      // ...

      // 5. Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 6. Verify in list
      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}
```

### 6.4 Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/hrms/domain/employee_list_filters_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=integration_test/hrms_integration_test.dart
```

---

## 7. Troubleshooting

### 7.1 Common Development Issues

**Issue: BLoC not updating UI**
```dart
// Wrong: Modifying state directly
state.employees.add(newEmployee);  // ❌

// Correct: Creating new state
emit(state.copyWith(employees: [...state.employees, newEmployee]));  // ✅
```

**Issue: RLS blocking reads**
```dart
// Verify user is logged in
final user = supabase.auth.currentUser;
if (user == null) {
  print('User not authenticated');
}

// Check user has proper role
final role = await getUserRole();
print('Current role: $role');
```

**Issue: Photo not uploading**
```dart
// Ensure file exists
if (!File(path).existsSync()) {
  throw FileNotFoundException();
}

// Check MIME type
if (!['image/jpeg', 'image/png'].contains(mimeType)) {
  throw UnsupportedFileTypeException();
}
```

### 7.2 Database Issues

**Duplicate Employee ID**
```dart
// Use UUID instead of manual ID
import 'package:uuid/uuid.dart';
const uuid = Uuid();
final employeeId = uuid.v4();  // ✅

// Or use Supabase's auto-increment
// (configure sequence in database)
```

**Date Format Issues**
```dart
// Always use ISO8601 for Supabase
final dateString = dateTime.toIso8601String();
// Good: 2024-01-15T10:30:00.000Z

// Parse correctly
final dateTime = DateTime.parse(dateString).toLocal();
```

---

## 8. Performance Optimization

### 8.1 Query Optimization

**Before (Slow):**
```dart
// Load all employees, filter in app
final employees = await getEmployeesUseCase();
final filtered = employees.where(...).toList();
```

**After (Optimized):**
```dart
// Use Supabase query filters
final filtered = await supabase
  .from('employees')
  .select()
  .eq('is_active', true)
  .ilike('employee_name', '%search%')
  .order('employee_name')
  .limit(50);
```

### 8.2 State Management Optimization

**Use Equatable for diff detection:**
```dart
class EmployeesState extends Equatable {
  const EmployeesState({
    this.status = EmployeesStatus.initial,
    this.employees = const [],  // Use const default
  });

  @override
  List<Object?> get props => [status, employees];  // Only include mutable fields
}
```

### 8.3 Widget Optimization

**Use BlocBuilder with filtered listener:**
```dart
// Only rebuild when employees change
BlocBuilder<EmployeesBloc, EmployeesState>(
  buildWhen: (previous, current) =>
    previous.employees != current.employees,  // Only rebuild on change
  builder: (context, state) {
    return EmployeeList(employees: state.employees);
  },
);
```

### 8.4 Caching Strategy

**Add BLoC-level caching:**
```dart
class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  List<Employee>? _cachedEmployees;
  DateTime? _lastFetch;

  Future<void> _onRequested(...) async {
    // Check cache (5 minute TTL)
    if (_cachedEmployees != null &&
        _lastFetch!.add(Duration(minutes: 5)).isAfter(DateTime.now())) {
      emit(state.copyWith(employees: _cachedEmployees));
      return;
    }

    // Fetch fresh
    final result = await getEmployeesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: EmployeesStatus.failure)),
      (employees) {
        _cachedEmployees = employees;
        _lastFetch = DateTime.now();
        emit(state.copyWith(status: EmployeesStatus.success, employees: employees));
      },
    );
  }
}
```

---

## Appendix: Quick Reference

### Code Snippets

**Get single employee:**
```dart
final result = await supabase
  .from('employees')
  .select()
  .eq('employee_id', 'E001')
  .single();
```

**Update employee status:**
```dart
await supabase
  .from('employees')
  .update({'is_active': false, 'date_of_exit': DateTime.now()})
  .eq('employee_id', 'E001');
```

**Get paginated list:**
```dart
final startIndex = (page - 1) * pageSize;
final employees = await supabase
  .from('employees')
  .select()
  .range(startIndex, startIndex + pageSize - 1);
```

**Upload photo:**
```dart
await supabase.storage
  .from('employee-avatars')
  .upload(
    'employee/$employeeId/photo.jpg',
    File(path),
    fileOptions: const FileOptions(upsert: true),
  );
```

### Common Imports

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayge_app/features/hrms/domain/entities/employee.dart';
import 'package:sayge_app/features/hrms/presentation/bloc/employees/employees_bloc.dart';
import 'package:sayge_app/injection_container.dart' as sl;
```

