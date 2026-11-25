# HRMS Module - Overview & Architecture

## Module Purpose
The HRMS (Human Resource Management System) module is the core HR management system in Sayge that handles:
- Employee lifecycle management (onboarding, updates, exit, rehire)
- Compensation and payroll data management
- Employee self-service portal
- Employee purchase order (PO) tracking
- Personal and professional employee information
- Photo/avatar management
- Role-based access control

## Module Structure

```
lib/features/hrms/
├── data/
│   ├── datasources/
│   │   ├── employee_remote_datasource.dart
│   │   └── employee_purchase_order_remote_datasource.dart
│   ├── models/
│   │   ├── employee_model.dart
│   │   └── employee_purchase_order_model.dart
│   └── repositories/
│       ├── employee_repository_impl.dart
│       └── employee_purchase_order_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── employee.dart
│   │   └── employee_purchase_order.dart
│   ├── repositories/
│   │   ├── employee_repository.dart
│   │   └── employee_purchase_order_repository.dart
│   ├── usecases/
│   │   ├── add_employee.dart
│   │   ├── update_employee.dart
│   │   ├── exit_employee.dart
│   │   ├── rehire_employee.dart
│   │   ├── get_employees.dart
│   │   ├── update_employee_photo_usecase.dart
│   │   ├── set_employee_photo_from_document_usecase.dart
│   │   └── employee_purchase_order_usecases.dart
│   └── employee_list_filters.dart
├── presentation/
│   ├── bloc/
│   │   ├── employees/
│   │   │   ├── employees_bloc.dart
│   │   │   ├── employees_event.dart
│   │   │   └── employees_state.dart
│   │   ├── add_employee/
│   │   │   ├── add_employee_bloc.dart
│   │   │   ├── add_employee_event.dart
│   │   │   └── add_employee_state.dart
│   │   └── employee_po/
│   │       ├── employee_po_bloc.dart
│   │       ├── employee_po_event.dart
│   │       └── employee_po_state.dart
│   ├── pages/
│   │   ├── hrms_overview_page.dart
│   │   ├── employees_page.dart
│   │   ├── add_employee_page.dart
│   │   ├── employee_detail_page.dart
│   │   ├── compensation_breakup_page.dart
│   │   ├── my_details_page.dart
│   └── widgets/
│       ├── employee_avatar.dart
│       ├── employee_form_layout.dart
│       ├── employee_stat_cards.dart
│       ├── employee_documents_section.dart
│       └── employee_purchase_orders_section.dart
```

## Architecture Pattern
- **BLoC Pattern** for state management
- **Clean Architecture** with 3-layer separation (Data, Domain, Presentation)
- **Repository Pattern** for data abstraction
- **Dependency Injection** via GetIt

## Database Tables

### employees (Primary Employee Data)
```
- employee_id (Primary Key)
- employee_name
- date_of_joining
- date_of_birth (nullable)
- date_of_exit (nullable)
- designation
- department
- location
- grade
- client_id (Foreign Key to clients)
- is_active
- is_draft
```

### Compensation Fields
```
- annual_ctc
- monthly_ctc
- monthly_rate (billing rate, distinct from payroll rate)
- tds_amount (Tax Deducted at Source)
- special_allowance
- pf_applicable (Provident Fund)
- pt_applicable (Professional Tax)
- medical_insurance
- retention_amount
```

### Banking & ID Fields
```
- bank_account
- ifsc
- pan
- uan
```

### Personal Information
```
- contact_no
- alternate_contact
- residential_address
- personal_email
- gender
- father_name
- mother_name
- nationality
- pincode
- photo_path
```

### employee_purchase_orders (PO Management)
```
- id (Primary Key)
- employee_id (Foreign Key)
- po_number
- start_date
- end_date
- file_name
- mime_type
- file_size_bytes
- storage_path
```

## Key Features

### 1. Employee Lifecycle Management
- ✅ Create new employees
- ✅ Update existing employee data
- ✅ Exit employees (mark as inactive with date_of_exit)
- ✅ Rehire exited employees
- ✅ Draft employees (incomplete profiles)
- ✅ Employee status tracking (Active, Draft, Exited)

### 2. Employee Data Categories

#### Professional Information
- Designation
- Department
- Grade
- Location
- Client Assignment
- Date of Joining

