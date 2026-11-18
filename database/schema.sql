-- HR & Payroll ERP : MySQL / MariaDB schema (InnoDB, utf8mb4)
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------- ACCESS CONTROL
CREATE TABLE IF NOT EXISTS roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  slug VARCHAR(80) NOT NULL UNIQUE,
  scope ENUM('all','team','self') NOT NULL DEFAULT 'self',
  description VARCHAR(255) NULL,
  is_system TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id INT NOT NULL,
  permission VARCHAR(80) NOT NULL,
  PRIMARY KEY (role_id, permission),
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NULL,
  username VARCHAR(80) NOT NULL UNIQUE,
  email VARCHAR(150) NULL,
  password_hash VARCHAR(255) NOT NULL,
  role_id INT NOT NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  must_change_password TINYINT(1) NOT NULL DEFAULT 0,
  last_login DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS delegations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  from_user_id INT NOT NULL,
  to_user_id INT NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  authority VARCHAR(80) NOT NULL DEFAULT 'All approvals',
  reason VARCHAR(255) NULL,
  status ENUM('Active','Revoked') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (from_user_id) REFERENCES users(id),
  FOREIGN KEY (to_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS delegation_rules (
  id INT AUTO_INCREMENT PRIMARY KEY,
  authority VARCHAR(80) NOT NULL UNIQUE,
  description VARCHAR(255) NULL,
  is_delegable TINYINT(1) NOT NULL DEFAULT 1,
  max_days INT NOT NULL DEFAULT 30,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  action VARCHAR(40) NOT NULL,
  entity VARCHAR(60) NOT NULL,
  entity_id VARCHAR(40) NULL,
  details TEXT NULL,
  ip VARCHAR(45) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (entity, entity_id), INDEX (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS settings (
  skey VARCHAR(80) PRIMARY KEY,
  svalue TEXT NULL,
  grp VARCHAR(40) NOT NULL DEFAULT 'general',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- ORGANIZATION DATA
CREATE TABLE IF NOT EXISTS branches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL,
  address VARCHAR(255) NULL,
  phone VARCHAR(30) NULL,
  is_head_office TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS departments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS grades (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL UNIQUE,
  level_no INT NOT NULL DEFAULT 1,
  min_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  max_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  annual_increment_percent DECIMAL(5,2) NOT NULL DEFAULT 10,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS designations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  grade_id INT NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS banks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  short_name VARCHAR(30) NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS holidays (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(120) NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  holiday_type ENUM('Government','Festival','Optional','Company') NOT NULL DEFAULT 'Government',
  note VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS work_shifts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  start_time TIME NOT NULL DEFAULT '09:00:00',
  end_time TIME NOT NULL DEFAULT '18:00:00',
  grace_minutes INT NOT NULL DEFAULT 10,
  half_day_hours DECIMAL(4,2) NOT NULL DEFAULT 4,
  weekly_off VARCHAR(40) NOT NULL DEFAULT 'Fri',
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- SALARY CONFIGURATION
CREATE TABLE IF NOT EXISTS salary_heads (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(80) NOT NULL,
  head_type ENUM('earning','deduction') NOT NULL DEFAULT 'earning',
  calc_type ENUM('fixed','percent_basic','percent_gross') NOT NULL DEFAULT 'fixed',
  default_value DECIMAL(12,2) NOT NULL DEFAULT 0,
  is_basic TINYINT(1) NOT NULL DEFAULT 0,
  is_taxable TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT NOT NULL DEFAULT 10,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS grade_structures (
  id INT AUTO_INCREMENT PRIMARY KEY,
  grade_id INT NOT NULL,
  head_id INT NOT NULL,
  calc_type ENUM('fixed','percent_basic','percent_gross') NOT NULL DEFAULT 'fixed',
  value DECIMAL(12,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_grade_head (grade_id, head_id),
  FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE,
  FOREIGN KEY (head_id) REFERENCES salary_heads(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fund_policies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fund_type ENUM('PF','WF','INS','OSF','EPS','GRATUITY') NOT NULL,
  name VARCHAR(120) NOT NULL,
  employee_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
  company_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
  base ENUM('basic','gross') NOT NULL DEFAULT 'basic',
  interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
  eligibility_months INT NOT NULL DEFAULT 0,
  min_service_years DECIMAL(4,1) NOT NULL DEFAULT 0,
  multiplier DECIMAL(5,2) NOT NULL DEFAULT 1,
  max_withdraw_percent DECIMAL(5,2) NOT NULL DEFAULT 100,
  effective_from DATE NULL,
  notes VARCHAR(255) NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vehicle_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  max_loan_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
  max_installments INT NOT NULL DEFAULT 60,
  min_grade_level INT NOT NULL DEFAULT 1,
  fuel_allowance DECIMAL(12,2) NOT NULL DEFAULT 0,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS income_tax_slabs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fiscal_year VARCHAR(9) NOT NULL,
  category ENUM('General','Female','Senior','Disabled') NOT NULL DEFAULT 'General',
  slab_order INT NOT NULL DEFAULT 1,
  slab_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  rate DECIMAL(5,2) NOT NULL DEFAULT 0,
  note VARCHAR(120) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS org_letter_templates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  letter_type VARCHAR(40) NOT NULL,
  name VARCHAR(120) NOT NULL,
  subject VARCHAR(200) NULL,
  body TEXT NOT NULL,
  signatory_name VARCHAR(120) NULL,
  signatory_title VARCHAR(120) NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS id_card_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  accent_color VARCHAR(9) NOT NULL DEFAULT '#1f6b2a',
  validity_years INT NOT NULL DEFAULT 2,
  show_blood_group TINYINT(1) NOT NULL DEFAULT 1,
  show_qr TINYINT(1) NOT NULL DEFAULT 1,
  footer_text VARCHAR(200) NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS periodic_report_configs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  report_key VARCHAR(60) NOT NULL,
  frequency ENUM('Daily','Weekly','Monthly','Quarterly','Yearly') NOT NULL DEFAULT 'Monthly',
  run_day INT NOT NULL DEFAULT 1,
  recipients VARCHAR(255) NULL,
  branch_id INT NULL,
  department_id INT NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS assessment_criteria (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  weight DECIMAL(5,2) NOT NULL DEFAULT 10,
  max_score INT NOT NULL DEFAULT 10,
  department_id INT NULL,
  description VARCHAR(255) NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS rating_scales (
  id INT AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(60) NOT NULL,
  min_percent DECIMAL(5,2) NOT NULL,
  max_percent DECIMAL(5,2) NOT NULL,
  recommendation ENUM('Promotion','Increment','Confirm','Extend Probation','Warning','No Action') NOT NULL DEFAULT 'No Action',
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- EMPLOYEES
CREATE TABLE IF NOT EXISTS employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  emp_code VARCHAR(30) NOT NULL UNIQUE,
  full_name VARCHAR(150) NOT NULL,
  father_name VARCHAR(120) NULL,
  mother_name VARCHAR(120) NULL,
  gender ENUM('Male','Female','Other') NOT NULL DEFAULT 'Male',
  dob DATE NULL,
  marital_status ENUM('Single','Married','Divorced','Widowed') NULL,
  religion VARCHAR(30) NULL,
  blood_group VARCHAR(5) NULL,
  nid VARCHAR(30) NULL,
  tin VARCHAR(30) NULL,
  mobile VARCHAR(30) NOT NULL,
  email VARCHAR(150) NULL,
  present_address VARCHAR(255) NULL,
  permanent_address VARCHAR(255) NULL,
  emergency_contact VARCHAR(150) NULL,
  branch_id INT NOT NULL,
  department_id INT NOT NULL,
  designation_id INT NOT NULL,
  grade_id INT NULL,
  employee_type ENUM('Probation','Contract','Permanent','Intern','Part-time') NOT NULL DEFAULT 'Probation',
  status ENUM('Active','Resigned','Terminated','Retired','Inactive') NOT NULL DEFAULT 'Active',
  joining_date DATE NOT NULL,
  probation_months INT NOT NULL DEFAULT 6,
  probation_end_date DATE NULL,
  confirmation_date DATE NULL,
  contract_end_date DATE NULL,
  retirement_date DATE NULL,
  separation_date DATE NULL,
  reporting_boss_id INT NULL,
  shift_id INT NULL,
  basic_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  gross_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  pf_member TINYINT(1) NOT NULL DEFAULT 1,
  wf_member TINYINT(1) NOT NULL DEFAULT 1,
  eps_member TINYINT(1) NOT NULL DEFAULT 0,
  ins_member TINYINT(1) NOT NULL DEFAULT 0,
  osf_member TINYINT(1) NOT NULL DEFAULT 0,
  payment_mode ENUM('Bank','Cash','Cheque') NOT NULL DEFAULT 'Bank',
  photo VARCHAR(255) NULL,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (branch_id), INDEX (department_id), INDEX (status), INDEX (reporting_boss_id),
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  FOREIGN KEY (department_id) REFERENCES departments(id),
  FOREIGN KEY (designation_id) REFERENCES designations(id),
  FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE SET NULL,
  FOREIGN KEY (shift_id) REFERENCES work_shifts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE users ADD CONSTRAINT fk_users_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE SET NULL;
ALTER TABLE employees ADD CONSTRAINT fk_emp_boss FOREIGN KEY (reporting_boss_id) REFERENCES employees(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS employee_salary_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  head_id INT NOT NULL,
  calc_type ENUM('fixed','percent_basic','percent_gross') NOT NULL DEFAULT 'fixed',
  value DECIMAL(12,2) NOT NULL DEFAULT 0,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_emp_head (employee_id, head_id),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
  FOREIGN KEY (head_id) REFERENCES salary_heads(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS employee_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  bank_id INT NULL,
  bank_name VARCHAR(120) NOT NULL,
  branch_name VARCHAR(120) NULL,
  account_name VARCHAR(150) NOT NULL,
  account_no VARCHAR(40) NOT NULL,
  routing_no VARCHAR(20) NULL,
  account_type ENUM('Savings','Current','Salary','Mobile Banking') NOT NULL DEFAULT 'Salary',
  is_primary TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS employee_documents (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  doc_type VARCHAR(60) NOT NULL,
  title VARCHAR(150) NOT NULL,
  file_name VARCHAR(200) NOT NULL,
  stored_name VARCHAR(120) NOT NULL,
  mime VARCHAR(80) NULL,
  size_bytes INT NOT NULL DEFAULT 0,
  uploaded_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS employee_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  event_type VARCHAR(40) NOT NULL,
  title VARCHAR(200) NOT NULL,
  details TEXT NULL,
  effective_date DATE NULL,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (employee_id),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS id_card_print_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  card_type_id INT NULL,
  copy_no INT NOT NULL DEFAULT 1,
  reason VARCHAR(120) NULL,
  printed_by INT NULL,
  printed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS salary_certificate_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ref_no VARCHAR(40) NOT NULL,
  employee_id INT NOT NULL,
  purpose VARCHAR(150) NULL,
  addressed_to VARCHAR(200) NULL,
  gross_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  issue_date DATE NOT NULL,
  printed_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS department_heads (
  id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  branch_id INT NULL,
  employee_id INT NOT NULL,
  from_date DATE NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  FOREIGN KEY (department_id) REFERENCES departments(id),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS report_authorities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  report_group VARCHAR(60) NOT NULL,
  role_id INT NULL,
  employee_id INT NULL,
  can_view TINYINT(1) NOT NULL DEFAULT 1,
  can_export TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  audience ENUM('All','Branch','Department') NOT NULL DEFAULT 'All',
  branch_id INT NULL,
  department_id INT NULL,
  priority ENUM('Normal','Important','Urgent') NOT NULL DEFAULT 'Normal',
  publish_date DATE NOT NULL,
  expire_date DATE NULL,
  created_by INT NULL,
  status ENUM('Draft','Published','Archived') NOT NULL DEFAULT 'Published',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- LEAVE
CREATE TABLE IF NOT EXISTS leave_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL UNIQUE,
  code VARCHAR(10) NOT NULL UNIQUE,
  yearly_quota DECIMAL(5,1) NOT NULL DEFAULT 0,
  is_paid TINYINT(1) NOT NULL DEFAULT 1,
  carry_forward TINYINT(1) NOT NULL DEFAULT 0,
  max_carry DECIMAL(5,1) NOT NULL DEFAULT 0,
  encashable TINYINT(1) NOT NULL DEFAULT 0,
  gender_rule ENUM('Any','Male','Female') NOT NULL DEFAULT 'Any',
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS leave_balances (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  leave_type_id INT NOT NULL,
  year INT NOT NULL,
  opening DECIMAL(5,1) NOT NULL DEFAULT 0,
  entitled DECIMAL(5,1) NOT NULL DEFAULT 0,
  used DECIMAL(5,1) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_bal (employee_id, leave_type_id, year),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
  FOREIGN KEY (leave_type_id) REFERENCES leave_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS leave_applications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  app_no VARCHAR(30) NOT NULL UNIQUE,
  employee_id INT NOT NULL,
  leave_type_id INT NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  days DECIMAL(5,1) NOT NULL DEFAULT 1,
  half_day TINYINT(1) NOT NULL DEFAULT 0,
  reason VARCHAR(255) NULL,
  application_type ENUM('Own','Other','Late') NOT NULL DEFAULT 'Own',
  status ENUM('Pending','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
  applied_by INT NULL,
  approver_employee_id INT NULL,
  decided_by INT NULL,
  decided_at DATETIME NULL,
  decision_note VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (employee_id, status), INDEX (from_date, to_date),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
  FOREIGN KEY (leave_type_id) REFERENCES leave_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- ATTENDANCE
CREATE TABLE IF NOT EXISTS attendance (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  att_date DATE NOT NULL,
  in_time TIME NULL,
  out_time TIME NULL,
  status ENUM('Present','Late','Absent','Leave','Holiday','Weekend','Half Day') NOT NULL DEFAULT 'Present',
  late_minutes INT NOT NULL DEFAULT 0,
  worked_minutes INT NOT NULL DEFAULT 0,
  source ENUM('Manual','Import','Device','Leave') NOT NULL DEFAULT 'Manual',
  remarks VARCHAR(200) NULL,
  UNIQUE KEY uq_att (employee_id, att_date),
  INDEX (att_date),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS attendance_devices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  serial_no VARCHAR(60) NULL,
  api_key VARCHAR(64) NOT NULL UNIQUE,
  device_type ENUM('Fingerprint','Face','Card') NOT NULL DEFAULT 'Fingerprint',
  branch_id INT NULL,
  last_sync DATETIME NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS attendance_import_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  file_name VARCHAR(200) NOT NULL,
  total_rows INT NOT NULL DEFAULT 0,
  success_rows INT NOT NULL DEFAULT 0,
  failed_rows INT NOT NULL DEFAULT 0,
  errors TEXT NULL,
  imported_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- RECRUITMENT
CREATE TABLE IF NOT EXISTS requisitions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  req_no VARCHAR(30) NOT NULL UNIQUE,
  branch_id INT NOT NULL,
  department_id INT NOT NULL,
  designation_id INT NOT NULL,
  vacancies INT NOT NULL DEFAULT 1,
  employment_type ENUM('Permanent','Contract','Intern','Part-time') NOT NULL DEFAULT 'Permanent',
  min_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  max_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  required_date DATE NULL,
  justification VARCHAR(500) NULL,
  requested_by INT NULL,
  status ENUM('Draft','Pending','Approved','Rejected','Closed') NOT NULL DEFAULT 'Pending',
  decided_by INT NULL,
  decided_at DATETIME NULL,
  decision_note VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  FOREIGN KEY (department_id) REFERENCES departments(id),
  FOREIGN KEY (designation_id) REFERENCES designations(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS job_circulars (
  id INT AUTO_INCREMENT PRIMARY KEY,
  circular_no VARCHAR(30) NOT NULL UNIQUE,
  requisition_id INT NULL,
  title VARCHAR(200) NOT NULL,
  branch_id INT NULL,
  department_id INT NULL,
  designation_id INT NULL,
  vacancies INT NOT NULL DEFAULT 1,
  description TEXT NULL,
  requirements TEXT NULL,
  publish_date DATE NULL,
  deadline DATE NULL,
  status ENUM('Draft','Published','Closed') NOT NULL DEFAULT 'Draft',
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (requisition_id) REFERENCES requisitions(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS job_applicants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  circular_id INT NOT NULL,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NULL,
  mobile VARCHAR(30) NULL,
  experience_years DECIMAL(4,1) NOT NULL DEFAULT 0,
  expected_salary DECIMAL(12,2) NOT NULL DEFAULT 0,
  stage ENUM('Applied','Shortlisted','Interviewed','Selected','Rejected','Hired') NOT NULL DEFAULT 'Applied',
  notes VARCHAR(255) NULL,
  employee_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (circular_id) REFERENCES job_circulars(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- PERFORMANCE & PERSONNEL ACTIONS
CREATE TABLE IF NOT EXISTS performance_reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  review_title VARCHAR(120) NOT NULL,
  period_from DATE NOT NULL,
  period_to DATE NOT NULL,
  reviewer_employee_id INT NULL,
  score_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
  rating VARCHAR(60) NULL,
  recommendation VARCHAR(40) NULL,
  comments VARCHAR(500) NULL,
  status ENUM('Draft','Submitted','Finalized') NOT NULL DEFAULT 'Draft',
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS performance_review_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  review_id INT NOT NULL,
  criteria_id INT NOT NULL,
  score DECIMAL(5,2) NOT NULL DEFAULT 0,
  remarks VARCHAR(255) NULL,
  FOREIGN KEY (review_id) REFERENCES performance_reviews(id) ON DELETE CASCADE,
  FOREIGN KEY (criteria_id) REFERENCES assessment_criteria(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS personnel_actions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ref_no VARCHAR(30) NOT NULL UNIQUE,
  action_type ENUM('promotion','demotion','permanent','increment','transfer','resign','terminate','retirement') NOT NULL,
  employee_id INT NOT NULL,
  effective_date DATE NOT NULL,
  review_id INT NULL,
  from_designation_id INT NULL,
  to_designation_id INT NULL,
  from_grade_id INT NULL,
  to_grade_id INT NULL,
  old_basic DECIMAL(12,2) NULL,
  new_basic DECIMAL(12,2) NULL,
  percent DECIMAL(5,2) NULL,
  from_branch_id INT NULL,
  to_branch_id INT NULL,
  from_department_id INT NULL,
  to_department_id INT NULL,
  sub_type VARCHAR(40) NULL,
  extension_months INT NULL,
  notice_days INT NULL,
  last_working_date DATE NULL,
  reason VARCHAR(500) NULL,
  status ENUM('Pending','Approved','Rejected','Cancelled','Completed') NOT NULL DEFAULT 'Pending',
  requested_by INT NULL,
  decided_by INT NULL,
  decided_at DATETIME NULL,
  decision_note VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (employee_id), INDEX (action_type, status),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS salary_reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  review_no VARCHAR(30) NOT NULL UNIQUE,
  title VARCHAR(150) NOT NULL,
  grade_id INT NULL,
  percent DECIMAL(5,2) NOT NULL DEFAULT 10,
  calc_method ENUM('simple','compound') NOT NULL DEFAULT 'simple',
  effective_date DATE NOT NULL,
  min_service_months INT NOT NULL DEFAULT 12,
  status ENUM('Draft','Approved','Applied','Rejected') NOT NULL DEFAULT 'Draft',
  remarks VARCHAR(255) NULL,
  created_by INT NULL,
  approved_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS salary_review_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  review_id INT NOT NULL,
  employee_id INT NOT NULL,
  old_basic DECIMAL(12,2) NOT NULL,
  new_basic DECIMAL(12,2) NOT NULL,
  increase DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (review_id) REFERENCES salary_reviews(id) ON DELETE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- ACCOUNTS, LOANS & FUNDS
CREATE TABLE IF NOT EXISTS loan_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE,
  kind ENUM('advance_salary','pf_loan','vehicle_loan','other') NOT NULL DEFAULT 'other',
  max_salary_multiple DECIMAL(5,2) NOT NULL DEFAULT 0,
  max_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
  max_installments INT NOT NULL DEFAULT 12,
  min_service_months INT NOT NULL DEFAULT 6,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS loans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_no VARCHAR(30) NOT NULL UNIQUE,
  employee_id INT NOT NULL,
  loan_type_id INT NOT NULL,
  vehicle_type_id INT NULL,
  amount DECIMAL(12,2) NOT NULL,
  interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
  installments INT NOT NULL DEFAULT 1,
  installment_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_payable DECIMAL(12,2) NOT NULL DEFAULT 0,
  start_month DATE NOT NULL,
  purpose VARCHAR(255) NULL,
  status ENUM('Pending','Approved','Rejected','Running','Closed','Settled') NOT NULL DEFAULT 'Pending',
  is_opening TINYINT(1) NOT NULL DEFAULT 0,
  requested_by INT NULL,
  decided_by INT NULL,
  decided_at DATETIME NULL,
  decision_note VARCHAR(255) NULL,
  disbursed_on DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (employee_id, status),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
  FOREIGN KEY (loan_type_id) REFERENCES loan_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS loan_installments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_id INT NOT NULL,
  installment_no INT NOT NULL,
  due_month DATE NOT NULL,
  principal DECIMAL(12,2) NOT NULL DEFAULT 0,
  interest DECIMAL(12,2) NOT NULL DEFAULT 0,
  amount DECIMAL(12,2) NOT NULL,
  status ENUM('Due','Paid','Settled') NOT NULL DEFAULT 'Due',
  paid_on DATE NULL,
  payroll_run_id INT NULL,
  INDEX (due_month, status),
  FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS edps_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  account_no VARCHAR(30) NOT NULL UNIQUE,
  employee_id INT NOT NULL,
  monthly_deposit DECIMAL(12,2) NOT NULL,
  interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
  term_months INT NOT NULL DEFAULT 60,
  start_date DATE NOT NULL,
  maturity_date DATE NOT NULL,
  balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  status ENUM('Active','Matured','Closed') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS edps_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  edps_id INT NOT NULL,
  tx_date DATE NOT NULL,
  tx_type ENUM('Deposit','Interest','Withdraw','Opening') NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  payroll_run_id INT NULL,
  note VARCHAR(150) NULL,
  FOREIGN KEY (edps_id) REFERENCES edps_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS early_settlements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ref_no VARCHAR(30) NOT NULL UNIQUE,
  settle_type ENUM('loan','edps') NOT NULL,
  loan_id INT NULL,
  edps_id INT NULL,
  employee_id INT NOT NULL,
  settlement_date DATE NOT NULL,
  outstanding DECIMAL(14,2) NOT NULL DEFAULT 0,
  penalty_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
  penalty_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  net_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  remarks VARCHAR(255) NULL,
  status ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  requested_by INT NULL,
  decided_by INT NULL,
  decided_at DATETIME NULL,
  decision_note VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS salary_deductions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  deduction_type ENUM('Disciplinary','Demotion','Damage','Advance Recovery','Other') NOT NULL DEFAULT 'Other',
  total_amount DECIMAL(12,2) NOT NULL,
  installments INT NOT NULL DEFAULT 1,
  monthly_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  from_month DATE NOT NULL,
  deducted_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  deducted_count INT NOT NULL DEFAULT 0,
  reason VARCHAR(255) NULL,
  status ENUM('Active','Completed','Cancelled') NOT NULL DEFAULT 'Active',
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS employee_tax_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  fiscal_year VARCHAR(9) NOT NULL,
  tax_category ENUM('General','Female','Senior','Disabled') NOT NULL DEFAULT 'General',
  tin VARCHAR(30) NULL,
  investment_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  other_income DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_override DECIMAL(12,2) NULL,
  exempt TINYINT(1) NOT NULL DEFAULT 0,
  note VARCHAR(255) NULL,
  UNIQUE KEY uq_tax (employee_id, fiscal_year),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tax_challans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  challan_no VARCHAR(40) NOT NULL,
  deposit_date DATE NOT NULL,
  period_month DATE NOT NULL,
  bank_name VARCHAR(120) NULL,
  amount DECIMAL(14,2) NOT NULL,
  note VARCHAR(255) NULL,
  created_by INT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fund_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  fund_type ENUM('PF','WF','EPS','OSF','INS') NOT NULL,
  tx_date DATE NOT NULL,
  tx_type ENUM('Opening','Employee','Company','Interest','Withdraw','Adjust') NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  payroll_run_id INT NULL,
  ref_note VARCHAR(150) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (employee_id, fund_type), INDEX (payroll_run_id),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fund_withdrawals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ref_no VARCHAR(30) NOT NULL UNIQUE,
  employee_id INT NOT NULL,
  fund_type ENUM('PF','WF','EPS','OSF','INS') NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  balance_at_request DECIMAL(14,2) NOT NULL DEFAULT 0,
  request_date DATE NOT NULL,
  reason VARCHAR(255) NULL,
  status ENUM('Pending','Approved','Rejected','Paid') NOT NULL DEFAULT 'Pending',
  requested_by INT NULL,
  decided_by INT NULL,
  decided_at DATETIME NULL,
  decision_note VARCHAR(255) NULL,
  paid_on DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS opening_balances (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  balance_type ENUM('Leave','PF','WF','EPS','OSF','INS','EDPS','Loan') NOT NULL,
  leave_type_id INT NULL,
  loan_type_id INT NULL,
  amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  installments_left INT NULL,
  as_of_date DATE NOT NULL,
  remarks VARCHAR(200) NULL,
  applied TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------- PAYROLL
CREATE TABLE IF NOT EXISTS payroll_runs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  run_no VARCHAR(30) NOT NULL UNIQUE,
  run_type ENUM('monthly','final') NOT NULL DEFAULT 'monthly',
  period_month DATE NOT NULL,
  period_from DATE NOT NULL,
  period_to DATE NOT NULL,
  branch_id INT NULL,
  department_id INT NULL,
  status ENUM('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  employee_count INT NOT NULL DEFAULT 0,
  total_gross DECIMAL(16,2) NOT NULL DEFAULT 0,
  total_deduction DECIMAL(16,2) NOT NULL DEFAULT 0,
  total_net DECIMAL(16,2) NOT NULL DEFAULT 0,
  notes VARCHAR(255) NULL,
  generated_by INT NULL,
  approved_by INT NULL,
  approved_at DATETIME NULL,
  paid_on DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (period_month, run_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS payslips (
  id INT AUTO_INCREMENT PRIMARY KEY,
  run_id INT NOT NULL,
  employee_id INT NOT NULL,
  period_month DATE NOT NULL,
  calendar_days INT NOT NULL DEFAULT 30,
  present_days DECIMAL(5,1) NOT NULL DEFAULT 0,
  absent_days DECIMAL(5,1) NOT NULL DEFAULT 0,
  leave_days DECIMAL(5,1) NOT NULL DEFAULT 0,
  late_days INT NOT NULL DEFAULT 0,
  paid_days DECIMAL(5,1) NOT NULL DEFAULT 0,
  basic DECIMAL(12,2) NOT NULL DEFAULT 0,
  gross DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_earning DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_deduction DECIMAL(12,2) NOT NULL DEFAULT 0,
  net_pay DECIMAL(12,2) NOT NULL DEFAULT 0,
  pf_employee DECIMAL(12,2) NOT NULL DEFAULT 0,
  pf_company DECIMAL(12,2) NOT NULL DEFAULT 0,
  wf_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  eps_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  loan_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  edps_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  payment_status ENUM('Unpaid','Paid','Hold') NOT NULL DEFAULT 'Unpaid',
  payment_mode VARCHAR(20) NULL,
  account_no VARCHAR(40) NULL,
  paid_on DATE NULL,
  remarks VARCHAR(255) NULL,
  UNIQUE KEY uq_slip (run_id, employee_id),
  INDEX (employee_id, period_month),
  FOREIGN KEY (run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS payslip_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  payslip_id INT NOT NULL,
  head_name VARCHAR(100) NOT NULL,
  item_type ENUM('earning','deduction') NOT NULL,
  source VARCHAR(20) NOT NULL DEFAULT 'head',
  ref_id INT NULL,
  amount DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (payslip_id) REFERENCES payslips(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS payroll_adjustments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  period_month DATE NOT NULL,
  adj_type ENUM('earning','deduction') NOT NULL DEFAULT 'earning',
  title VARCHAR(120) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  applied TINYINT(1) NOT NULL DEFAULT 0,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS salary_dues (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  period_month DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  reason VARCHAR(255) NULL,
  payslip_id INT NULL,
  status ENUM('Due','Paid','Cancelled') NOT NULL DEFAULT 'Due',
  paid_on DATE NULL,
  paid_mode VARCHAR(20) NULL,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (status),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS festival_bonuses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bonus_no VARCHAR(30) NOT NULL UNIQUE,
  title VARCHAR(120) NOT NULL,
  bonus_date DATE NOT NULL,
  percent_of_basic DECIMAL(5,2) NOT NULL DEFAULT 100,
  min_service_months INT NOT NULL DEFAULT 6,
  proportional TINYINT(1) NOT NULL DEFAULT 1,
  religion VARCHAR(30) NULL,
  status ENUM('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  total_amount DECIMAL(16,2) NOT NULL DEFAULT 0,
  created_by INT NULL,
  approved_by INT NULL,
  paid_on DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS festival_bonus_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bonus_id INT NOT NULL,
  employee_id INT NOT NULL,
  basic DECIMAL(12,2) NOT NULL,
  service_months INT NOT NULL DEFAULT 0,
  gross_bonus DECIMAL(12,2) NOT NULL,
  tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  net_bonus DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (bonus_id) REFERENCES festival_bonuses(id) ON DELETE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS interest_runs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  run_no VARCHAR(30) NOT NULL UNIQUE,
  fund_type ENUM('PF','WF','EPS','EDPS') NOT NULL,
  period_from DATE NOT NULL,
  period_to DATE NOT NULL,
  rate_percent DECIMAL(5,2) NOT NULL,
  status ENUM('Draft','Posted') NOT NULL DEFAULT 'Draft',
  total_interest DECIMAL(16,2) NOT NULL DEFAULT 0,
  created_by INT NULL,
  posted_at DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS interest_run_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  run_id INT NOT NULL,
  employee_id INT NOT NULL,
  account_ref INT NULL,
  base_balance DECIMAL(14,2) NOT NULL,
  interest DECIMAL(14,2) NOT NULL,
  FOREIGN KEY (run_id) REFERENCES interest_runs(id) ON DELETE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS gratuities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ref_no VARCHAR(30) NOT NULL UNIQUE,
  employee_id INT NOT NULL,
  calc_date DATE NOT NULL,
  service_years DECIMAL(5,2) NOT NULL DEFAULT 0,
  counted_years INT NOT NULL DEFAULT 0,
  last_basic DECIMAL(12,2) NOT NULL DEFAULT 0,
  multiplier DECIMAL(5,2) NOT NULL DEFAULT 1,
  amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  status ENUM('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  final_payment_id INT NULL,
  paid_on DATE NULL,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS final_payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fp_no VARCHAR(30) NOT NULL UNIQUE,
  employee_id INT NOT NULL,
  action_id INT NULL,
  sep_type ENUM('Resign','Terminate','Retirement') NOT NULL,
  last_working_date DATE NOT NULL,
  service_years DECIMAL(5,2) NOT NULL DEFAULT 0,
  salary_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  leave_days DECIMAL(5,1) NOT NULL DEFAULT 0,
  leave_encash_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  gratuity_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  pf_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  wf_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  eps_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  edps_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  other_earning DECIMAL(14,2) NOT NULL DEFAULT 0,
  loan_deduction DECIMAL(14,2) NOT NULL DEFAULT 0,
  notice_deduction DECIMAL(14,2) NOT NULL DEFAULT 0,
  tax_deduction DECIMAL(14,2) NOT NULL DEFAULT 0,
  other_deduction DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_earning DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_deduction DECIMAL(14,2) NOT NULL DEFAULT 0,
  net_payable DECIMAL(14,2) NOT NULL DEFAULT 0,
  breakdown TEXT NULL,
  status ENUM('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  remarks VARCHAR(255) NULL,
  created_by INT NULL,
  approved_by INT NULL,
  paid_on DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
