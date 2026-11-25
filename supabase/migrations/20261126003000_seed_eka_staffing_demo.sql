-- Dedicated, non-production-data workspace used for product demonstrations.
-- This migration is deliberately idempotent: it only upserts records prefixed
-- with `demo_eka_` and never changes any customer tenant's data.

begin;

do $$
declare
  v_owner_id uuid;
begin
  select id into v_owner_id
  from auth.users
  where lower(email) = 'adityaranaworks@gmail.com'
  limit 1;

  if v_owner_id is null then
    raise exception 'DEMO_OWNER_MISSING: create adityaranaworks@gmail.com in Auth before applying this migration';
  end if;

  insert into public.company_details (
    id, name, display_name, address, gstin, pan, sac_code, telephone, email,
    bank_name, bank_account_no, bank_branch, bank_ifsc
  ) values (
    'company_eka_demo', 'eka-staffing-demo', 'Eka Staffing — Demo',
    'Demo Office, Andheri East, Mumbai, Maharashtra 400069',
    '27AAAAA0000A1Z5', 'AAAAA0000A', '998311', '+91 90000 00001',
    'demo@ekastaffing.example', 'Demo Bank', '000000000000001',
    'Mumbai Demo Branch', 'DEMO0000001'
  ) on conflict (id) do update set
    name = excluded.name,
    display_name = excluded.display_name,
    address = excluded.address,
    gstin = excluded.gstin,
    pan = excluded.pan,
    sac_code = excluded.sac_code,
    telephone = excluded.telephone,
    email = excluded.email,
    bank_name = excluded.bank_name,
    bank_account_no = excluded.bank_account_no,
    bank_branch = excluded.bank_branch,
    bank_ifsc = excluded.bank_ifsc;

  insert into public.users (id, email, full_name, role_id, company_id, is_active)
  values (
    v_owner_id, 'adityaranaworks@gmail.com', 'Eka Demo Owner',
    'role_owner', 'company_eka_demo', true
  ) on conflict (id) do update set
    email = excluded.email,
    full_name = excluded.full_name,
    role_id = excluded.role_id,
    company_id = excluded.company_id,
    employee_id = null,
    is_active = true;

  insert into public.company_members (company_id, user_id, role)
  values ('company_eka_demo', v_owner_id, 'owner')
  on conflict (company_id, user_id) do update set role = excluded.role;

  insert into public.billing_subscription (
    id, company_id, plan_code, status, pos_enabled, grace_days, access_enforced,
    current_period_start, current_period_end, manual_notes
  ) values (
    'company_eka_demo', 'company_eka_demo', 'growth', 'active', false, 7, false,
    date_trunc('month', current_date)::date,
    (date_trunc('month', current_date) + interval '1 month - 1 day')::date,
    'Demo tenant. Subscription access enforcement intentionally disabled for pilot.'
  ) on conflict (id) do update set
    company_id = excluded.company_id,
    plan_code = excluded.plan_code,
    status = excluded.status,
    pos_enabled = false,
    access_enforced = false,
    manual_notes = excluded.manual_notes;

  insert into public.clients (
    id, name, vendor_code, entity_code, contact_name, address, gstin, is_active, company_id
  ) values (
    'demo_eka_mahindra_finance', 'Mahindra Finance', 'EKA-DEMO-VC-100', 'EKA-DEMO-2438335',
    'Ketan Jain',
    E'Mahindra & Mahindra Financial Services Ltd.\nMahindra Towers, Worli\nMumbai, Maharashtra 400018\nIndia',
    '27AAACM2931R2Z2', true, 'company_eka_demo'
  ) on conflict (id) do update set
    name = excluded.name,
    vendor_code = excluded.vendor_code,
    entity_code = excluded.entity_code,
    contact_name = excluded.contact_name,
    address = excluded.address,
    gstin = excluded.gstin,
    is_active = true,
    company_id = excluded.company_id;

  insert into public.employees (
    employee_id, employee_name, date_of_joining, date_of_birth, designation, department,
    annual_ctc, monthly_ctc, monthly_rate, pf_applicable, pt_applicable,
    medical_insurance, retention_amount, tds_amount, special_allowance,
    bank_account, ifsc, pan, uan, contact_no, residential_address, alternate_contact,
    personal_email, gender, father_name, mother_name, nationality, pincode,
    is_active, is_draft, location, grade, client_id, company_id
  ) values
    ('EKA-DEMO-001', 'Aarav Mehta', '2026-02-03', '1994-07-12', 'Senior Java Engineer', 'Technology', 1320000, 110000, 185000, true, true, 650, 2000, 8500, 12000, '000000000001', 'DEMO0000001', 'ABCDE1001A', '100000000001', '+91 90000 01001', 'Demo address, Mumbai', '+91 90000 11001', 'aarav.mehta@example.test', 'Male', 'Demo Parent', 'Demo Parent', 'Indian', '400001', true, false, 'Mumbai', 'L3', 'demo_eka_mahindra_finance', 'company_eka_demo'),
    ('EKA-DEMO-002', 'Diya Kapoor', '2026-03-16', '1996-02-25', 'QA Lead', 'Quality Engineering', 1080000, 90000, 155000, true, true, 650, 2000, 6500, 9000, '000000000002', 'DEMO0000001', 'ABCDE1002A', '100000000002', '+91 90000 01002', 'Demo address, Pune', '+91 90000 11002', 'diya.kapoor@example.test', 'Female', 'Demo Parent', 'Demo Parent', 'Indian', '411001', true, false, 'Pune', 'L2', 'demo_eka_mahindra_finance', 'company_eka_demo'),
    ('EKA-DEMO-003', 'Kabir Singh', '2026-05-04', '1992-11-08', 'Business Analyst', 'Product', 960000, 80000, 140000, true, true, 650, 2000, 5000, 7000, '000000000003', 'DEMO0000001', 'ABCDE1003A', '100000000003', '+91 90000 01003', 'Demo address, Bengaluru', '+91 90000 11003', 'kabir.singh@example.test', 'Male', 'Demo Parent', 'Demo Parent', 'Indian', '560001', true, false, 'Bengaluru', 'L2', 'demo_eka_mahindra_finance', 'company_eka_demo'),
    ('EKA-DEMO-004', 'Meera Iyer', '2026-06-09', '1995-04-19', 'Data Engineer', 'Data & Analytics', 1200000, 100000, 175000, true, true, 650, 2000, 7500, 10000, '000000000004', 'DEMO0000001', 'ABCDE1004A', '100000000004', '+91 90000 01004', 'Demo address, Chennai', '+91 90000 11004', 'meera.iyer@example.test', 'Female', 'Demo Parent', 'Demo Parent', 'Indian', '600001', true, false, 'Chennai', 'L3', 'demo_eka_mahindra_finance', 'company_eka_demo'),
    ('EKA-DEMO-005', 'Rohan Shah', '2026-08-17', '1997-09-03', 'Support Engineer', 'Operations', 840000, 70000, 120000, true, true, 650, 2000, 3500, 6000, '000000000005', 'DEMO0000001', 'ABCDE1005A', '100000000005', '+91 90000 01005', 'Demo address, Ahmedabad', '+91 90000 11005', 'rohan.shah@example.test', 'Male', 'Demo Parent', 'Demo Parent', 'Indian', '380001', true, false, 'Ahmedabad', 'L1', 'demo_eka_mahindra_finance', 'company_eka_demo')
  on conflict (employee_id) do update set
    employee_name = excluded.employee_name,
    date_of_joining = excluded.date_of_joining,
    designation = excluded.designation,
    department = excluded.department,
    annual_ctc = excluded.annual_ctc,
    monthly_ctc = excluded.monthly_ctc,
    monthly_rate = excluded.monthly_rate,
    client_id = excluded.client_id,
    company_id = excluded.company_id,
    is_active = true,
    is_draft = false,
    date_of_exit = null;

  insert into public.proposals (
    id, reference_no, quote_date, expiry_date, place_of_supply, vendor_code, entity_code,
    bill_to_name, bill_to_company, bill_to_address, bill_to_gstin,
    ship_to_name, ship_to_company, ship_to_address, ship_to_gstin, notes, subtotal, status, company_id
  ) values (
    'demo_eka_proposal_001', 'EKA/PROP/2026/001', '2026-01-15', '2026-02-14', 'Maharashtra',
    'EKA-DEMO-VC-100', 'EKA-DEMO-2438335', 'Ketan Jain', 'Mahindra Finance',
    E'Mahindra Towers, Worli, Mumbai 400018', '27AAACM2931R2Z2',
    'Ketan Jain', 'Mahindra Finance', E'Mahindra Towers, Worli, Mumbai 400018', '27AAACM2931R2Z2',
    'Demo staffing proposal: five technical consultants for Mahindra Finance.', 775000, 'accepted', 'company_eka_demo'
  ) on conflict (id) do update set
    quote_date = excluded.quote_date, expiry_date = excluded.expiry_date,
    subtotal = excluded.subtotal, status = excluded.status, notes = excluded.notes,
    company_id = excluded.company_id;

  insert into public.proposal_line_items (id, proposal_id, sort_order, description, monthly_rate, months, days, total_rate)
  values
    ('demo_eka_prop_line_001', 'demo_eka_proposal_001', 1, 'Aarav Mehta — Senior Java Engineer', 185000, 12, 0, 2220000),
    ('demo_eka_prop_line_002', 'demo_eka_proposal_001', 2, 'Diya Kapoor — QA Lead', 155000, 12, 0, 1860000),
    ('demo_eka_prop_line_003', 'demo_eka_proposal_001', 3, 'Kabir Singh — Business Analyst', 140000, 12, 0, 1680000),
    ('demo_eka_prop_line_004', 'demo_eka_proposal_001', 4, 'Meera Iyer — Data Engineer', 175000, 12, 0, 2100000),
    ('demo_eka_prop_line_005', 'demo_eka_proposal_001', 5, 'Rohan Shah — Support Engineer', 120000, 12, 0, 1440000)
  on conflict (id) do update set
    proposal_id = excluded.proposal_id, sort_order = excluded.sort_order, description = excluded.description,
    monthly_rate = excluded.monthly_rate, months = excluded.months, days = excluded.days, total_rate = excluded.total_rate;

  insert into public.employee_purchase_orders (
    id, employee_id, po_number, start_date, end_date, file_name, storage_path, company_id
  ) values
    ('demo_eka_po_001', 'EKA-DEMO-001', 'MF/EKA/PO/2026/001', '2026-02-01', '2027-01-31', 'DEMO-PO-AARAV.pdf', '', 'company_eka_demo'),
    ('demo_eka_po_002', 'EKA-DEMO-002', 'MF/EKA/PO/2026/002', '2026-03-01', '2027-02-28', 'DEMO-PO-DIYA.pdf', '', 'company_eka_demo'),
    ('demo_eka_po_003', 'EKA-DEMO-003', 'MF/EKA/PO/2026/003', '2026-05-01', '2027-04-30', 'DEMO-PO-KABIR.pdf', '', 'company_eka_demo'),
    ('demo_eka_po_004', 'EKA-DEMO-004', 'MF/EKA/PO/2026/004', '2026-06-01', '2026-11-30', 'DEMO-PO-MEERA-RENEWAL.pdf', '', 'company_eka_demo'),
    ('demo_eka_po_005', 'EKA-DEMO-005', 'MF/EKA/PO/2026/005', '2026-08-01', '2027-07-31', 'DEMO-PO-ROHAN.pdf', '', 'company_eka_demo')
  on conflict (id) do update set
    employee_id = excluded.employee_id, po_number = excluded.po_number,
    start_date = excluded.start_date, end_date = excluded.end_date, file_name = excluded.file_name,
    storage_path = excluded.storage_path, company_id = excluded.company_id;

  insert into public.invoices (
    id, invoice_no, invoice_date, po_number, place_of_supply, buyer_name, buyer_company,
    buyer_address, buyer_gstin, buyer_contact, intra_state, taxable_amount, cgst_amount,
    sgst_amount, igst_amount, total_amount, amount_in_words, payment_status, amount_paid,
    due_date, paid_at, company_id
  ) values
    ('demo_eka_invoice_001', 'EKA/INV/2026/009', '2026-09-30', 'MF/EKA/PO/2026/001', 'Maharashtra', 'Ketan Jain', 'Mahindra Finance', E'Mahindra Towers, Worli, Mumbai 400018', '27AAACM2931R2Z2', 'Ketan Jain', true, 775000, 69750, 69750, 0, 914500, 'Nine lakh fourteen thousand five hundred rupees only', 'paid', 914500, '2026-10-30', '2026-10-22', 'company_eka_demo'),
    ('demo_eka_invoice_002', 'EKA/INV/2026/010', '2026-10-31', 'MF/EKA/PO/2026/002', 'Maharashtra', 'Ketan Jain', 'Mahindra Finance', E'Mahindra Towers, Worli, Mumbai 400018', '27AAACM2931R2Z2', 'Ketan Jain', true, 775000, 69750, 69750, 0, 914500, 'Nine lakh fourteen thousand five hundred rupees only', 'partial', 457250, '2026-11-30', null, 'company_eka_demo'),
    ('demo_eka_invoice_003', 'EKA/INV/2026/011', '2026-11-25', 'MF/EKA/PO/2026/003', 'Maharashtra', 'Ketan Jain', 'Mahindra Finance', E'Mahindra Towers, Worli, Mumbai 400018', '27AAACM2931R2Z2', 'Ketan Jain', true, 775000, 69750, 69750, 0, 914500, 'Nine lakh fourteen thousand five hundred rupees only', 'sent', 0, '2026-12-25', null, 'company_eka_demo')
  on conflict (id) do update set
    invoice_date = excluded.invoice_date, po_number = excluded.po_number,
    taxable_amount = excluded.taxable_amount, cgst_amount = excluded.cgst_amount,
    sgst_amount = excluded.sgst_amount, total_amount = excluded.total_amount,
    payment_status = excluded.payment_status, amount_paid = excluded.amount_paid,
    due_date = excluded.due_date, paid_at = excluded.paid_at, company_id = excluded.company_id;

  insert into public.invoice_line_items (id, invoice_id, sort_order, particulars, amount)
  values
    ('demo_eka_inv_line_001', 'demo_eka_invoice_001', 1, 'September 2026 staffing services — Mahindra Finance', 775000),
    ('demo_eka_inv_line_002', 'demo_eka_invoice_002', 1, 'October 2026 staffing services — Mahindra Finance', 775000),
    ('demo_eka_inv_line_003', 'demo_eka_invoice_003', 1, 'November 2026 staffing services — Mahindra Finance', 775000)
  on conflict (id) do update set
    invoice_id = excluded.invoice_id, sort_order = excluded.sort_order,
    particulars = excluded.particulars, amount = excluded.amount;

  insert into public.expenses (
    id, made_for, amount, paid_from, category, client_id, created_by, approval_status,
    approved_by, approved_at, expense_date, receipt_name, company_id
  ) values
    ('demo_eka_expense_001', 'Mahindra Finance onboarding travel', 18500, 'Company account', 'Travel', 'demo_eka_mahindra_finance', v_owner_id, 'paid', v_owner_id, now() - interval '20 days', '2026-11-06', 'DEMO-travel-receipt.pdf', 'company_eka_demo'),
    ('demo_eka_expense_002', 'Recruitment campaign — November', 12000, 'Company account', 'Recruitment', 'demo_eka_mahindra_finance', v_owner_id, 'approved', v_owner_id, now() - interval '5 days', '2026-11-18', 'DEMO-campaign-receipt.pdf', 'company_eka_demo'),
    ('demo_eka_expense_003', 'Client workshop refreshments', 6400, 'Company account', 'Client meeting', 'demo_eka_mahindra_finance', v_owner_id, 'pending', null, null, '2026-11-24', 'DEMO-workshop-receipt.pdf', 'company_eka_demo')
  on conflict (id) do update set
    made_for = excluded.made_for, amount = excluded.amount, paid_from = excluded.paid_from,
    category = excluded.category, client_id = excluded.client_id,
    approval_status = excluded.approval_status, approved_by = excluded.approved_by,
    approved_at = excluded.approved_at, expense_date = excluded.expense_date,
    receipt_name = excluded.receipt_name, company_id = excluded.company_id;

  insert into public.dms_entities (id, name, entity_type, subtitle, company_id)
  values
    ('demo_eka_dms_employee_001', 'Aarav Mehta', 'employee', 'Senior Java Engineer · Mahindra Finance', 'company_eka_demo'),
    ('demo_eka_dms_client_001', 'Mahindra Finance', 'company', 'Client records · Ketan Jain', 'company_eka_demo')
  on conflict (id) do update set
    name = excluded.name, entity_type = excluded.entity_type, subtitle = excluded.subtitle,
    company_id = excluded.company_id;

  insert into public.documents (
    id, entity_type, entity_id, entity_name, title, file_name, mime_type,
    file_size_bytes, storage_path, notes, category, company_id
  ) values
    ('demo_eka_document_001', 'employee', 'EKA-DEMO-001', 'Aarav Mehta', 'Employment agreement (demo)', 'DEMO-Aarav-employment-agreement.pdf', 'application/pdf', 0, '', 'Demo-only placeholder; upload a real document during the presentation if needed.', 'Contracts', 'company_eka_demo'),
    ('demo_eka_document_002', 'company', 'demo_eka_mahindra_finance', 'Mahindra Finance', 'Approved proposal (demo)', 'DEMO-Mahindra-approved-proposal.pdf', 'application/pdf', 0, '', 'Demo-only placeholder for the proposal-to-PO journey.', 'Commercial', 'company_eka_demo')
  on conflict (id) do update set
    entity_type = excluded.entity_type, entity_id = excluded.entity_id,
    entity_name = excluded.entity_name, title = excluded.title, file_name = excluded.file_name,
    notes = excluded.notes, category = excluded.category, company_id = excluded.company_id;
end $$;

commit;
