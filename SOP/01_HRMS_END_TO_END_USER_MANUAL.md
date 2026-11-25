# HRMS Module - End-to-End User Manual

## 1. HRMS Dashboard (Overview)

### Location
`Modules → HRMS → Overview`

### Purpose
Quick snapshot of employee statistics and company HR metrics

### Features
- **Active Employees Count**: Total number of active, non-draft employees
- **Draft Employees Count**: Incomplete profiles awaiting completion
- **Exited Employees Count**: Former employees who have left
- **Monthly Payroll**: Total monthly CTC for active employees
- **At a Glance Cards**: Visual summary of key HR metrics

### How to Access
1. Login to Sayge app
2. Navigate to `Modules` tab
3. Select `HRMS`
4. Click `Overview` tab

### Common Use Cases
- **HR Managers**: Quick check on employee headcount
- **Finance Team**: Understand monthly payroll burden
- **Executives**: Dashboard briefing before meetings

---

## 2. Managing Employees

### 2.1 View Employee List

#### Location
`Modules → HRMS → Employees`

#### How to Access
1. Navigate to HRMS module
2. Click `Employees` tab
3. See list of all employees (paginated)

#### Employee List Features

**Search**
- Search by employee name
- Real-time filtering as you type
- Case-insensitive search

**Filters**
- **Status Filter** (3 options):
  - Active: Fully onboarded, working
  - Draft: Incomplete profile
  - Exited: Former employees
- **Client Filter**: Filter by assigned client
- Multiple filters work together

**Employee Card Shows**
- Employee photo (if uploaded)
- Employee name
- Designation
- Department
- Status badge (Active/Draft/Exited)
- Quick action menu (view/edit)

**Sorting & Pagination**
- Sorted by employee name alphabetically
- Paginated for large lists
- Load more as you scroll (mobile)
- Fixed pagination on desktop

**Bulk Actions**
- Select multiple employees
- Export to CSV for reporting
- Download selected employee data

**Add New Employee**
- Click `+` button in top-right corner
- Or click `Add Employee` button

#### Employee Card Details
Clicking an employee card shows:
- Full name and ID
- Photo
- Designation and Department
- Status
- Quick access to edit, view details, or delete

---

### 2.2 Add New Employee

#### Location
`Modules → HRMS → Employees → + Add`

#### How to Add Employee

**Step 1: Basic Information**
1. Click `Add Employee` button
2. Fill in required fields:
   - **Employee Name**: Full name (required)
   - **Date of Joining**: When employee started (required)
   - **Designation**: Job title (required)
   - **Department**: Department name (required)
   - **Grade**: Seniority level (required)
   - **Location**: Office location (required)

**Step 2: Compensation Details**
1. **Annual CTC**: Total annual compensation (required)
   - System auto-calculates Monthly CTC (÷ 12)
   - Enter gross amount
2. **Monthly Billing Rate**: Rate for proposal/client billing (optional)
   - Distinct from monthly salary
   - Used for revenue calculations
3. **TDS Amount**: Monthly tax withholding (default: 0)
4. **Special Allowance**: Fixed allowance outside salary structure (default: 0)
5. **Medical Insurance**: Monthly premium (default: ₹650)
6. **Retention Amount**: Performance/retention bonus (default: ₹2000)

**Step 3: Tax & Benefit Eligibility**
- **PF Applicable**: Provident Fund deduction (default: Yes)
- **PT Applicable**: Professional Tax deduction (default: Yes)

**Step 4: Banking & ID Information**
1. **Bank Account Number** (required): 9-18 digits
2. **IFSC Code** (required): Bank branch code
3. **PAN** (required): 10-character tax ID
4. **UAN**: Universal Account Number (optional, for PF)

**Step 5: Personal Information**
1. **Date of Birth** (optional)
2. **Gender** (optional)
3. **Contact Number** (optional)
4. **Alternate Contact** (optional)
5. **Personal Email** (optional)
6. **Residential Address** (optional)
7. **Pincode** (optional)
8. **Nationality** (optional)
9. **Father's Name** (optional)
10. **Mother's Name** (optional)

**Step 6: Client Assignment**
- **Client**: Link employee to a client (optional)
- Used for client billing and project assignment
- Select from active clients dropdown

**Step 7: Photo Upload**
- Click `Add Photo` section
- Upload employee photo (JPG, PNG)
- Photo visible in employee list and profile
- Can be updated/changed later

