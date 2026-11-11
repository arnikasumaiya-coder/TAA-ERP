<?php
session_start();
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/HRFacade.php';
require_once __DIR__ . '/AttendanceImport.php';

$hr = new HRFacade(__DIR__ . '/../data');

/* Step 8: role-based access, following the permission-group idea of the
   main ERP (a role sees and changes only its own part of the system).
   The server enforces this map for every action; the menus in the
   browser only mirror it. null = any signed-in role. */
const ROLE_LABELS = [
    'admin' => 'Super Admin', 'hr' => 'HR Manager', 'payroll' => 'Payroll',
    'manager' => 'Line Manager', 'employee' => 'Employee',
];
const PERMS = [
    'stats'         => ['admin', 'hr'],
    'list'          => ['admin', 'hr', 'payroll', 'manager'],
    'add'           => ['admin', 'hr'],
    'leaveApply'    => null,
    'leaveList'     => ['admin', 'hr', 'manager', 'employee'],
    'leaveDecide'   => ['admin', 'hr', 'manager'],
    'leaveBalance'  => ['admin', 'hr', 'manager', 'employee'],
    'attMark'       => ['admin', 'hr'],
    'attList'       => ['admin', 'hr', 'manager', 'employee'],
    'attMonthly'    => ['admin', 'hr', 'manager', 'employee'],
    'attUpload'     => ['manager', 'employee'],
    'leaveTypes'    => ['admin', 'hr', 'manager', 'employee'],
    'holidays'      => null,
    'notices'       => null,
    'noticeAdd'     => ['admin', 'hr'],
    'departments'   => ['admin', 'hr', 'manager'],
    'deptAdd'       => ['admin', 'hr'],
    'payslips'      => ['admin', 'payroll', 'manager', 'employee'],
    'payroll'       => ['admin', 'payroll'],
    'empReport'     => ['admin', 'hr'],
    'attReport'     => ['admin', 'hr', 'manager'],
    'leaveReport'   => ['admin', 'hr', 'manager'],
    'payrollReport' => ['admin', 'payroll'],
    'jobs'          => ['admin', 'hr'],
    'jobAdd'        => ['admin', 'hr'],
    'jobClose'      => ['admin', 'hr'],
    'candidates'    => ['admin', 'hr'],
    'candidateAdd'  => ['admin', 'hr'],
    'candidateStage' => ['admin', 'hr'],
    'interviews'    => ['admin', 'hr'],
    'interviewAdd'  => ['admin', 'hr'],
    'interviewResult' => ['admin', 'hr'],
    'offers'        => ['admin', 'hr'],
    'offerAdd'      => ['admin', 'hr'],
];

function fail(int $code, string $msg): void {
    http_response_code($code);
    echo json_encode(['ok' => false, 'error' => $msg]);
    exit;
}
function publicUser(array $u): array {
    $u['roleLabel'] = ROLE_LABELS[$u['role']] ?? $u['role'];
    return $u;
}

try {
    $action = $_GET['action'] ?? '';
    $isPost = $_SERVER['REQUEST_METHOD'] === 'POST';
    $in = [];
    if ($isPost && $action !== 'attUpload') {
        $in = json_decode(file_get_contents('php://input'), true);
        $in = is_array($in) ? $in : [];
    }

    /* ---- sign in / out ---- */
    if ($action === 'login') {
        if (!$isPost) throw new InvalidArgumentException('POST required.');
        $user = $hr->authenticate(trim((string)($in['email'] ?? '')), (string)($in['password'] ?? ''));
        if (!$user) fail(401, 'Email or password is incorrect.');
        session_regenerate_id(true);
        $_SESSION['user'] = $user;
        echo json_encode(['ok' => true, 'data' => publicUser($user)]);
        exit;
    }
    if ($action === 'logout') {
        $_SESSION = [];
        session_destroy();
        echo json_encode(['ok' => true, 'data' => true]);
        exit;
    }
    if ($action === 'me') {
        if (empty($_SESSION['user'])) fail(401, 'Not signed in.');
        echo json_encode(['ok' => true, 'data' => publicUser($_SESSION['user'])]);
        exit;
    }

    /* ---- everything below needs a signed-in user with the right role ---- */
    if (empty($_SESSION['user'])) fail(401, 'Please sign in first.');
    $user = $_SESSION['user'];
    $role = $user['role'];
    if (!array_key_exists($action, PERMS)) throw new InvalidArgumentException('Unknown action.');
    $allowed = PERMS[$action];
    if ($allowed !== null && !in_array($role, $allowed, true)) {
        fail(403, 'Access denied: the ' . (ROLE_LABELS[$role] ?? $role) . ' role cannot do this.');
    }
    $ownId = isset($user['employeeId']) ? $user['employeeId'] : null;
    $selfScoped = in_array($role, ['manager', 'employee'], true);

    if (in_array($action, ['add', 'leaveApply', 'leaveDecide', 'attMark', 'noticeAdd', 'deptAdd',
                           'jobAdd', 'jobClose', 'candidateAdd', 'candidateStage',
                           'interviewAdd', 'interviewResult', 'offerAdd', 'attUpload'], true) && !$isPost) {
        throw new InvalidArgumentException('POST required.');
    }
    switch ($action) {
        case 'add':          $data = $hr->addEmployee($in); break;
        case 'list':         $data = $hr->listEmployees(); break;
        case 'stats':        $data = $hr->dashboardStats(); break;
        case 'payroll':      $data = $hr->payrollSummary(); break;
        case 'leaveApply':
            // Line managers and employees can only apply for themselves
            if ($selfScoped) {
                if ($ownId === null) throw new InvalidArgumentException('This account is not linked to an employee.');
                $in['employeeId'] = $ownId;
            }
            $data = $hr->applyLeave($in); break;
        case 'leaveList':    $data = $hr->listLeaves($role === 'employee' ? $ownId : null); break;
        case 'leaveDecide':  $data = $hr->decideLeave((int)($in['id'] ?? 0), (string)($in['status'] ?? '')); break;
        case 'leaveBalance': $data = $hr->leaveBalance($role === 'employee' ? $ownId : null); break;
        case 'attMark':      $data = $hr->markAttendance($in); break;
        case 'attList':      $data = $hr->listAttendance($selfScoped ? $ownId : null); break;
        case 'attMonthly':   $data = $hr->monthlyAttendance((string)($_GET['month'] ?? date('Y-m')), $role === 'employee' ? $ownId : null); break;
        case 'attUpload': {
            if ($ownId === null) throw new InvalidArgumentException('This account is not linked to an employee.');
            if (empty($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
                throw new InvalidArgumentException('Choose an attendance file to upload.');
            }
            if ($_FILES['file']['size'] > 2 * 1024 * 1024) throw new InvalidArgumentException('File is too large (max 2 MB).');
            $rows = AttendanceImport::parse($_FILES['file']['tmp_name'], (string)$_FILES['file']['name']);
            $data = $hr->importAttendance((int)$ownId, $rows);
            break;
        }
        case 'leaveTypes':   $data = $hr->leaveTypes(); break;
        case 'holidays':     $data = $hr->listHolidays(); break;
        case 'notices':      $data = $hr->listNotices(); break;
        case 'noticeAdd':    $data = $hr->addNotice($in); break;
        case 'departments':  $data = $hr->listDepartments(); break;
        case 'deptAdd':      $data = $hr->addDepartment($in); break;
        case 'payslips':     $data = $hr->payslips((string)($_GET['month'] ?? date('Y-m')), $selfScoped ? $ownId : null); break;
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
