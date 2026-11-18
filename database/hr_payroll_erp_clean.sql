
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

/*!40000 DROP DATABASE IF EXISTS `hr_payroll_erp`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hr_payroll_erp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `hr_payroll_erp`;
DROP TABLE IF EXISTS `assessment_criteria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessment_criteria` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `weight` decimal(5,2) NOT NULL DEFAULT 10.00,
  `max_score` int(11) NOT NULL DEFAULT 10,
  `department_id` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `assessment_criteria` DISABLE KEYS */;
INSERT INTO `assessment_criteria` VALUES
(1,'Quality of work',20.00,10,NULL,NULL,'Active'),
(2,'Productivity & delivery',20.00,10,NULL,NULL,'Active'),
(3,'Teamwork & communication',15.00,10,NULL,NULL,'Active'),
(4,'Attendance & punctuality',15.00,10,NULL,NULL,'Active'),
(5,'Initiative & learning',15.00,10,NULL,NULL,'Active'),
(6,'Discipline & conduct',15.00,10,NULL,NULL,'Active');
/*!40000 ALTER TABLE `assessment_criteria` ENABLE KEYS */;
DROP TABLE IF EXISTS `attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `att_date` date NOT NULL,
  `in_time` time DEFAULT NULL,
  `out_time` time DEFAULT NULL,
  `status` enum('Present','Late','Absent','Leave','Holiday','Weekend','Half Day') NOT NULL DEFAULT 'Present',
  `late_minutes` int(11) NOT NULL DEFAULT 0,
  `worked_minutes` int(11) NOT NULL DEFAULT 0,
  `source` enum('Manual','Import','Device','Leave') NOT NULL DEFAULT 'Manual',
  `remarks` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_att` (`employee_id`,`att_date`),
  KEY `att_date` (`att_date`),
  CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `attendance` DISABLE KEYS */;
/*!40000 ALTER TABLE `attendance` ENABLE KEYS */;
DROP TABLE IF EXISTS `attendance_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `serial_no` varchar(60) DEFAULT NULL,
  `api_key` varchar(64) NOT NULL,
  `device_type` enum('Fingerprint','Face','Card') NOT NULL DEFAULT 'Fingerprint',
  `branch_id` int(11) DEFAULT NULL,
  `last_sync` datetime DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `api_key` (`api_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `attendance_devices` DISABLE KEYS */;
/*!40000 ALTER TABLE `attendance_devices` ENABLE KEYS */;
DROP TABLE IF EXISTS `attendance_import_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance_import_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `file_name` varchar(200) NOT NULL,
  `total_rows` int(11) NOT NULL DEFAULT 0,
  `success_rows` int(11) NOT NULL DEFAULT 0,
  `failed_rows` int(11) NOT NULL DEFAULT 0,
  `errors` text DEFAULT NULL,
  `imported_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `attendance_import_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `attendance_import_logs` ENABLE KEYS */;
DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `entity` varchar(60) NOT NULL,
  `entity_id` varchar(40) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `entity` (`entity`,`entity_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