**Step 8: Review & Save**
1. Review all entered information
2. Click `Save Employee`
3. System generates unique employee ID (auto-increment)
4. Employee status set to `Active` by default

#### Validation Rules
- Employee Name: Required, non-empty
- Annual CTC: Must be > 0
- PAN: Exactly 10 characters
- Bank Account: Numeric, 9-18 digits
- IFSC: Valid bank IFSC format
- Dates: Valid date range (DOJ before DOB)
- Phone: Valid format if provided

#### After Adding
- Redirect to employee detail page
- Employee now visible in list
- Can edit, add PO, or invite to system
- Payroll can reference this employee

---

### 2.3 View & Edit Employee Details

#### Location
`Employees → Select Employee → View Details`

#### How to Access Employee Details
1. Go to Employees list
2. Click on employee card or name
3. Opens employee detail page

#### Employee Detail Page Shows

**Header Section**
- Employee photo
- Employee ID
- Name
- Current Status (Active/Draft/Exited)
- Quick actions menu

**Tabs/Sections**

**Tab 1: Professional Information**
- Designation
- Department
- Grade
- Location
- Client Assignment
- Date of Joining

**Tab 2: Compensation & Payroll**
- Annual CTC
- Monthly CTC (calculated)
- Monthly Billing Rate
- TDS Amount
- Special Allowance
- Medical Insurance
- Retention Amount
- PF/PT Status

**Tab 3: Banking Details**
- Bank Account Number
- IFSC Code
- PAN (Permanent Account Number)
- UAN (Universal Account Number)

**Tab 4: Personal Information**
- Date of Birth
- Gender
- Contact Numbers (Primary & Alternate)
- Personal Email
- Residential Address
- Pincode
- Nationality
- Family Information (Father/Mother name)

**Tab 5: Compensation Breakup** (Detailed Breakdown)
- Shows salary component structure
- Monthly breakdown
- Annual summary
- Tax implications

**Tab 6: Employee Purchase Orders (POs)**
- List of assigned purchase orders
- PO number, dates, file
- Download/view PO documents

**Tab 7: Personal Documents (DMS)**
- Employee's private documents
- Uploaded contracts, certificates
- Download with signed URLs

**Tab 8: Activity History**
- Record of changes
- Who modified what and when
- Visible to admins only

#### How to Edit Employee

**Making Changes**
1. On detail page, click `Edit` button
2. Same form as add employee opens
3. All fields pre-filled with current data
4. Make required changes
5. Click `Save Employee`

**Editable by Employee (Self-Service)**
Employees can only edit:
- Contact number
- Alternate contact
- Personal email
- Residential address
- Pincode
- Nationality
- Gender
- Father's name
- Mother's name
- Photo

**Locked Fields (Admins only)**
- Compensation (CTC, TDS, allowances)
- Designation, grade, department
- Banking details (account, IFSC, PAN)
- Date of joining
- is_active, is_draft status

#### Photo Management
- Click photo area to change
- Upload new photo (JPG, PNG, up to 5MB)
- Photo updates in list immediately
- Previous photo automatically deleted

---

### 2.4 Employee Self-Service (My Details)

#### Location
`Modules → Employee Dashboard → My Details`

#### How to Access
1. Login as employee
2. Navigate to Employee Dashboard
3. Click `My Details` tab

#### What Employees Can View
- Their complete profile
- Compensation breakup
- Payslips
- Personal documents
- Expenses they submitted
- POs assigned to them

#### What Employees Can Edit
- Contact number
- Alternate contact
- Personal email
- Residential address
- Pincode
- Nationality
- Gender
- Family names (Father/Mother)
- Photo

#### Workflow
1. Employee views their profile
2. Finds fields to update
3. Clicks `Edit` on relevant section
4. Makes changes
5. Changes auto-save
6. Can view audit trail of changes

---

### 2.5 Compensation Breakup View

#### Location
`Employee Detail → Compensation Breakup Tab`

#### Purpose
Detailed breakdown of salary structure for accounting and payroll

#### Components Shown
- **Gross Salary**
  - Basic Salary (calculated as: Annual CTC - Special Allowance) / 12
  - Special Allowance (fixed amount)
- **Deductions**
  - TDS (Tax Deducted at Source)
  - PF (if applicable)
  - PT (if applicable)
  - Medical Insurance
  - Other deductions
- **Net Salary** (Gross - Deductions)
- **Monthly Breakdown**
- **Annual Summary**

#### Use Cases
- Payroll team verifying calculations
- Employees understanding salary structure
- Finance reconciliation
- PF/PT compliance verification

