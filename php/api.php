<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/HRFacade.php';

$hr = new HRFacade(__DIR__ . '/../data');

try {
    $action = $_GET['action'] ?? '';
    $isPost = $_SERVER['REQUEST_METHOD'] === 'POST';
    $in = $isPost ? json_decode(file_get_contents('php://input'), true) : [];
    $in = is_array($in) ? $in : [];
    if (in_array($action, ['add', 'leaveApply', 'leaveDecide', 'attMark'], true) && !$isPost) {
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