DROP TABLE IF EXISTS `banks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `banks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `short_name` varchar(30) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `banks` DISABLE KEYS */;
INSERT INTO `banks` VALUES
(1,'Sonali Bank',NULL,'Active'),
(2,'Janata Bank',NULL,'Active'),
(3,'Agrani Bank',NULL,'Active'),
(4,'Rupali Bank',NULL,'Active'),
(5,'Islami Bank Bangladesh',NULL,'Active'),
(6,'Dutch-Bangla Bank',NULL,'Active'),
(7,'BRAC Bank',NULL,'Active'),
(8,'City Bank',NULL,'Active'),
(9,'Eastern Bank',NULL,'Active'),
(10,'Prime Bank',NULL,'Active'),
(11,'bKash',NULL,'Active');
/*!40000 ALTER TABLE `banks` ENABLE KEYS */;
DROP TABLE IF EXISTS `branches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `branches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name` varchar(120) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `is_head_office` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `branches` DISABLE KEYS */;
INSERT INTO `branches` VALUES
(1,'HO','Head Office','Dhaka',NULL,1,'Active');
/*!40000 ALTER TABLE `branches` ENABLE KEYS */;
DROP TABLE IF EXISTS `delegation_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `delegation_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `authority` varchar(80) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_delegable` tinyint(1) NOT NULL DEFAULT 1,
  `max_days` int(11) NOT NULL DEFAULT 30,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `authority` (`authority`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `delegation_rules` DISABLE KEYS */;
INSERT INTO `delegation_rules` VALUES
(1,'All approvals','Every approval the delegator holds',1,30,'Active'),
(2,'Leave approval','Approve leave of the team',1,30,'Active'),
(3,'Requisition approval','Approve manpower requisitions',1,15,'Active'),
(4,'Personnel actions','Promotion, transfer, confirmation etc.',1,15,'Active'),
(5,'Loan approval','Approve loans and withdrawals',1,15,'Active');
/*!40000 ALTER TABLE `delegation_rules` ENABLE KEYS */;
DROP TABLE IF EXISTS `delegations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `delegations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `from_user_id` int(11) NOT NULL,
  `to_user_id` int(11) NOT NULL,
  `from_date` date NOT NULL,
  `to_date` date NOT NULL,
  `authority` varchar(80) NOT NULL DEFAULT 'All approvals',
  `reason` varchar(255) DEFAULT NULL,
  `status` enum('Active','Revoked') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `from_user_id` (`from_user_id`),
  KEY `to_user_id` (`to_user_id`),
  CONSTRAINT `delegations_ibfk_1` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `delegations_ibfk_2` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `delegations` DISABLE KEYS */;
/*!40000 ALTER TABLE `delegations` ENABLE KEYS */;
DROP TABLE IF EXISTS `department_heads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `department_heads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `department_id` int(11) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `employee_id` int(11) NOT NULL,
  `from_date` date DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  KEY `department_id` (`department_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `department_heads_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  CONSTRAINT `department_heads_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `department_heads` DISABLE KEYS */;
/*!40000 ALTER TABLE `department_heads` ENABLE KEYS */;
DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `departments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name` varchar(120) NOT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `departments` DISABLE KEYS */;
INSERT INTO `departments` VALUES
(1,'HR','Human Resources','Active'),
(2,'FIN','Finance & Accounts','Active'),
(3,'IT','Information Technology','Active'),
(4,'OPS','Operations','Active'),
(5,'SALES','Sales & Marketing','Active');
/*!40000 ALTER TABLE `departments` ENABLE KEYS */;
DROP TABLE IF EXISTS `designations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `designations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `grade_id` int(11) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  KEY `grade_id` (`grade_id`),
  CONSTRAINT `designations_ibfk_1` FOREIGN KEY (`grade_id`) REFERENCES `grades` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `designations` DISABLE KEYS */;
INSERT INTO `designations` VALUES
(1,'Chief Executive Officer',1,'Active'),
(2,'General Manager',2,'Active'),
(3,'Senior Manager',3,'Active'),
(4,'Manager',4,'Active'),
(5,'Senior Executive',5,'Active'),
(6,'Executive',6,'Active'),
(7,'Officer',7,'Active'),
(8,'Junior Officer',8,'Active'),
(9,'Software Engineer',6,'Active'),
(10,'Senior Software Engineer',5,'Active'),
(11,'Accountant',6,'Active'),
(12,'HR Officer',7,'Active');
/*!40000 ALTER TABLE `designations` ENABLE KEYS */;
DROP TABLE IF EXISTS `early_settlements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `early_settlements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref_no` varchar(30) NOT NULL,
  `settle_type` enum('loan','edps') NOT NULL,
  `loan_id` int(11) DEFAULT NULL,
  `edps_id` int(11) DEFAULT NULL,
  `employee_id` int(11) NOT NULL,
  `settlement_date` date NOT NULL,
  `outstanding` decimal(14,2) NOT NULL DEFAULT 0.00,
  `penalty_percent` decimal(5,2) NOT NULL DEFAULT 0.00,
  `penalty_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `net_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `remarks` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `requested_by` int(11) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ref_no` (`ref_no`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `early_settlements_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `early_settlements` DISABLE KEYS */;
/*!40000 ALTER TABLE `early_settlements` ENABLE KEYS */;
DROP TABLE IF EXISTS `edps_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `edps_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_no` varchar(30) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `monthly_deposit` decimal(12,2) NOT NULL,
  `interest_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `term_months` int(11) NOT NULL DEFAULT 60,
  `start_date` date NOT NULL,
  `maturity_date` date NOT NULL,
  `balance` decimal(14,2) NOT NULL DEFAULT 0.00,
  `status` enum('Active','Matured','Closed') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_no` (`account_no`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `edps_accounts_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `edps_accounts` DISABLE KEYS */;
/*!40000 ALTER TABLE `edps_accounts` ENABLE KEYS */;
DROP TABLE IF EXISTS `edps_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `edps_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `edps_id` int(11) NOT NULL,
  `tx_date` date NOT NULL,
  `tx_type` enum('Deposit','Interest','Withdraw','Opening') NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `payroll_run_id` int(11) DEFAULT NULL,
  `note` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `edps_id` (`edps_id`),
  CONSTRAINT `edps_transactions_ibfk_1` FOREIGN KEY (`edps_id`) REFERENCES `edps_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `edps_transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `edps_transactions` ENABLE KEYS */;
DROP TABLE IF EXISTS `employee_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `bank_id` int(11) DEFAULT NULL,
  `bank_name` varchar(120) NOT NULL,
  `branch_name` varchar(120) DEFAULT NULL,
  `account_name` varchar(150) NOT NULL,
  `account_no` varchar(40) NOT NULL,
  `routing_no` varchar(20) DEFAULT NULL,
  `account_type` enum('Savings','Current','Salary','Mobile Banking') NOT NULL DEFAULT 'Salary',
  `is_primary` tinyint(1) NOT NULL DEFAULT 1,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `employee_accounts_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `employee_accounts` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee_accounts` ENABLE KEYS */;
DROP TABLE IF EXISTS `employee_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `doc_type` varchar(60) NOT NULL,
  `title` varchar(150) NOT NULL,
  `file_name` varchar(200) NOT NULL,
  `stored_name` varchar(120) NOT NULL,
  `mime` varchar(80) DEFAULT NULL,
  `size_bytes` int(11) NOT NULL DEFAULT 0,
  `uploaded_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `employee_documents_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `employee_documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee_documents` ENABLE KEYS */;
DROP TABLE IF EXISTS `employee_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `event_type` varchar(40) NOT NULL,
  `title` varchar(200) NOT NULL,
  `details` text DEFAULT NULL,
  `effective_date` date DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `employee_history_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `employee_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee_history` ENABLE KEYS */;
DROP TABLE IF EXISTS `employee_salary_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_salary_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `head_id` int(11) NOT NULL,
  `calc_type` enum('fixed','percent_basic','percent_gross') NOT NULL DEFAULT 'fixed',
  `value` decimal(12,2) NOT NULL DEFAULT 0.00,
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_emp_head` (`employee_id`,`head_id`),
  KEY `head_id` (`head_id`),
  CONSTRAINT `employee_salary_items_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `employee_salary_items_ibfk_2` FOREIGN KEY (`head_id`) REFERENCES `salary_heads` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `employee_salary_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee_salary_items` ENABLE KEYS */;
DROP TABLE IF EXISTS `employee_tax_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_tax_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `fiscal_year` varchar(9) NOT NULL,
  `tax_category` enum('General','Female','Senior','Disabled') NOT NULL DEFAULT 'General',
  `tin` varchar(30) DEFAULT NULL,
  `investment_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `other_income` decimal(12,2) NOT NULL DEFAULT 0.00,
  `tax_override` decimal(12,2) DEFAULT NULL,
  `exempt` tinyint(1) NOT NULL DEFAULT 0,
  `note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tax` (`employee_id`,`fiscal_year`),
  CONSTRAINT `employee_tax_profiles_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `employee_tax_profiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee_tax_profiles` ENABLE KEYS */;
DROP TABLE IF EXISTS `employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_code` varchar(30) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `father_name` varchar(120) DEFAULT NULL,
  `mother_name` varchar(120) DEFAULT NULL,
  `gender` enum('Male','Female','Other') NOT NULL DEFAULT 'Male',
  `dob` date DEFAULT NULL,
  `marital_status` enum('Single','Married','Divorced','Widowed') DEFAULT NULL,
  `religion` varchar(30) DEFAULT NULL,
  `blood_group` varchar(5) DEFAULT NULL,
  `nid` varchar(30) DEFAULT NULL,
  `tin` varchar(30) DEFAULT NULL,
  `mobile` varchar(30) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `present_address` varchar(255) DEFAULT NULL,
  `permanent_address` varchar(255) DEFAULT NULL,
  `emergency_contact` varchar(150) DEFAULT NULL,
  `branch_id` int(11) NOT NULL,
  `department_id` int(11) NOT NULL,
  `designation_id` int(11) NOT NULL,
  `grade_id` int(11) DEFAULT NULL,
  `employee_type` enum('Probation','Contract','Permanent','Intern','Part-time') NOT NULL DEFAULT 'Probation',
  `status` enum('Active','Resigned','Terminated','Retired','Inactive') NOT NULL DEFAULT 'Active',
  `joining_date` date NOT NULL,
  `probation_months` int(11) NOT NULL DEFAULT 6,
  `probation_end_date` date DEFAULT NULL,
  `confirmation_date` date DEFAULT NULL,
  `contract_end_date` date DEFAULT NULL,
  `retirement_date` date DEFAULT NULL,
  `separation_date` date DEFAULT NULL,
  `reporting_boss_id` int(11) DEFAULT NULL,
  `shift_id` int(11) DEFAULT NULL,
  `basic_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `gross_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `pf_member` tinyint(1) NOT NULL DEFAULT 1,
  `wf_member` tinyint(1) NOT NULL DEFAULT 1,
  `eps_member` tinyint(1) NOT NULL DEFAULT 0,
  `ins_member` tinyint(1) NOT NULL DEFAULT 0,
  `osf_member` tinyint(1) NOT NULL DEFAULT 0,
  `payment_mode` enum('Bank','Cash','Cheque') NOT NULL DEFAULT 'Bank',
  `photo` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `emp_code` (`emp_code`),
  KEY `branch_id` (`branch_id`),
  KEY `department_id` (`department_id`),
  KEY `status` (`status`),
  KEY `reporting_boss_id` (`reporting_boss_id`),
  KEY `designation_id` (`designation_id`),
  KEY `grade_id` (`grade_id`),
  KEY `shift_id` (`shift_id`),
  CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT `employees_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  CONSTRAINT `employees_ibfk_3` FOREIGN KEY (`designation_id`) REFERENCES `designations` (`id`),
  CONSTRAINT `employees_ibfk_4` FOREIGN KEY (`grade_id`) REFERENCES `grades` (`id`) ON DELETE SET NULL,
  CONSTRAINT `employees_ibfk_5` FOREIGN KEY (`shift_id`) REFERENCES `work_shifts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_emp_boss` FOREIGN KEY (`reporting_boss_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `employees` DISABLE KEYS */;
/*!40000 ALTER TABLE `employees` ENABLE KEYS */;
DROP TABLE IF EXISTS `festival_bonus_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `festival_bonus_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bonus_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `basic` decimal(12,2) NOT NULL,
  `service_months` int(11) NOT NULL DEFAULT 0,
  `gross_bonus` decimal(12,2) NOT NULL,
  `tax_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `net_bonus` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `bonus_id` (`bonus_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `festival_bonus_items_ibfk_1` FOREIGN KEY (`bonus_id`) REFERENCES `festival_bonuses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `festival_bonus_items_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `festival_bonus_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `festival_bonus_items` ENABLE KEYS */;
DROP TABLE IF EXISTS `festival_bonuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `festival_bonuses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bonus_no` varchar(30) NOT NULL,
  `title` varchar(120) NOT NULL,
  `bonus_date` date NOT NULL,
  `percent_of_basic` decimal(5,2) NOT NULL DEFAULT 100.00,
  `min_service_months` int(11) NOT NULL DEFAULT 6,
  `proportional` tinyint(1) NOT NULL DEFAULT 1,
  `religion` varchar(30) DEFAULT NULL,
  `status` enum('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  `total_amount` decimal(16,2) NOT NULL DEFAULT 0.00,
  `created_by` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `bonus_no` (`bonus_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `festival_bonuses` DISABLE KEYS */;
/*!40000 ALTER TABLE `festival_bonuses` ENABLE KEYS */;
DROP TABLE IF EXISTS `final_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `final_payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fp_no` varchar(30) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `action_id` int(11) DEFAULT NULL,
  `sep_type` enum('Resign','Terminate','Retirement') NOT NULL,
  `last_working_date` date NOT NULL,
  `service_years` decimal(5,2) NOT NULL DEFAULT 0.00,
  `salary_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `leave_days` decimal(5,1) NOT NULL DEFAULT 0.0,
  `leave_encash_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `gratuity_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `pf_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `wf_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `eps_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `edps_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `other_earning` decimal(14,2) NOT NULL DEFAULT 0.00,
  `loan_deduction` decimal(14,2) NOT NULL DEFAULT 0.00,
  `notice_deduction` decimal(14,2) NOT NULL DEFAULT 0.00,
  `tax_deduction` decimal(14,2) NOT NULL DEFAULT 0.00,
  `other_deduction` decimal(14,2) NOT NULL DEFAULT 0.00,
  `total_earning` decimal(14,2) NOT NULL DEFAULT 0.00,
  `total_deduction` decimal(14,2) NOT NULL DEFAULT 0.00,
  `net_payable` decimal(14,2) NOT NULL DEFAULT 0.00,
  `breakdown` text DEFAULT NULL,
  `status` enum('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  `remarks` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `fp_no` (`fp_no`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `final_payments_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `final_payments` DISABLE KEYS */;
/*!40000 ALTER TABLE `final_payments` ENABLE KEYS */;
DROP TABLE IF EXISTS `fund_policies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fund_policies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fund_type` enum('PF','WF','INS','OSF','EPS','GRATUITY') NOT NULL,
  `name` varchar(120) NOT NULL,
  `employee_percent` decimal(5,2) NOT NULL DEFAULT 0.00,
  `company_percent` decimal(5,2) NOT NULL DEFAULT 0.00,
  `base` enum('basic','gross') NOT NULL DEFAULT 'basic',
  `interest_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `eligibility_months` int(11) NOT NULL DEFAULT 0,
  `min_service_years` decimal(4,1) NOT NULL DEFAULT 0.0,
  `multiplier` decimal(5,2) NOT NULL DEFAULT 1.00,
  `max_withdraw_percent` decimal(5,2) NOT NULL DEFAULT 100.00,
  `effective_from` date DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `fund_policies` DISABLE KEYS */;
INSERT INTO `fund_policies` VALUES
(1,'PF','Provident Fund Policy',10.00,10.00,'basic',10.00,6,0.0,1.00,80.00,'2026-01-01',NULL,'Active'),
(2,'WF','Welfare Fund Policy',2.00,1.00,'basic',0.00,3,0.0,1.00,100.00,'2026-01-01',NULL,'Active'),
(3,'EPS','Employee Pension Scheme',0.00,0.00,'basic',8.00,12,0.0,1.00,80.00,'2026-01-01',NULL,'Active'),
(4,'GRATUITY','Gratuity Policy',0.00,0.00,'basic',0.00,0,5.0,1.00,100.00,'2026-01-01',NULL,'Active');
/*!40000 ALTER TABLE `fund_policies` ENABLE KEYS */;
DROP TABLE IF EXISTS `fund_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fund_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `fund_type` enum('PF','WF','EPS','OSF','INS') NOT NULL,
  `tx_date` date NOT NULL,
  `tx_type` enum('Opening','Employee','Company','Interest','Withdraw','Adjust') NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `payroll_run_id` int(11) DEFAULT NULL,
  `ref_note` varchar(150) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`,`fund_type`),
  KEY `payroll_run_id` (`payroll_run_id`),
  CONSTRAINT `fund_transactions_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `fund_transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `fund_transactions` ENABLE KEYS */;
DROP TABLE IF EXISTS `fund_withdrawals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fund_withdrawals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref_no` varchar(30) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `fund_type` enum('PF','WF','EPS','OSF','INS') NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `balance_at_request` decimal(14,2) NOT NULL DEFAULT 0.00,
  `request_date` date NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected','Paid') NOT NULL DEFAULT 'Pending',
  `requested_by` int(11) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ref_no` (`ref_no`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `fund_withdrawals_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `fund_withdrawals` DISABLE KEYS */;
/*!40000 ALTER TABLE `fund_withdrawals` ENABLE KEYS */;
DROP TABLE IF EXISTS `grade_structures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `grade_structures` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grade_id` int(11) NOT NULL,
  `head_id` int(11) NOT NULL,
  `calc_type` enum('fixed','percent_basic','percent_gross') NOT NULL DEFAULT 'fixed',
  `value` decimal(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade_head` (`grade_id`,`head_id`),
  KEY `head_id` (`head_id`),
  CONSTRAINT `grade_structures_ibfk_1` FOREIGN KEY (`grade_id`) REFERENCES `grades` (`id`) ON DELETE CASCADE,
  CONSTRAINT `grade_structures_ibfk_2` FOREIGN KEY (`head_id`) REFERENCES `salary_heads` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `grade_structures` DISABLE KEYS */;
INSERT INTO `grade_structures` VALUES
(1,1,2,'percent_basic',50.00),
(2,1,3,'percent_basic',10.00),
(3,1,4,'fixed',1500.00),
(4,2,2,'percent_basic',50.00),
(5,2,3,'percent_basic',10.00),
(6,2,4,'fixed',1500.00),
(7,3,2,'percent_basic',50.00),
(8,3,3,'percent_basic',10.00),
(9,3,4,'fixed',1500.00),
(10,4,2,'percent_basic',50.00),
(11,4,3,'percent_basic',10.00),
(12,4,4,'fixed',1500.00),
(13,5,2,'percent_basic',50.00),
(14,5,3,'percent_basic',10.00),
(15,5,4,'fixed',1500.00),
(16,6,2,'percent_basic',50.00),
(17,6,3,'percent_basic',10.00),
(18,6,4,'fixed',1500.00),
(19,7,2,'percent_basic',50.00),
(20,7,3,'percent_basic',10.00),
(21,7,4,'fixed',1500.00),
(22,8,2,'percent_basic',50.00),
(23,8,3,'percent_basic',10.00),
(24,8,4,'fixed',1500.00);
/*!40000 ALTER TABLE `grade_structures` ENABLE KEYS */;
DROP TABLE IF EXISTS `grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `grades` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(60) NOT NULL,
  `level_no` int(11) NOT NULL DEFAULT 1,
  `min_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `max_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `annual_increment_percent` decimal(5,2) NOT NULL DEFAULT 10.00,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `grades` DISABLE KEYS */;
INSERT INTO `grades` VALUES
(1,'Grade 1',1,100000.00,160000.00,10.00,'Active'),
(2,'Grade 2',2,70000.00,110000.00,10.00,'Active'),
(3,'Grade 3',3,50000.00,80000.00,10.00,'Active'),
(4,'Grade 4',4,38000.00,60000.00,10.00,'Active'),
(5,'Grade 5',5,28000.00,45000.00,10.00,'Active'),
(6,'Grade 6',6,20000.00,33000.00,10.00,'Active'),
(7,'Grade 7',7,15000.00,25000.00,10.00,'Active'),
(8,'Grade 8',8,10000.00,18000.00,10.00,'Active');
/*!40000 ALTER TABLE `grades` ENABLE KEYS */;
DROP TABLE IF EXISTS `gratuities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gratuities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref_no` varchar(30) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `calc_date` date NOT NULL,
  `service_years` decimal(5,2) NOT NULL DEFAULT 0.00,
  `counted_years` int(11) NOT NULL DEFAULT 0,
  `last_basic` decimal(12,2) NOT NULL DEFAULT 0.00,
  `multiplier` decimal(5,2) NOT NULL DEFAULT 1.00,
  `amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `status` enum('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  `final_payment_id` int(11) DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ref_no` (`ref_no`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `gratuities_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `gratuities` DISABLE KEYS */;
/*!40000 ALTER TABLE `gratuities` ENABLE KEYS */;
DROP TABLE IF EXISTS `holidays`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `holidays` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(120) NOT NULL,
  `from_date` date NOT NULL,
  `to_date` date NOT NULL,
  `holiday_type` enum('Government','Festival','Optional','Company') NOT NULL DEFAULT 'Government',
  `note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `holidays` DISABLE KEYS */;
INSERT INTO `holidays` VALUES
(1,'Eid-ul-Fitr','2026-03-20','2026-03-24','Festival',NULL),
(2,'Independence Day','2026-03-26','2026-03-26','Government',NULL),
(3,'Pohela Boishakh','2026-04-14','2026-04-14','Government',NULL),
(4,'May Day','2026-05-01','2026-05-01','Government',NULL),
(5,'Eid-ul-Adha','2026-05-27','2026-05-31','Festival',NULL),
(6,'Victory Day','2026-12-16','2026-12-16','Government',NULL),
(7,'Christmas Day','2026-12-25','2026-12-25','Government',NULL);
/*!40000 ALTER TABLE `holidays` ENABLE KEYS */;
DROP TABLE IF EXISTS `id_card_print_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `id_card_print_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `card_type_id` int(11) DEFAULT NULL,
  `copy_no` int(11) NOT NULL DEFAULT 1,
  `reason` varchar(120) DEFAULT NULL,
  `printed_by` int(11) DEFAULT NULL,
  `printed_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `id_card_print_logs_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `id_card_print_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `id_card_print_logs` ENABLE KEYS */;
DROP TABLE IF EXISTS `id_card_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `id_card_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `accent_color` varchar(9) NOT NULL DEFAULT '#1f6b2a',
  `validity_years` int(11) NOT NULL DEFAULT 2,
  `show_blood_group` tinyint(1) NOT NULL DEFAULT 1,
  `show_qr` tinyint(1) NOT NULL DEFAULT 1,
  `footer_text` varchar(200) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `id_card_types` DISABLE KEYS */;
INSERT INTO `id_card_types` VALUES
(1,'Employee Card','#1f6b2a',2,1,1,'If found, please return to the HR department','Active');
/*!40000 ALTER TABLE `id_card_types` ENABLE KEYS */;
DROP TABLE IF EXISTS `income_tax_slabs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `income_tax_slabs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fiscal_year` varchar(9) NOT NULL,
  `category` enum('General','Female','Senior','Disabled') NOT NULL DEFAULT 'General',
  `slab_order` int(11) NOT NULL DEFAULT 1,
  `slab_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `note` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `income_tax_slabs` DISABLE KEYS */;
INSERT INTO `income_tax_slabs` VALUES
(1,'2025-2026','General',1,350000.00,0.00,NULL),
(2,'2025-2026','General',2,100000.00,5.00,NULL),
(3,'2025-2026','General',3,400000.00,10.00,NULL),
(4,'2025-2026','General',4,500000.00,15.00,NULL),
(5,'2025-2026','General',5,500000.00,20.00,NULL),
(6,'2025-2026','General',6,99999999.00,25.00,NULL),
(7,'2025-2026','Female',1,400000.00,0.00,NULL),
(8,'2025-2026','Female',2,100000.00,5.00,NULL),
(9,'2025-2026','Female',3,400000.00,10.00,NULL),
(10,'2025-2026','Female',4,500000.00,15.00,NULL),
(11,'2025-2026','Female',5,500000.00,20.00,NULL),
(12,'2025-2026','Female',6,99999999.00,25.00,NULL),
(13,'2025-2026','Senior',1,400000.00,0.00,NULL),
(14,'2025-2026','Senior',2,100000.00,5.00,NULL),
(15,'2025-2026','Senior',3,400000.00,10.00,NULL),
(16,'2025-2026','Senior',4,500000.00,15.00,NULL),
(17,'2025-2026','Senior',5,500000.00,20.00,NULL),
(18,'2025-2026','Senior',6,99999999.00,25.00,NULL),
(19,'2025-2026','Disabled',1,475000.00,0.00,NULL),
(20,'2025-2026','Disabled',2,100000.00,5.00,NULL),
(21,'2025-2026','Disabled',3,400000.00,10.00,NULL),
(22,'2025-2026','Disabled',4,500000.00,15.00,NULL),
(23,'2025-2026','Disabled',5,500000.00,20.00,NULL),
(24,'2025-2026','Disabled',6,99999999.00,25.00,NULL),
(25,'2026-2027','General',1,350000.00,0.00,NULL),
(26,'2026-2027','General',2,100000.00,5.00,NULL),
(27,'2026-2027','General',3,400000.00,10.00,NULL),
(28,'2026-2027','General',4,500000.00,15.00,NULL),
(29,'2026-2027','General',5,500000.00,20.00,NULL),
(30,'2026-2027','General',6,99999999.00,25.00,NULL),
(31,'2026-2027','Female',1,400000.00,0.00,NULL),
(32,'2026-2027','Female',2,100000.00,5.00,NULL),
(33,'2026-2027','Female',3,400000.00,10.00,NULL),
(34,'2026-2027','Female',4,500000.00,15.00,NULL),
(35,'2026-2027','Female',5,500000.00,20.00,NULL),
(36,'2026-2027','Female',6,99999999.00,25.00,NULL),
(37,'2026-2027','Senior',1,400000.00,0.00,NULL),
(38,'2026-2027','Senior',2,100000.00,5.00,NULL),
(39,'2026-2027','Senior',3,400000.00,10.00,NULL),
(40,'2026-2027','Senior',4,500000.00,15.00,NULL),
(41,'2026-2027','Senior',5,500000.00,20.00,NULL),
(42,'2026-2027','Senior',6,99999999.00,25.00,NULL),
(43,'2026-2027','Disabled',1,475000.00,0.00,NULL),
(44,'2026-2027','Disabled',2,100000.00,5.00,NULL),
(45,'2026-2027','Disabled',3,400000.00,10.00,NULL),
(46,'2026-2027','Disabled',4,500000.00,15.00,NULL),
(47,'2026-2027','Disabled',5,500000.00,20.00,NULL),
(48,'2026-2027','Disabled',6,99999999.00,25.00,NULL);
/*!40000 ALTER TABLE `income_tax_slabs` ENABLE KEYS */;
DROP TABLE IF EXISTS `interest_run_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `interest_run_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `account_ref` int(11) DEFAULT NULL,
  `base_balance` decimal(14,2) NOT NULL,
  `interest` decimal(14,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `run_id` (`run_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `interest_run_items_ibfk_1` FOREIGN KEY (`run_id`) REFERENCES `interest_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `interest_run_items_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `interest_run_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `interest_run_items` ENABLE KEYS */;
DROP TABLE IF EXISTS `interest_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `interest_runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_no` varchar(30) NOT NULL,
  `fund_type` enum('PF','WF','EPS','EDPS') NOT NULL,
  `period_from` date NOT NULL,
  `period_to` date NOT NULL,
  `rate_percent` decimal(5,2) NOT NULL,
  `status` enum('Draft','Posted') NOT NULL DEFAULT 'Draft',
  `total_interest` decimal(16,2) NOT NULL DEFAULT 0.00,
  `created_by` int(11) DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `run_no` (`run_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `interest_runs` DISABLE KEYS */;
/*!40000 ALTER TABLE `interest_runs` ENABLE KEYS */;
DROP TABLE IF EXISTS `job_applicants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_applicants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `circular_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `mobile` varchar(30) DEFAULT NULL,
  `experience_years` decimal(4,1) NOT NULL DEFAULT 0.0,
  `expected_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `stage` enum('Applied','Shortlisted','Interviewed','Selected','Rejected','Hired') NOT NULL DEFAULT 'Applied',
  `notes` varchar(255) DEFAULT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `circular_id` (`circular_id`),
  CONSTRAINT `job_applicants_ibfk_1` FOREIGN KEY (`circular_id`) REFERENCES `job_circulars` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `job_applicants` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_applicants` ENABLE KEYS */;
DROP TABLE IF EXISTS `job_circulars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_circulars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `circular_no` varchar(30) NOT NULL,
  `requisition_id` int(11) DEFAULT NULL,
  `title` varchar(200) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `designation_id` int(11) DEFAULT NULL,
  `vacancies` int(11) NOT NULL DEFAULT 1,
  `description` text DEFAULT NULL,
  `requirements` text DEFAULT NULL,
  `publish_date` date DEFAULT NULL,
  `deadline` date DEFAULT NULL,
  `status` enum('Draft','Published','Closed') NOT NULL DEFAULT 'Draft',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `circular_no` (`circular_no`),
  KEY `requisition_id` (`requisition_id`),
  CONSTRAINT `job_circulars_ibfk_1` FOREIGN KEY (`requisition_id`) REFERENCES `requisitions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `job_circulars` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_circulars` ENABLE KEYS */;
DROP TABLE IF EXISTS `leave_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `leave_applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_no` varchar(30) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `leave_type_id` int(11) NOT NULL,
  `from_date` date NOT NULL,
  `to_date` date NOT NULL,
  `days` decimal(5,1) NOT NULL DEFAULT 1.0,
  `half_day` tinyint(1) NOT NULL DEFAULT 0,
  `reason` varchar(255) DEFAULT NULL,
  `application_type` enum('Own','Other','Late') NOT NULL DEFAULT 'Own',
  `status` enum('Pending','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
  `applied_by` int(11) DEFAULT NULL,
  `approver_employee_id` int(11) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `app_no` (`app_no`),
  KEY `employee_id` (`employee_id`,`status`),
  KEY `from_date` (`from_date`,`to_date`),
  KEY `leave_type_id` (`leave_type_id`),
  CONSTRAINT `leave_applications_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `leave_applications_ibfk_2` FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `leave_applications` DISABLE KEYS */;
/*!40000 ALTER TABLE `leave_applications` ENABLE KEYS */;
DROP TABLE IF EXISTS `leave_balances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `leave_balances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `leave_type_id` int(11) NOT NULL,
  `year` int(11) NOT NULL,
  `opening` decimal(5,1) NOT NULL DEFAULT 0.0,
  `entitled` decimal(5,1) NOT NULL DEFAULT 0.0,
  `used` decimal(5,1) NOT NULL DEFAULT 0.0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bal` (`employee_id`,`leave_type_id`,`year`),
  KEY `leave_type_id` (`leave_type_id`),
  CONSTRAINT `leave_balances_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `leave_balances_ibfk_2` FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `leave_balances` DISABLE KEYS */;
/*!40000 ALTER TABLE `leave_balances` ENABLE KEYS */;
DROP TABLE IF EXISTS `leave_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `leave_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(60) NOT NULL,
  `code` varchar(10) NOT NULL,
  `yearly_quota` decimal(5,1) NOT NULL DEFAULT 0.0,
  `is_paid` tinyint(1) NOT NULL DEFAULT 1,
  `carry_forward` tinyint(1) NOT NULL DEFAULT 0,
  `max_carry` decimal(5,1) NOT NULL DEFAULT 0.0,
  `encashable` tinyint(1) NOT NULL DEFAULT 0,
  `gender_rule` enum('Any','Male','Female') NOT NULL DEFAULT 'Any',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `leave_types` DISABLE KEYS */;
INSERT INTO `leave_types` VALUES
(1,'Sick Leave','SL',14.0,1,0,0.0,0,'Any','Active'),
(2,'Annual Leave','AL',20.0,1,1,10.0,1,'Any','Active'),
(3,'Casual Leave','CL',10.0,1,0,0.0,0,'Any','Active'),
(4,'Emergency Leave','EL',5.0,1,0,0.0,0,'Any','Active'),
(5,'Maternity Leave','ML',112.0,1,0,0.0,0,'Female','Active'),
(6,'Leave Without Pay','LWP',0.0,0,0,0.0,0,'Any','Active');
/*!40000 ALTER TABLE `leave_types` ENABLE KEYS */;
DROP TABLE IF EXISTS `loan_installments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `loan_installments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `loan_id` int(11) NOT NULL,
  `installment_no` int(11) NOT NULL,
  `due_month` date NOT NULL,
  `principal` decimal(12,2) NOT NULL DEFAULT 0.00,
  `interest` decimal(12,2) NOT NULL DEFAULT 0.00,
  `amount` decimal(12,2) NOT NULL,
  `status` enum('Due','Paid','Settled') NOT NULL DEFAULT 'Due',
  `paid_on` date DEFAULT NULL,
  `payroll_run_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `due_month` (`due_month`,`status`),
  KEY `loan_id` (`loan_id`),
  CONSTRAINT `loan_installments_ibfk_1` FOREIGN KEY (`loan_id`) REFERENCES `loans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `loan_installments` DISABLE KEYS */;
/*!40000 ALTER TABLE `loan_installments` ENABLE KEYS */;
DROP TABLE IF EXISTS `loan_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `loan_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `kind` enum('advance_salary','pf_loan','vehicle_loan','other') NOT NULL DEFAULT 'other',
  `max_salary_multiple` decimal(5,2) NOT NULL DEFAULT 0.00,
  `max_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `interest_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `max_installments` int(11) NOT NULL DEFAULT 12,
  `min_service_months` int(11) NOT NULL DEFAULT 6,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `loan_types` DISABLE KEYS */;
INSERT INTO `loan_types` VALUES
(1,'Advance Salary Loan','advance_salary',2.00,0.00,0.00,6,6,'Active'),
(2,'PF Loan','pf_loan',0.00,0.00,0.00,24,12,'Active'),
(3,'Vehicle Loan','vehicle_loan',0.00,1500000.00,6.00,60,24,'Active');
/*!40000 ALTER TABLE `loan_types` ENABLE KEYS */;
DROP TABLE IF EXISTS `loans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `loans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `loan_no` varchar(30) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `loan_type_id` int(11) NOT NULL,
  `vehicle_type_id` int(11) DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `interest_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `installments` int(11) NOT NULL DEFAULT 1,
  `installment_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_payable` decimal(12,2) NOT NULL DEFAULT 0.00,
  `start_month` date NOT NULL,
  `purpose` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected','Running','Closed','Settled') NOT NULL DEFAULT 'Pending',
  `is_opening` tinyint(1) NOT NULL DEFAULT 0,
  `requested_by` int(11) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `disbursed_on` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `loan_no` (`loan_no`),
  KEY `employee_id` (`employee_id`,`status`),
  KEY `loan_type_id` (`loan_type_id`),
  CONSTRAINT `loans_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `loans_ibfk_2` FOREIGN KEY (`loan_type_id`) REFERENCES `loan_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `loans` DISABLE KEYS */;
/*!40000 ALTER TABLE `loans` ENABLE KEYS */;
DROP TABLE IF EXISTS `notices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `notices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `audience` enum('All','Branch','Department') NOT NULL DEFAULT 'All',
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `priority` enum('Normal','Important','Urgent') NOT NULL DEFAULT 'Normal',
  `publish_date` date NOT NULL,
  `expire_date` date DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `status` enum('Draft','Published','Archived') NOT NULL DEFAULT 'Published',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `notices` DISABLE KEYS */;
INSERT INTO `notices` VALUES
(1,'Welcome to the HR & Payroll portal','Use this portal to apply for leave, view payslips and manage your profile. Contact HR for any help.','All',NULL,NULL,'Normal','2026-10-12',NULL,NULL,'Published','2026-10-12 03:06:42');
/*!40000 ALTER TABLE `notices` ENABLE KEYS */;
DROP TABLE IF EXISTS `opening_balances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `opening_balances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `balance_type` enum('Leave','PF','WF','EPS','OSF','INS','EDPS','Loan') NOT NULL,
  `leave_type_id` int(11) DEFAULT NULL,
  `loan_type_id` int(11) DEFAULT NULL,
  `amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `installments_left` int(11) DEFAULT NULL,
  `as_of_date` date NOT NULL,
  `remarks` varchar(200) DEFAULT NULL,
  `applied` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `opening_balances_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `opening_balances` DISABLE KEYS */;
/*!40000 ALTER TABLE `opening_balances` ENABLE KEYS */;
DROP TABLE IF EXISTS `org_letter_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `org_letter_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `letter_type` varchar(40) NOT NULL,
  `name` varchar(120) NOT NULL,
  `subject` varchar(200) DEFAULT NULL,
  `body` text NOT NULL,
  `signatory_name` varchar(120) DEFAULT NULL,
  `signatory_title` varchar(120) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `org_letter_templates` DISABLE KEYS */;
INSERT INTO `org_letter_templates` VALUES
(1,'Appointment','Appointment Letter (standard)','Appointment Letter','Dear {{employee_name}},\n\nWe are pleased to appoint you as {{designation}} in the {{department}} department ({{branch}}) of {{company_name}}, effective {{joining_date}}. Your monthly basic salary will be BDT {{basic_salary}} and gross salary BDT {{gross_salary}}.\n\nPlease report to your supervisor on the joining date with the original documents.','Head of HR','Human Resources Department','Active'),
(2,'Confirmation','Confirmation Letter (standard)','Confirmation Letter','Dear {{employee_name}},\n\nWe are happy to inform you that after satisfactory completion of your probation period you are confirmed as a Permanent {{designation}} with effect from {{effective_date}}.','Head of HR','Human Resources Department','Active'),
(3,'Promotion','Promotion Letter (standard)','Promotion Letter','Dear {{employee_name}},\n\nIn recognition of your performance you are promoted to {{new_designation}} with effect from {{effective_date}}. Your new basic salary will be BDT {{new_basic}}.','Head of HR','Human Resources Department','Active'),
(4,'Increment','Increment Letter (standard)','Increment Letter','Dear {{employee_name}},\n\nWe are pleased to inform you that your basic salary is increased to BDT {{new_basic}} with effect from {{effective_date}}.','Head of HR','Human Resources Department','Active'),
(5,'Transfer','Transfer Letter (standard)','Transfer Letter','Dear {{employee_name}},\n\nYou are transferred as per company need with effect from {{effective_date}}. Please hand over your current duties and join the new place of posting.','Head of HR','Human Resources Department','Active'),
(6,'Resign','Resignation Acceptance (standard)','Resignation Acceptance','Dear {{employee_name}},\n\nYour resignation has been accepted. Your last working day will be {{last_working_date}}. Please complete the clearance formalities before your departure.','Head of HR','Human Resources Department','Active'),
(7,'Terminate','Termination Letter (standard)','Termination Letter','Dear {{employee_name}},\n\nYour employment with {{company_name}} is terminated with effect from {{effective_date}}; your last working day is {{last_working_date}}.','Head of HR','Human Resources Department','Active'),
(8,'Retirement','Retirement Letter (standard)','Retirement Letter','Dear {{employee_name}},\n\nOn behalf of {{company_name}} we thank you for your years of service. Your retirement is effective {{effective_date}} and your last working day is {{last_working_date}}.','Head of HR','Human Resources Department','Active'),
(9,'Experience','Experience Certificate (standard)','Experience Certificate','This is to certify that {{employee_name}} (ID {{emp_code}}) worked with {{company_name}} as {{designation}} in the {{department}} department since {{joining_date}}. We found the person sincere and hardworking. We wish them every success.','Head of HR','Human Resources Department','Active');
/*!40000 ALTER TABLE `org_letter_templates` ENABLE KEYS */;
DROP TABLE IF EXISTS `payroll_adjustments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payroll_adjustments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `period_month` date NOT NULL,
  `adj_type` enum('earning','deduction') NOT NULL DEFAULT 'earning',
  `title` varchar(120) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `applied` tinyint(1) NOT NULL DEFAULT 0,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `payroll_adjustments_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `payroll_adjustments` DISABLE KEYS */;
/*!40000 ALTER TABLE `payroll_adjustments` ENABLE KEYS */;
DROP TABLE IF EXISTS `payroll_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payroll_runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_no` varchar(30) NOT NULL,
  `run_type` enum('monthly','final') NOT NULL DEFAULT 'monthly',
  `period_month` date NOT NULL,
  `period_from` date NOT NULL,
  `period_to` date NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `status` enum('Draft','Approved','Paid') NOT NULL DEFAULT 'Draft',
  `employee_count` int(11) NOT NULL DEFAULT 0,
  `total_gross` decimal(16,2) NOT NULL DEFAULT 0.00,
  `total_deduction` decimal(16,2) NOT NULL DEFAULT 0.00,
  `total_net` decimal(16,2) NOT NULL DEFAULT 0.00,
  `notes` varchar(255) DEFAULT NULL,
  `generated_by` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `run_no` (`run_no`),
  KEY `period_month` (`period_month`,`run_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `payroll_runs` DISABLE KEYS */;
/*!40000 ALTER TABLE `payroll_runs` ENABLE KEYS */;
DROP TABLE IF EXISTS `payslip_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payslip_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `payslip_id` int(11) NOT NULL,
  `head_name` varchar(100) NOT NULL,
  `item_type` enum('earning','deduction') NOT NULL,
  `source` varchar(20) NOT NULL DEFAULT 'head',
  `ref_id` int(11) DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `payslip_id` (`payslip_id`),
  CONSTRAINT `payslip_items_ibfk_1` FOREIGN KEY (`payslip_id`) REFERENCES `payslips` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `payslip_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `payslip_items` ENABLE KEYS */;
DROP TABLE IF EXISTS `payslips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payslips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `period_month` date NOT NULL,
  `calendar_days` int(11) NOT NULL DEFAULT 30,
  `present_days` decimal(5,1) NOT NULL DEFAULT 0.0,
  `absent_days` decimal(5,1) NOT NULL DEFAULT 0.0,
  `leave_days` decimal(5,1) NOT NULL DEFAULT 0.0,
  `late_days` int(11) NOT NULL DEFAULT 0,
  `paid_days` decimal(5,1) NOT NULL DEFAULT 0.0,
  `basic` decimal(12,2) NOT NULL DEFAULT 0.00,
  `gross` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_earning` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_deduction` decimal(12,2) NOT NULL DEFAULT 0.00,
  `net_pay` decimal(12,2) NOT NULL DEFAULT 0.00,
  `pf_employee` decimal(12,2) NOT NULL DEFAULT 0.00,
  `pf_company` decimal(12,2) NOT NULL DEFAULT 0.00,
  `wf_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `eps_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `tax_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `loan_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `edps_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `payment_status` enum('Unpaid','Paid','Hold') NOT NULL DEFAULT 'Unpaid',
  `payment_mode` varchar(20) DEFAULT NULL,
  `account_no` varchar(40) DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slip` (`run_id`,`employee_id`),
  KEY `employee_id` (`employee_id`,`period_month`),
  CONSTRAINT `payslips_ibfk_1` FOREIGN KEY (`run_id`) REFERENCES `payroll_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `payslips_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `payslips` DISABLE KEYS */;
/*!40000 ALTER TABLE `payslips` ENABLE KEYS */;
DROP TABLE IF EXISTS `performance_review_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `performance_review_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `review_id` int(11) NOT NULL,
  `criteria_id` int(11) NOT NULL,
  `score` decimal(5,2) NOT NULL DEFAULT 0.00,
  `remarks` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `review_id` (`review_id`),
  KEY `criteria_id` (`criteria_id`),
  CONSTRAINT `performance_review_items_ibfk_1` FOREIGN KEY (`review_id`) REFERENCES `performance_reviews` (`id`) ON DELETE CASCADE,
  CONSTRAINT `performance_review_items_ibfk_2` FOREIGN KEY (`criteria_id`) REFERENCES `assessment_criteria` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `performance_review_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `performance_review_items` ENABLE KEYS */;
DROP TABLE IF EXISTS `performance_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `performance_reviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `review_title` varchar(120) NOT NULL,
  `period_from` date NOT NULL,
  `period_to` date NOT NULL,
  `reviewer_employee_id` int(11) DEFAULT NULL,
  `score_percent` decimal(5,2) NOT NULL DEFAULT 0.00,
  `rating` varchar(60) DEFAULT NULL,
  `recommendation` varchar(40) DEFAULT NULL,
  `comments` varchar(500) DEFAULT NULL,
  `status` enum('Draft','Submitted','Finalized') NOT NULL DEFAULT 'Draft',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `performance_reviews_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `performance_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `performance_reviews` ENABLE KEYS */;
DROP TABLE IF EXISTS `periodic_report_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `periodic_report_configs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `report_key` varchar(60) NOT NULL,
  `frequency` enum('Daily','Weekly','Monthly','Quarterly','Yearly') NOT NULL DEFAULT 'Monthly',
  `run_day` int(11) NOT NULL DEFAULT 1,
  `recipients` varchar(255) DEFAULT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `periodic_report_configs` DISABLE KEYS */;
/*!40000 ALTER TABLE `periodic_report_configs` ENABLE KEYS */;
DROP TABLE IF EXISTS `personnel_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `personnel_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref_no` varchar(30) NOT NULL,
  `action_type` enum('promotion','demotion','permanent','increment','transfer','resign','terminate','retirement') NOT NULL,
  `employee_id` int(11) NOT NULL,
  `effective_date` date NOT NULL,
  `review_id` int(11) DEFAULT NULL,
  `from_designation_id` int(11) DEFAULT NULL,
  `to_designation_id` int(11) DEFAULT NULL,
  `from_grade_id` int(11) DEFAULT NULL,
  `to_grade_id` int(11) DEFAULT NULL,
  `old_basic` decimal(12,2) DEFAULT NULL,
  `new_basic` decimal(12,2) DEFAULT NULL,
  `percent` decimal(5,2) DEFAULT NULL,
  `from_branch_id` int(11) DEFAULT NULL,
  `to_branch_id` int(11) DEFAULT NULL,
  `from_department_id` int(11) DEFAULT NULL,
  `to_department_id` int(11) DEFAULT NULL,
  `sub_type` varchar(40) DEFAULT NULL,
  `extension_months` int(11) DEFAULT NULL,
  `notice_days` int(11) DEFAULT NULL,
  `last_working_date` date DEFAULT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected','Cancelled','Completed') NOT NULL DEFAULT 'Pending',
  `requested_by` int(11) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ref_no` (`ref_no`),
  KEY `employee_id` (`employee_id`),
  KEY `action_type` (`action_type`,`status`),
  CONSTRAINT `personnel_actions_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `personnel_actions` DISABLE KEYS */;
/*!40000 ALTER TABLE `personnel_actions` ENABLE KEYS */;
DROP TABLE IF EXISTS `rating_scales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rating_scales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(60) NOT NULL,
  `min_percent` decimal(5,2) NOT NULL,
  `max_percent` decimal(5,2) NOT NULL,
  `recommendation` enum('Promotion','Increment','Confirm','Extend Probation','Warning','No Action') NOT NULL DEFAULT 'No Action',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `rating_scales` DISABLE KEYS */;
INSERT INTO `rating_scales` VALUES
(1,'Excellent',85.00,100.00,'Promotion','Active'),
(2,'Good',70.00,84.99,'Increment','Active'),
(3,'Average',50.00,69.99,'Extend Probation','Active'),
(4,'Below Average',0.00,49.99,'Warning','Active');
/*!40000 ALTER TABLE `rating_scales` ENABLE KEYS */;
DROP TABLE IF EXISTS `report_authorities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `report_authorities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_group` varchar(60) NOT NULL,
  `role_id` int(11) DEFAULT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) NOT NULL DEFAULT 1,
  `can_export` tinyint(1) NOT NULL DEFAULT 1,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  KEY `role_id` (`role_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `report_authorities_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `report_authorities_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `report_authorities` DISABLE KEYS */;
/*!40000 ALTER TABLE `report_authorities` ENABLE KEYS */;
DROP TABLE IF EXISTS `requisitions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `requisitions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `req_no` varchar(30) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `department_id` int(11) NOT NULL,
  `designation_id` int(11) NOT NULL,
  `vacancies` int(11) NOT NULL DEFAULT 1,
  `employment_type` enum('Permanent','Contract','Intern','Part-time') NOT NULL DEFAULT 'Permanent',
  `min_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `max_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `required_date` date DEFAULT NULL,
  `justification` varchar(500) DEFAULT NULL,
  `requested_by` int(11) DEFAULT NULL,
  `status` enum('Draft','Pending','Approved','Rejected','Closed') NOT NULL DEFAULT 'Pending',
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `req_no` (`req_no`),
  KEY `branch_id` (`branch_id`),
  KEY `department_id` (`department_id`),
  KEY `designation_id` (`designation_id`),
  CONSTRAINT `requisitions_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT `requisitions_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  CONSTRAINT `requisitions_ibfk_3` FOREIGN KEY (`designation_id`) REFERENCES `designations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `requisitions` DISABLE KEYS */;
/*!40000 ALTER TABLE `requisitions` ENABLE KEYS */;
DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `role_id` int(11) NOT NULL,
  `permission` varchar(80) NOT NULL,
  PRIMARY KEY (`role_id`,`permission`),
  CONSTRAINT `role_permissions_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `role_permissions` DISABLE KEYS */;
INSERT INTO `role_permissions` VALUES
(1,'*'),
(2,'attendance.approve'),
(2,'attendance.create'),
(2,'attendance.delete'),
(2,'attendance.edit'),
(2,'attendance.view'),
(2,'bonus.approve'),
(2,'bonus.create'),
(2,'bonus.delete'),
(2,'bonus.edit'),
(2,'bonus.view'),
(2,'dashboard.approve'),
(2,'dashboard.create'),
(2,'dashboard.delete'),
(2,'dashboard.edit'),
(2,'dashboard.view'),
(2,'delegation.approve'),
(2,'delegation.create'),
(2,'delegation.delete'),
(2,'delegation.edit'),
(2,'delegation.view'),
(2,'demotion.approve'),
(2,'demotion.create'),
(2,'demotion.delete'),
(2,'demotion.edit'),
(2,'demotion.view'),
(2,'documents.approve'),
(2,'documents.create'),
(2,'documents.delete'),
(2,'documents.edit'),
(2,'documents.view'),
(2,'early_settlement.approve'),
(2,'early_settlement.create'),
(2,'early_settlement.delete'),
(2,'early_settlement.edit'),
(2,'early_settlement.view'),
(2,'edps.approve'),
(2,'edps.create'),
(2,'edps.delete'),
(2,'edps.edit'),
(2,'edps.view'),
(2,'employees.approve'),
(2,'employees.create'),
(2,'employees.delete'),
(2,'employees.edit'),
(2,'employees.view'),
(2,'eps_withdraw.approve'),
(2,'eps_withdraw.create'),
(2,'eps_withdraw.delete'),
(2,'eps_withdraw.edit'),
(2,'eps_withdraw.view'),
(2,'final_payment.approve'),
(2,'final_payment.create'),
(2,'final_payment.delete'),
(2,'final_payment.edit'),
(2,'final_payment.view'),
(2,'gratuity.approve'),
(2,'gratuity.create'),
(2,'gratuity.delete'),
(2,'gratuity.edit'),
(2,'gratuity.view'),
(2,'income_tax.approve'),
(2,'income_tax.create'),
(2,'income_tax.delete'),
(2,'income_tax.edit'),
(2,'income_tax.view'),
(2,'increment.approve'),
(2,'increment.create'),
(2,'increment.delete'),
(2,'increment.edit'),
(2,'increment.view'),
(2,'interest.approve'),
(2,'interest.create'),
(2,'interest.delete'),
(2,'interest.edit'),
(2,'interest.view'),
(2,'leave.approve'),
(2,'leave.create'),
(2,'leave.delete'),
(2,'leave.edit'),
(2,'leave.view'),
(2,'leave_late.approve'),
(2,'leave_late.create'),
(2,'leave_late.delete'),
(2,'leave_late.edit'),
(2,'leave_late.view'),
(2,'loan_advance.approve'),
(2,'loan_advance.create'),
(2,'loan_advance.delete'),
(2,'loan_advance.edit'),
(2,'loan_advance.view'),
(2,'loan_pf.approve'),
(2,'loan_pf.create'),
(2,'loan_pf.delete'),
(2,'loan_pf.edit'),
(2,'loan_pf.view'),
(2,'loan_vehicle.approve'),
(2,'loan_vehicle.create'),
(2,'loan_vehicle.delete'),
(2,'loan_vehicle.edit'),
(2,'loan_vehicle.view'),
(2,'my_reports.approve'),
(2,'my_reports.create'),
(2,'my_reports.delete'),
(2,'my_reports.edit'),
(2,'my_reports.view'),
(2,'notices.approve'),
(2,'notices.create'),
(2,'notices.delete'),
(2,'notices.edit'),
(2,'notices.view'),
(2,'opening_balance.approve'),
(2,'opening_balance.create'),
(2,'opening_balance.delete'),
(2,'opening_balance.edit'),
(2,'opening_balance.view'),
(2,'org.approve'),
(2,'org.create'),
(2,'org.delete'),
(2,'org.edit'),
(2,'org.view'),
(2,'payroll.approve'),
(2,'payroll.create'),
(2,'payroll.delete'),
(2,'payroll.edit'),
(2,'payroll.view'),
(2,'performance.approve'),
(2,'performance.create'),
(2,'performance.delete'),
(2,'performance.edit'),
(2,'performance.view'),
(2,'permanent.approve'),
(2,'permanent.create'),
(2,'permanent.delete'),
(2,'permanent.edit'),
(2,'permanent.view'),
(2,'promotion.approve'),
(2,'promotion.create'),
(2,'promotion.delete'),
(2,'promotion.edit'),
(2,'promotion.view'),
(2,'recruitment.approve'),
(2,'recruitment.create'),
(2,'recruitment.delete'),
(2,'recruitment.edit'),
(2,'recruitment.view'),
(2,'reports.approve'),
(2,'reports.create'),
(2,'reports.delete'),
(2,'reports.edit'),
(2,'reports.view'),
(2,'resign.approve'),
(2,'resign.create'),
(2,'resign.delete'),
(2,'resign.edit'),
(2,'resign.view'),
(2,'retirement.approve'),
(2,'retirement.create'),
(2,'retirement.delete'),
(2,'retirement.edit'),
(2,'retirement.view'),
(2,'salary_deduction.approve'),
(2,'salary_deduction.create'),
(2,'salary_deduction.delete'),
(2,'salary_deduction.edit'),
(2,'salary_deduction.view'),
(2,'salary_review.approve'),
(2,'salary_review.create'),
(2,'salary_review.delete'),
(2,'salary_review.edit'),
(2,'salary_review.view'),
(2,'settings.approve'),
(2,'settings.create'),
(2,'settings.delete'),
(2,'settings.edit'),
(2,'settings.view'),
(2,'terminate.approve'),
(2,'terminate.create'),
(2,'terminate.delete'),
(2,'terminate.edit'),
(2,'terminate.view'),
(2,'transfer.approve'),
(2,'transfer.create'),
(2,'transfer.delete'),
(2,'transfer.edit'),
(2,'transfer.view'),
(2,'wf_withdraw.approve'),
(2,'wf_withdraw.create'),
(2,'wf_withdraw.delete'),
(2,'wf_withdraw.edit'),
(2,'wf_withdraw.view'),
(3,'attendance.view'),
(3,'bonus.approve'),
(3,'bonus.create'),
(3,'bonus.delete'),
(3,'bonus.edit'),
(3,'bonus.view'),
(3,'delegation.approve'),
(3,'delegation.create'),
(3,'delegation.delete'),
(3,'delegation.edit'),
(3,'delegation.view'),
(3,'documents.view'),
(3,'early_settlement.approve'),
(3,'early_settlement.create'),
(3,'early_settlement.delete'),
(3,'early_settlement.edit'),
(3,'early_settlement.view'),
(3,'edps.approve'),
(3,'edps.create'),
(3,'edps.delete'),
(3,'edps.edit'),
(3,'edps.view'),
(3,'employees.view'),
(3,'eps_withdraw.approve'),
(3,'eps_withdraw.create'),
(3,'eps_withdraw.delete'),
(3,'eps_withdraw.edit'),
(3,'eps_withdraw.view'),
(3,'final_payment.approve'),
(3,'final_payment.create'),
(3,'final_payment.delete'),
(3,'final_payment.edit'),
(3,'final_payment.view'),
(3,'gratuity.approve'),
(3,'gratuity.create'),
(3,'gratuity.delete'),
(3,'gratuity.edit'),
(3,'gratuity.view'),
(3,'income_tax.approve'),
(3,'income_tax.create'),
(3,'income_tax.delete'),
(3,'income_tax.edit'),
(3,'income_tax.view'),
(3,'interest.approve'),
(3,'interest.create'),
(3,'interest.delete'),
(3,'interest.edit'),
(3,'interest.view'),
(3,'leave.view'),
(3,'loan_advance.approve'),
(3,'loan_advance.create'),
(3,'loan_advance.delete'),
(3,'loan_advance.edit'),
(3,'loan_advance.view'),
(3,'loan_pf.approve'),
(3,'loan_pf.create'),
(3,'loan_pf.delete'),
(3,'loan_pf.edit'),
(3,'loan_pf.view'),
(3,'loan_vehicle.approve'),
(3,'loan_vehicle.create'),
(3,'loan_vehicle.delete'),
(3,'loan_vehicle.edit'),
(3,'loan_vehicle.view'),
(3,'notices.view'),
(3,'opening_balance.approve'),
(3,'opening_balance.create'),
(3,'opening_balance.delete'),
(3,'opening_balance.edit'),
(3,'opening_balance.view'),
(3,'org.view'),
(3,'payroll.approve'),
(3,'payroll.create'),
(3,'payroll.delete'),
(3,'payroll.edit'),
(3,'payroll.view'),
(3,'payslip.view'),
(3,'reports.view'),
(3,'salary_deduction.approve'),
(3,'salary_deduction.create'),
(3,'salary_deduction.delete'),
(3,'salary_deduction.edit'),
(3,'salary_deduction.view'),
(3,'settings.view'),
(3,'wf_withdraw.approve'),
(3,'wf_withdraw.create'),
(3,'wf_withdraw.delete'),
(3,'wf_withdraw.edit'),
(3,'wf_withdraw.view'),
(4,'attendance.create'),
(4,'attendance.view'),
(4,'delegation.create'),
(4,'delegation.view'),
(4,'documents.view'),
(4,'employees.view'),
(4,'eps_withdraw.approve'),
(4,'eps_withdraw.create'),
(4,'eps_withdraw.view'),
(4,'increment.create'),
(4,'increment.view'),
(4,'leave.approve'),
(4,'leave.create'),
(4,'leave.view'),
(4,'loan_advance.approve'),
(4,'loan_advance.create'),
(4,'loan_advance.view'),
(4,'loan_pf.approve'),
(4,'loan_pf.create'),
(4,'loan_pf.view'),
(4,'loan_vehicle.view'),
(4,'notices.view'),
(4,'payslip.view'),
(4,'performance.create'),
(4,'performance.view'),
(4,'permanent.create'),
(4,'permanent.view'),
(4,'promotion.create'),
(4,'promotion.view'),
(4,'recruitment.create'),
(4,'recruitment.view'),
(4,'reports.view'),
(4,'resign.approve'),
(4,'resign.create'),
(4,'resign.view'),
(4,'terminate.view'),
(4,'transfer.create'),
(4,'transfer.view'),
(4,'wf_withdraw.approve'),
(4,'wf_withdraw.create'),
(4,'wf_withdraw.view'),
(5,'attendance.view'),
(5,'documents.view'),
(5,'employees.view'),
(5,'eps_withdraw.create'),
(5,'eps_withdraw.view'),
(5,'leave.create'),
(5,'leave.view'),
(5,'loan_advance.create'),
(5,'loan_advance.view'),
(5,'loan_pf.create'),
(5,'loan_pf.view'),
(5,'loan_vehicle.create'),
(5,'loan_vehicle.view'),
(5,'my_reports.view'),
(5,'notices.view'),
(5,'payslip.view'),
(5,'resign.create'),
(5,'resign.view'),
(5,'wf_withdraw.create'),
(5,'wf_withdraw.view');
/*!40000 ALTER TABLE `role_permissions` ENABLE KEYS */;
DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `slug` varchar(80) NOT NULL,
  `scope` enum('all','team','self') NOT NULL DEFAULT 'self',
  `description` varchar(255) DEFAULT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES
(1,'Super Admin','super_admin','all','Full access to everything',1,'2026-10-12 03:06:41'),
(2,'HR Manager','hr_admin','all','Runs HR operations: employees, leave, attendance, recruitment, performance',1,'2026-10-12 03:06:41'),
(3,'Payroll / Accounts','payroll_officer','all','Salary sheets, loans, funds, bonus and final payments',1,'2026-10-12 03:06:41'),
(4,'Line Manager','manager','team','Approves and assesses own team (reporting boss)',1,'2026-10-12 03:06:41'),
(5,'Employee','employee','self','Self service: own profile, leave, payslips, loans',1,'2026-10-12 03:06:41');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
DROP TABLE IF EXISTS `salary_certificate_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_certificate_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref_no` varchar(40) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `purpose` varchar(150) DEFAULT NULL,
  `addressed_to` varchar(200) DEFAULT NULL,
  `gross_salary` decimal(12,2) NOT NULL DEFAULT 0.00,
  `issue_date` date NOT NULL,
  `printed_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `salary_certificate_logs_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `salary_certificate_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `salary_certificate_logs` ENABLE KEYS */;
DROP TABLE IF EXISTS `salary_deductions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_deductions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `deduction_type` enum('Disciplinary','Demotion','Damage','Advance Recovery','Other') NOT NULL DEFAULT 'Other',
  `total_amount` decimal(12,2) NOT NULL,
  `installments` int(11) NOT NULL DEFAULT 1,
  `monthly_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `from_month` date NOT NULL,
  `deducted_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `deducted_count` int(11) NOT NULL DEFAULT 0,
  `reason` varchar(255) DEFAULT NULL,
  `status` enum('Active','Completed','Cancelled') NOT NULL DEFAULT 'Active',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `salary_deductions_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `salary_deductions` DISABLE KEYS */;
/*!40000 ALTER TABLE `salary_deductions` ENABLE KEYS */;
DROP TABLE IF EXISTS `salary_dues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_dues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL,
  `period_month` date NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `payslip_id` int(11) DEFAULT NULL,
  `status` enum('Due','Paid','Cancelled') NOT NULL DEFAULT 'Due',
  `paid_on` date DEFAULT NULL,
  `paid_mode` varchar(20) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `salary_dues_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `salary_dues` DISABLE KEYS */;
/*!40000 ALTER TABLE `salary_dues` ENABLE KEYS */;
DROP TABLE IF EXISTS `salary_heads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_heads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name` varchar(80) NOT NULL,
  `head_type` enum('earning','deduction') NOT NULL DEFAULT 'earning',
  `calc_type` enum('fixed','percent_basic','percent_gross') NOT NULL DEFAULT 'fixed',
  `default_value` decimal(12,2) NOT NULL DEFAULT 0.00,
  `is_basic` tinyint(1) NOT NULL DEFAULT 0,
  `is_taxable` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(11) NOT NULL DEFAULT 10,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `salary_heads` DISABLE KEYS */;
INSERT INTO `salary_heads` VALUES
(1,'BASIC','Basic Salary','earning','fixed',0.00,1,1,1,'Active'),
(2,'HRENT','House Rent','earning','percent_basic',50.00,0,0,2,'Active'),
(3,'MEDICAL','Medical Allowance','earning','percent_basic',10.00,0,0,3,'Active'),
(4,'CONV','Conveyance','earning','fixed',1500.00,0,0,4,'Active'),
(5,'MOBILE','Mobile Allowance','earning','fixed',0.00,0,1,5,'Active');
/*!40000 ALTER TABLE `salary_heads` ENABLE KEYS */;
DROP TABLE IF EXISTS `salary_review_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_review_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `review_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `old_basic` decimal(12,2) NOT NULL,
  `new_basic` decimal(12,2) NOT NULL,
  `increase` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `review_id` (`review_id`),
  KEY `employee_id` (`employee_id`),
  CONSTRAINT `salary_review_items_ibfk_1` FOREIGN KEY (`review_id`) REFERENCES `salary_reviews` (`id`) ON DELETE CASCADE,
  CONSTRAINT `salary_review_items_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `salary_review_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `salary_review_items` ENABLE KEYS */;
DROP TABLE IF EXISTS `salary_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `salary_reviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `review_no` varchar(30) NOT NULL,
  `title` varchar(150) NOT NULL,
  `grade_id` int(11) DEFAULT NULL,
  `percent` decimal(5,2) NOT NULL DEFAULT 10.00,
  `calc_method` enum('simple','compound') NOT NULL DEFAULT 'simple',
  `effective_date` date NOT NULL,
  `min_service_months` int(11) NOT NULL DEFAULT 12,
  `status` enum('Draft','Approved','Applied','Rejected') NOT NULL DEFAULT 'Draft',
  `remarks` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `review_no` (`review_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `salary_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `salary_reviews` ENABLE KEYS */;
DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `skey` varchar(80) NOT NULL,
  `svalue` text DEFAULT NULL,
  `grp` varchar(40) NOT NULL DEFAULT 'general',
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`skey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES
('company_address','House 12, Road 5, Gulshan, Dhaka-1212','company','2026-10-12 03:06:42'),
('company_email','hr@democompany.com','company','2026-10-12 03:06:42'),
('company_name','Demo Company Ltd.','company','2026-10-12 03:06:42'),
('company_phone','+880 1700-000000','company','2026-10-12 03:06:42'),
('currency_symbol','৳','company','2026-10-12 03:06:42'),
('payroll_cycle_start_day','1','payroll','2026-10-12 03:06:42');
/*!40000 ALTER TABLE `settings` ENABLE KEYS */;
DROP TABLE IF EXISTS `tax_challans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tax_challans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `challan_no` varchar(40) NOT NULL,
  `deposit_date` date NOT NULL,
  `period_month` date NOT NULL,
  `bank_name` varchar(120) DEFAULT NULL,
  `amount` decimal(14,2) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `tax_challans` DISABLE KEYS */;
/*!40000 ALTER TABLE `tax_challans` ENABLE KEYS */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) DEFAULT NULL,
  `username` varchar(80) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role_id` int(11) NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `role_id` (`role_id`),
  KEY `fk_users_employee` (`employee_id`),
  CONSTRAINT `fk_users_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL,
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,NULL,'admin','admin@example.com','$2y$10$S/2lY9PGc.J7LRYE3a.IOOCd/.I4do4wiTXJFIWYhmv1//AIUxbKm',1,'active',0,NULL,'2026-10-12 03:06:42');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
DROP TABLE IF EXISTS `vehicle_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `max_loan_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `interest_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `max_installments` int(11) NOT NULL DEFAULT 60,
  `min_grade_level` int(11) NOT NULL DEFAULT 1,
  `fuel_allowance` decimal(12,2) NOT NULL DEFAULT 0.00,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `vehicle_types` DISABLE KEYS */;
INSERT INTO `vehicle_types` VALUES
(1,'Motorcycle',250000.00,6.00,36,8,2000.00,'Active'),
(2,'Car',1500000.00,7.00,60,4,8000.00,'Active');
/*!40000 ALTER TABLE `vehicle_types` ENABLE KEYS */;
DROP TABLE IF EXISTS `work_shifts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_shifts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `start_time` time NOT NULL DEFAULT '09:00:00',
  `end_time` time NOT NULL DEFAULT '18:00:00',
  `grace_minutes` int(11) NOT NULL DEFAULT 10,
  `half_day_hours` decimal(4,2) NOT NULL DEFAULT 4.00,
  `weekly_off` varchar(40) NOT NULL DEFAULT 'Fri',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `work_shifts` DISABLE KEYS */;
INSERT INTO `work_shifts` VALUES
(1,'General Shift','09:00:00','18:00:00',10,4.00,'Fri','Active');
/*!40000 ALTER TABLE `work_shifts` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