---

## 3. Employee Lifecycle Management

### 3.1 Employee Status Transitions

**Status Types**

| Status | Meaning | Active | Draft | Exited |
|--------|---------|--------|-------|--------|
| Active | Fully onboarded, working | ✓ | ✗ | ✗ |
| Draft | Incomplete profile | ✗ | ✓ | ✗ |
| Exited | Former employee | ✗ | ✗ | ✓ |

### 3.2 Exit Employee

#### When to Use
- Employee resigned
- Employee terminated
- Employee retired
- Employee on sabbatical

#### How to Exit Employee
1. Open employee detail page
2. Click `More Actions` → `Exit Employee`
3. Enter **Date of Exit** (last working day)
4. Optionally add **Exit Reason** (resignation, termination, etc.)
5. Click `Confirm Exit`

#### What Happens
- Employee status changes to "Exited"
- `is_active` set to false
- `date_of_exit` populated with provided date
- Employee removed from active list
- Appears in "Exited" filter
- Cannot access employee portal
- Cannot submit new expenses
- Previous data retained for history/compliance

#### Final Payroll
- Run final payslip before or on exit date
- Include pro-rata calculations
- Include full/final settlement
- Include ELI (Employee Liability Insurance) if applicable

### 3.3 Re-hire Exited Employee

#### When to Use
- Employee rejoins company
- Previous employee brought back
- Consultant becomes full-time employee

#### How to Rehire
1. Open exited employee detail page
2. Click `More Actions` → `Rehire Employee`
3. Enter **New Date of Joining** (re-join date)
4. Confirm rehire
5. Click `Save`

#### What Happens
- Employee status changes back to "Active"
- `is_active` set to true
- `date_of_exit` cleared (set to null)
- `date_of_joining` updated to new date
- Previous compensation retained
- Previous data accessible
- Can access employee portal again
- Can submit expenses

#### Payroll Consideration
- Previous payroll history retained
- May need adjustment of benefits (PF reset, etc.)
- Coordinate with Finance team

---

## 4. Employee Purchase Order (PO) Management

### Location
`Employee Detail → Employee Purchase Orders Tab`

### Purpose
Track and manage purchase orders (contracts) assigned to employees

### PO Information Stored
- **PO Number**: Unique identifier
- **Start Date**: PO validity start
- **End Date**: PO validity end
- **Document**: PDF or attachment of PO
- **Coverage Period**: Inclusive date range

### How to Add PO

**Manual Addition**
1. Open employee detail page
2. Go to `Employee Purchase Orders` tab
3. Click `Add Purchase Order`
4. Fill in:
   - PO Number (unique identifier)
   - Start Date (when PO becomes valid)
   - End Date (when PO expires)
5. Upload PO document (PDF preferred)
6. Click `Save PO`

**Bulk Upload**
- Upload multiple POs for single employee
- Or bulk assign POs to multiple employees

### How to View PO

1. Click on PO in list
2. See:
   - PO number and dates
   - File name and size
   - Upload date
   - Download link
3. Download document with secure signed URL

### PO Date Coverage Check

**Validation Rule**
- `end_date` must be >= `start_date`
- Used for invoice/proposal date validation
- System checks if invoice date falls within PO coverage

**Use in Invoicing**
- When creating invoice for employee, system checks if invoice date falls within any active PO
- Restricts billing if no active PO
- Ensures compliance with contract terms

### How to Delete PO
1. Click on PO in list
2. Click `Delete`
3. Confirm deletion
4. Document removed from storage
5. Record deleted from database

---

## 5. Employee Filtering & Search

### Search by Name

**How**
- Type employee name in search box
- Real-time results as you type
- Case-insensitive matching
- Partial name matching works

**Examples**
- Search "ada" finds "Ada Lovelace"
- Search "raj" finds "Rajesh Kumar"
- Search "Kumar" finds "Rajesh Kumar"

### Filter by Status

**Active Employees**
- Requirement: `is_active = true` AND `is_draft = false`
- Shows fully onboarded working employees
- Default view in Employees list

**Draft Employees**
- Requirement: `is_draft = true`
- Shows incomplete profiles (invited but not completed setup)
- Usually pending document submission

**Exited Employees**
- Requirement: `is_active = false` OR `date_of_exit` is populated
- Shows former employees
- Separated from active payroll

### Filter by Client

**How**
- Select client from client filter dropdown
- Shows only employees linked to that client
- Useful for project-based billing