#### Compensation Details
- Annual CTC
- Monthly CTC
- Monthly Billing Rate (proposal rate)
- TDS Amount (tax withholding)
- Special Allowances
- PF & PT Status
- Medical Insurance
- Retention Amount

#### Personal Information
- Full Name
- Date of Birth
- Gender
- Contact Numbers
- Email Address
- Residential Address
- Family Information (Father/Mother name)
- Nationality, Pincode

#### Banking & Identification
- Bank Account Number
- IFSC Code
- PAN (Permanent Account Number)
- UAN (Universal Account Number)

#### Media
- Photo/Avatar (uploaded, stored in cloud)

### 3. Access Control (Row-Level Security)
- **Owners/Admins**: Full access to all employees
- **HR Users**: Full access to all employees
- **Team Leads**: View all employees (read-only)
- **Employees**: View only their own data

### 4. Field-Level Write Restrictions (By Role)
Employees can only edit these fields:
- contact_no
- alternate_contact
- personal_email
- residential_address
- pincode
- nationality
- gender
- father_name
- mother_name
- photo_path

Employees CANNOT edit:
- CTC, salary components (monetary fields)
- Designation, grade, department
- Bank details, PAN, UAN
- is_active, is_draft, date_of_exit
- client_id

## Related Features

### Payroll Module Integration
Employee compensation data feeds into payroll calculations:
- Monthly CTC for salary computation
- TDS for tax calculations
- PF/PT for deduction calculations
- Special allowances for gross calculation

### DMS (Document Management)
Employee documents stored in:
- Private `documents/employee/<employee_id>/` folder
- RLS-protected storage with signed URLs

### Expense Management
Employee profile links to:
- Expense submissions
- Expense approvals
- Expense receipt uploads

### Authentication & User Management
Employee link to:
- User accounts in auth system
- Roles and permissions
- Invitation system (for new employees)

## Status Definitions

### Active
- `is_active = true`
- `is_draft = false`
- `date_of_exit = null`
- Visible in employee lists
- Can submit expenses, view payslips

### Draft
- `is_draft = true`
- Incomplete employee profile
- Created via email invitation
- Not visible in active employee list
- Cannot access full system features

### Exited
- `is_active = false` OR `date_of_exit != null`
- Employee has left the company
- Final payslip generated
- Cannot access employee portal
- Can be rehired (soft restore)

## Key Business Rules

1. **Employee ID Auto-Sequence**: IDs auto-generate starting from 2127 when no higher numeric ID exists
2. **Monthly CTC Calculation**: Derived from annual CTC (annual / 12)
3. **Monthly Rate**: Distinct from monthly CTC; used for proposal/billing rates
4. **Date of Exit Logic**: Can be used to identify exited employees alongside is_active flag
5. **Photo Storage**: Photos stored separately; deleted when employee record updates
6. **PO Date Coverage**: Purchase orders must have end_date >= start_date
7. **Soft Deletes**: Draft employees not shown in active lists but records preserved
8. **Re-hire Support**: Exited employees can be rehired by clearing date_of_exit and setting is_active = true

## Performance Considerations

### Indexes
- `employees_location_idx` on (location)
- `employee_purchase_orders_employee_idx` on (employee_id, start_date desc)

### Common Queries
- Get all active employees
- Filter by status (Active/Draft/Exited)
- Filter by client assignment
- Search by name
- Get employee details with POs

## Error Handling

Common errors and their causes:
1. **Employee ID Conflict**: Duplicate employee ID when adding
2. **RLS Violation**: User attempting to access other employee's data
3. **Missing Required Fields**: Employee name, CTC, PAN, etc.
4. **Invalid Date Ranges**: Date of exit before joining
5. **File Upload Failure**: Photo or PO document upload errors
6. **Network Timeout**: Long-running employee list fetch

## Testing Strategy

### Unit Tests
- Employee status filtering (`employee_list_filters_test.dart`)
- Date range calculations
- Field validation
- Payroll calculations

### Integration Tests
- Full employee creation flow
- Photo upload and retrieval
- PO management workflows
- Role-based data access

### Key Test Cases
- Active employee requires !draft && isActive
- Draft matches isDraft flag
- Exited requires !isActive or dateOfExit != null
- Rehire clears dateOfExit and restores isActive
- Search and filtering combinations
