<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/HRFacade.php';

$hr = new HRFacade(__DIR__ . '/../data');

try {
    $action = $_GET['action'] ?? '';
    $isPost = $_SERVER['REQUEST_METHOD'] === 'POST';
    $in = $isPost ? json_decode(file_get_contents('php://input'), true) : [];
    $in = is_array($in) ? $in : [];
    if (in_array($action, ['add', 'leaveApply', 'leaveDecide', 'attMark', 'noticeAdd', 'deptAdd',
                           'jobAdd', 'jobClose', 'candidateAdd', 'candidateStage',
                           'interviewAdd', 'interviewResult', 'offerAdd'], true) && !$isPost) {
        throw new InvalidArgumentException('POST required.');
    }
    switch ($action) {
        case 'add':          $data = $hr->addEmployee($in); break;
        case 'list':         $data = $hr->listEmployees(); break;
        case 'stats':        $data = $hr->dashboardStats(); break;
        case 'payroll':      $data = $hr->payrollSummary(); break;
        case 'leaveApply':   $data = $hr->applyLeave($in); break;
        case 'leaveList':    $data = $hr->listLeaves(); break;
        case 'leaveDecide':  $data = $hr->decideLeave((int)($in['id'] ?? 0), (string)($in['status'] ?? '')); break;
        case 'leaveBalance': $data = $hr->leaveBalance(); break;
        case 'attMark':      $data = $hr->markAttendance($in); break;
        case 'attList':      $data = $hr->listAttendance(); break;
        case 'attMonthly':   $data = $hr->monthlyAttendance((string)($_GET['month'] ?? date('Y-m'))); break;
        case 'leaveTypes':   $data = $hr->leaveTypes(); break;
        case 'holidays':     $data = $hr->listHolidays(); break;
        case 'notices':      $data = $hr->listNotices(); break;
        case 'noticeAdd':    $data = $hr->addNotice($in); break;
        case 'departments':  $data = $hr->listDepartments(); break;
        case 'deptAdd':      $data = $hr->addDepartment($in); break;
        case 'payslips':     $data = $hr->payslips((string)($_GET['month'] ?? date('Y-m'))); break;
        case 'empReport':    $data = $hr->employeeReport(); break;
        case 'leaveReport':  $data = $hr->leaveReport(); break;
        case 'attReport':    $data = $hr->attendanceReport((string)($_GET['month'] ?? date('Y-m'))); break;
        case 'payrollReport': $data = $hr->payrollReport((string)($_GET['month'] ?? date('Y-m'))); break;
        case 'jobs':         $data = $hr->listJobs(); break;
        case 'jobAdd':       $data = $hr->addJob($in); break;
        case 'jobClose':     $data = $hr->closeJob((int)($in['id'] ?? 0)); break;
        case 'candidates':   $data = $hr->listCandidates(); break;
        case 'candidateAdd': $data = $hr->addCandidate($in); break;
        case 'candidateStage': $data = $hr->setCandidateStage((int)($in['id'] ?? 0), (string)($in['stage'] ?? '')); break;
        case 'interviews':   $data = $hr->listInterviews(); break;
        case 'interviewAdd': $data = $hr->scheduleInterview($in); break;
        case 'interviewResult': $data = $hr->interviewResult((int)($in['id'] ?? 0), (string)($in['result'] ?? '')); break;
        case 'offers':       $data = $hr->listOffers(); break;
        case 'offerAdd':     $data = $hr->createOffer($in); break;
        default: throw new InvalidArgumentException('Unknown action.');
    }
    echo json_encode(['ok' => true, 'data' => $data]);
} catch (InvalidArgumentException $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Server error.']);
}