**Examples**
- Filter by "Acme Corp" to see all Acme employees
- Filter by "Beta Inc" to see contractor assignments
- Multiple filters combine (e.g., Active + Acme)

### Combined Filtering

**Example Scenario**: Find all active employees at Acme Corp named "Kumar"
1. Search box: type "Kumar"
2. Status filter: select "Active"
3. Client filter: select "Acme Corp"
4. Result: Shows matching employees only

---

## 6. Data Privacy & Security

### Row-Level Security (RLS)

**Employee Access**
- Employees can see only their own record
- Cannot view other employee compensation
- Cannot view other employee banking details
- Cannot access exited employee data

**Admin/Owner Access**
- Full access to all employee records
- Can view all compensation details
- Can audit changes via activity log

**HR Team Access**
- Full access (depends on role configuration)

### Field-Level Security

**Employee Self-Edit Allowed**
- Contact number, email, address
- Personal details (gender, family)
- Photo
- Other non-financial fields

**Admin-Only Fields**
- All compensation (CTC, TDS, allowances)
- Designation, grade, department
- Banking/ID details (account, PAN, UAN)
- is_active, is_draft flags
- Dates (joining, exit, DOB)

### Audit Trail

**What's Logged**
- Every change to employee record
- Who made the change
- When it was made
- Previous and new values

**Who Can View**
- Owners and Admins only
- Not visible to HR team by default
- Not visible to employees

**Access**
- `Activity Log` page
- Filter by employee, date range
- Export logs for compliance

---

## 7. Common Tasks & Workflows

### Onboarding New Employee

1. **Week Before Joining**
   - Collect employee details
   - Prepare offer letter
   - Coordinate with IT/HR

2. **Day Before Joining**
   - Add employee to system
   - Upload employee photo
   - Assign compensation
   - Assign client (if applicable)
   - Upload any initial documents (offer letter, ID)

3. **Day of Joining**
   - Send invitation link (via email)
   - Employee sets password
   - Employee completes personal information
   - Assign employee ID badge

4. **Week After Joining**
   - Verify all data completed
   - Set up access to systems
   - Assign initial PO (if applicable)
   - Briefing on employee portal

### Monthly Payroll Cycle

1. **Day 1-5**: Collect attendance, leaves, bonus info
2. **Day 6-15**: 
   - Run payroll in Payroll module
   - System calculates using employee data
   - Generate payslips
3. **Day 16-25**: 
   - Approve payroll
   - Process payments
   - Send payslips to employees
4. **Day 26-30**: 
   - Confirm all payments done
   - Archive records
   - Prepare for next month

### Employee Transfer to Another Client

1. Open employee detail
2. Click `Edit`
3. Change `Client` field
4. Update any compensation changes
5. Click `Save`
6. Document reason in activity log (manual note)

### Bulk Hire Multiple Employees

1. Prepare CSV with employee details
2. Use bulk import (if available)
3. Or manually add each employee
4. Send invitation links to all
5. Track completion status

### Export Employee List

1. Go to Employees list
2. Click `Export to CSV`
3. Choose fields to export
4. File downloads (Excel format)
5. Use for reporting, compliance, payroll export

---

## 8. Troubleshooting & Common Issues

### Issue: Cannot Save Employee
**Cause**: Missing required field
**Solution**: 
- Check all required fields are filled
- Annual CTC must be > 0
- PAN must be exactly 10 characters
- Dates must be valid

### Issue: Photo Not Uploading
**Cause**: File too large or wrong format
**Solution**:
- Use JPG or PNG only
- File size < 5MB
- Crop photo to reasonable size
- Try different browser if problem persists

### Issue: Employee Cannot Edit Their Details
**Cause**: Permission restrictions
**Solution**:
- Verify employee is logged in with correct account
- Check role settings
- Allowed fields: contact, email, address, photo only
- Cannot edit compensation or designation

### Issue: Exited Employee Visible in Active List
**Cause**: is_active flag not updated correctly
**Solution**:
- Refresh page (clear browser cache)
- Use `Exit Employee` function (not just editing is_active)
- Verify status filter is set to "Active"

### Issue: Performance Slow with Large Employee List
**Cause**: Too many employees, unoptimized query
**Solution**:
- Use search/filter to reduce dataset
- Paginate through results
- Export to CSV for large reports
- Contact support if consistent slowness

### Issue: Cannot Find Employee
**Cause**: Misspelled name, hidden by filter
**Solution**:
- Check spelling in search box
- Clear all filters and search again
- Check Status filter (may be hidden in Draft/Exited)
- Check Client filter
- Verify employee hasn't been deleted

---

## 9. Best Practices

### Data Quality
1. **Keep Information Current**: Update immediately on changes
2. **Complete All Fields**: Especially banking details for payroll
3. **Photo Guidelines**: 
   - Professional headshot
   - Face clearly visible
   - Current photo (within 1 year)
4. **Address Accuracy**: Important for mail/compliance
5. **Regular Audits**: Monthly review of employee data

### Security
1. **Limit Access**: Only assign HR role to authorized users
2. **Audit Regularly**: Review activity logs monthly
3. **Secure Passwords**: Strong password for employee accounts
4. **Document Storage**: Keep POs and contracts updated
5. **Compliance**: Maintain complete record for 7 years

### Payroll Accuracy
1. **Verify CTC**: Double-check salary calculations
2. **TDS Settings**: Configure correctly for tax compliance
3. **Benefits Enrollment**: Document PF/PT choices
4. **Bank Details**: Verify before first payment
5. **Deduction Rates**: Review annually with Finance

### Documentation
1. **Date Format**: Use YYYY-MM-DD consistently
2. **PAN Format**: Exactly 10 characters (e.g., ABCDE1234F)
3. **Bank Account**: Use correct length per bank
4. **Notes**: Use Description field for special cases
5. **Archive**: Keep copies of exit documents

---

## 10. Integration Points

### With Payroll Module
- Employee compensation → Salary calculations
- TDS, PF, PT settings → Deduction calculations
- Monthly CTC → Payslip generation

### With Expense Module
- Employee identity → Expense ownership
- Employee status → Expense submission eligibility
- Banking details → Reimbursement processing

### With DMS (Document Management)
- Private folder: `documents/employee/<employee_id>/`
- Signed URLs for secure access
- Storage per employee

### With Proposal/Invoice Module
- Monthly billing rate → Invoice line items
- PO validation → Billing restrictions
- Client assignment → Client revenue tracking

### With User/Auth System
- Employee record ↔ User account
- Role assignment → Permission system
- Invitation system → User provisioning

---

## Appendix A: Employee Field Reference

| Field | Type | Required | Editable by Employee | Use Case |
|-------|------|----------|---------------------|----------|
| employee_id | String | Yes | No | Unique identifier |
| employee_name | String | Yes | No | Full name |
| date_of_joining | Date | Yes | No | Tenure calculation |
| designation | String | Yes | No | Job title for org chart |
| department | String | Yes | No | Department assignment |
| annual_ctc | Number | Yes | No | Payroll base |
| monthly_ctc | Number | Calculated | No | Payslip amount |
| monthly_rate | Number | No | No | Proposal billing rate |
| pf_applicable | Boolean | Yes | No | Deduction eligibility |
| pt_applicable | Boolean | Yes | No | Deduction eligibility |
| bank_account | String | Yes | No | Salary transfer |
| pan | String | Yes | No | Tax filing |
| uan | String | No | No | PF account |
| contact_no | String | No | Yes | Communication |
| residential_address | String | No | Yes | Mailing address |
| personal_email | String | No | Yes | Notifications |
| gender | String | No | Yes | Demographic |
| date_of_birth | Date | No | Yes | Age verification |
| photo_path | String | No | Yes | Identification |
| is_active | Boolean | Yes | No | Payroll inclusion |
| is_draft | Boolean | No | No | Completion status |
| date_of_exit | Date | No | No | Exit tracking |

---

## Appendix B: Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+N` / `Cmd+N` | New employee (on employees list) |
| `Ctrl+E` / `Cmd+E` | Edit current employee |
| `Ctrl+S` / `Cmd+S` | Save changes |
| `Escape` | Cancel/close dialog |
| `Ctrl+F` / `Cmd+F` | Search/filter |

---

## Appendix C: Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Employee ID already exists" | Duplicate ID | Use different ID or let system auto-generate |
| "Required field missing" | Incomplete form | Fill all marked required fields |
| "Invalid PAN format" | Wrong format | Use 10-character format (e.g., ABCDE1234F) |
| "Date of exit before joining" | Invalid date range | Exit date must be after or equal to joining date |
| "File too large" | Photo > 5MB | Use smaller image |
| "Insufficient permissions" | Role restriction | Contact admin for elevated access |
| "Network timeout" | Slow connection | Retry operation or check internet |

