<?php
require_once __DIR__ . '/EmployeeFactory.php';
require_once __DIR__ . '/Leave.php';
require_once __DIR__ . '/Attendance.php';

/* Small helper hidden behind the Facade: reads/writes one JSON file. */
class JsonRepository {
    private $file;
    public function __construct(string $file) { $this->file = $file; }

    public function all(): array {
        if (!file_exists($this->file)) return [];
        $rows = json_decode(file_get_contents($this->file), true);
        return is_array($rows) ? $rows : [];
    }
    public function nextId(): int {
        $max = 0;
        foreach ($this->all() as $r) $max = max($max, (int)$r['id']);
        return $max + 1;
    }
    public function add(array $row): void {
        $rows = $this->all();
        $rows[] = $row;
        $this->saveAll($rows);
    }
    public function saveAll(array $rows): void {
        file_put_contents($this->file, json_encode(array_values($rows), JSON_PRETTY_PRINT), LOCK_EX);
    }
}

/* FACADE pattern.
   The web pages and api.php talk only to this class.
   Storage, factories, validation, balances and salary rules stay hidden inside. */
class HRFacade {
    private $employeeRepo; private $leaveRepo; private $attRepo;
    private $holidayRepo; private $noticeRepo; private $deptRepo;
    private $jobRepo; private $candRepo; private $intRepo; private $offerRepo;

    public function __construct(string $dir) {
        $this->employeeRepo = new JsonRepository($dir . '/employees.json');
        $this->leaveRepo = new JsonRepository($dir . '/leaves.json');
        $this->attRepo = new JsonRepository($dir . '/attendance.json');
        $this->holidayRepo = new JsonRepository($dir . '/holidays.json');
        $this->noticeRepo = new JsonRepository($dir . '/notices.json');
        $this->deptRepo = new JsonRepository($dir . '/departments.json');
        $this->jobRepo = new JsonRepository($dir . '/jobs.json');
        $this->candRepo = new JsonRepository($dir . '/candidates.json');
        $this->intRepo = new JsonRepository($dir . '/interviews.json');
        $this->offerRepo = new JsonRepository($dir . '/offers.json');
    }

    /* ---- hidden helpers: every object is rebuilt through its factory ---- */
    private function employees(): array {
        return array_map(function ($r) { return EmployeeFactory::forType($r['type'])->register($r); }, $this->employeeRepo->all());
    }
    private function employeeMap(): array {
        $map = [];
        foreach ($this->employees() as $e) $map[(int)$e->id] = $e;
        return $map;
    }
    private function findEmployee(int $id): Employee {
        $map = $this->employeeMap();
        if (!isset($map[$id])) throw new InvalidArgumentException('Choose an employee.');
        return $map[$id];
    }
    private function leaves(): array {
        return array_map(function ($r) { return LeaveFactory::forType($r['type'])->register($r); }, $this->leaveRepo->all());
    }
    private function attendance(): array {
        return array_map(function ($r) { return AttendanceFactory::forStatus($r['status'])->register($r); }, $this->attRepo->all());
    }
    private function usedDays(int $employeeId): int {
        $used = 0;
        foreach ($this->leaves() as $l) {
            if ($l->employeeId === $employeeId && $l->status === 'approved' && $l->deductsBalance()) $used += $l->days();
        }
        return $used;
    }

    /* ---- employees ---- */
    public function addEmployee(array $in): array {
        $type = strtolower(trim($in['type'] ?? ''));
        $row = [
            'id' => $this->employeeRepo->nextId(), 'type' => $type,
            'name' => trim($in['name'] ?? ''), 'email' => trim($in['email'] ?? ''),
            'department' => trim($in['department'] ?? ''), 'baseSalary' => $in['baseSalary'] ?? 0,
        ];
        $employee = EmployeeFactory::forType($type)->register($row);
        $this->employeeRepo->add($row);
        return $employee->toArray();
    }
    public function listEmployees(): array {
        return array_map(function ($e) { return $e->toArray(); }, $this->employees());
    }

    /* ---- leave ---- */
    public function applyLeave(array $in): array {
        $emp = $this->findEmployee((int)($in['employeeId'] ?? 0));
        $type = strtolower(trim($in['type'] ?? ''));
        $row = [
            'id' => $this->leaveRepo->nextId(), 'employeeId' => (int)$emp->id, 'type' => $type,
            'from' => trim($in['from'] ?? ''), 'to' => trim($in['to'] ?? ''),
            'reason' => trim($in['reason'] ?? ''), 'status' => 'pending',
        ];
        $leave = LeaveFactory::forType($type)->register($row);
        if ($leave->deductsBalance() && $leave->days() > $emp->leaveDays() - $this->usedDays((int)$emp->id)) {
            throw new InvalidArgumentException('Not enough leave balance.');
        }
        $this->leaveRepo->add($row);
        return $leave->toArray();
    }
    public function listLeaves(): array {
        $map = $this->employeeMap();
        return array_map(function ($l) use ($map) {
            $a = $l->toArray();
            $a['employeeName'] = isset($map[$l->employeeId]) ? $map[$l->employeeId]->name : 'Unknown';
            return $a;
        }, array_reverse($this->leaves()));
    }
    public function decideLeave(int $id, string $status): array {
        if (!in_array($status, ['approved', 'rejected'], true)) throw new InvalidArgumentException('Invalid decision.');
        $rows = $this->leaveRepo->all();
        foreach ($rows as $i => $r) {
            if ((int)$r['id'] !== $id) continue;
            if ($r['status'] !== 'pending') throw new InvalidArgumentException('This request was already decided.');
            if ($status === 'approved') {
                $leave = LeaveFactory::forType($r['type'])->register($r);
                $emp = $this->findEmployee((int)$r['employeeId']);
                if ($leave->deductsBalance() && $leave->days() > $emp->leaveDays() - $this->usedDays((int)$emp->id)) {
                    throw new InvalidArgumentException('Not enough leave balance to approve.');
                }
            }
            $rows[$i]['status'] = $status;
            $this->leaveRepo->saveAll($rows);
            return ['id' => $id, 'status' => $status];
        }
        throw new InvalidArgumentException('Leave request not found.');
    }
    public function leaveBalance(): array {
        $out = [];
        foreach ($this->employees() as $e) {
            $used = $this->usedDays((int)$e->id);
            $out[] = ['name' => $e->name, 'type' => $e->type(), 'entitled' => $e->leaveDays(),
                      'used' => $used, 'remaining' => $e->leaveDays() - $used];
        }
        return $out;
    }

    /* ---- attendance ---- */
    public function markAttendance(array $in): array {
        $emp = $this->findEmployee((int)($in['employeeId'] ?? 0));
        $status = strtolower(trim($in['status'] ?? ''));
        $date = trim($in['date'] ?? '');
        foreach ($this->attRepo->all() as $r) {
            if ((int)$r['employeeId'] === (int)$emp->id && $r['date'] === $date) {
                throw new InvalidArgumentException('Attendance is already marked for this employee on this date.');
            }
        }
        $row = ['id' => $this->attRepo->nextId(), 'employeeId' => (int)$emp->id, 'date' => $date, 'status' => $status];
        $record = AttendanceFactory::forStatus($status)->register($row);
        $this->attRepo->add($row);
        return $record->toArray();
    }
    public function listAttendance(): array {
        $map = $this->employeeMap();
        $rows = array_map(function ($a) use ($map) {
            $r = $a->toArray();
            $r['employeeName'] = isset($map[$a->employeeId]) ? $map[$a->employeeId]->name : 'Unknown';
            return $r;
        }, $this->attendance());
        usort($rows, function ($x, $y) { return strcmp($y['date'], $x['date']) ?: $y['id'] - $x['id']; });
        return array_slice($rows, 0, 30);
    }
    public function monthlyAttendance(string $month): array {
        if (!preg_match('/^\d{4}-\d{2}$/', $month)) throw new InvalidArgumentException('Choose a month.');
        $out = [];
        foreach ($this->employees() as $e) {
            $out[(int)$e->id] = ['name' => $e->name, 'present' => 0, 'late' => 0, 'halfday' => 0, 'absent' => 0, 'workDays' => 0];
        }
        foreach ($this->attendance() as $a) {
            if (strpos($a->date, $month) !== 0 || !isset($out[$a->employeeId])) continue;
            $out[$a->employeeId][$a->status()]++;
            $out[$a->employeeId]['workDays'] += $a->workDays();
        }
        return array_values($out);
    }

    /* ---- dashboard and payroll ---- */
    public function dashboardStats(): array {
        $total = 0; $payroll = 0; $today = date('Y-m-d');
        foreach ($this->employees() as $e) { $total++; $payroll += $e->monthlySalary(); }
        $present = 0;
        foreach ($this->attendance() as $a) if ($a->date === $today && $a->workDays() > 0) $present++;
        $onLeave = 0; $pending = 0;
        foreach ($this->leaves() as $l) {
            if ($l->status === 'pending') $pending++;
            if ($l->status === 'approved' && $l->from <= $today && $today <= $l->to) $onLeave++;
        }
        return ['total' => $total, 'monthlyPayroll' => round($payroll, 2),
                'presentToday' => $present, 'onLeave' => $onLeave, 'pendingLeaves' => $pending];
    }
    public function payrollSummary(): array {
        $groups = []; $grand = 0;
        foreach ($this->employees() as $e) {
            $t = $e->type();
            if (!isset($groups[$t])) $groups[$t] = ['type' => $t, 'count' => 0, 'total' => 0];
            $groups[$t]['count']++;
            $groups[$t]['total'] += $e->monthlySalary();
            $grand += $e->monthlySalary();
        }
        return ['rows' => array_values($groups), 'grandTotal' => round($grand, 2)];
    }

    /* ---- Step 4: leave types & holiday calendar ---- */
    public function leaveTypes(): array {
        $dummy = ['id' => 0, 'employeeId' => 0, 'from' => '2026-01-01', 'to' => '2026-01-01',
                  'reason' => '-', 'status' => 'approved'];
        $out = [];
        foreach ([new AnnualLeave($dummy), new CasualLeave($dummy), new SickLeave($dummy), new EmergencyLeave($dummy)] as $l) {
            $out[] = ['type' => $l->type(), 'maxDays' => $l->maxDays(), 'deductsBalance' => $l->deductsBalance()];
        }
        return $out;
    }
    public function listHolidays(): array {
        $rows = $this->holidayRepo->all();
        usort($rows, function ($a, $b) { return strcmp($a['date'], $b['date']); });
        foreach ($rows as $i => $r) $rows[$i]['day'] = date('l', strtotime($r['date']));
        return $rows;
    }

    /* ---- Step 5: notices ---- */
    public function listNotices(): array {
        return array_reverse($this->noticeRepo->all());
    }
    public function addNotice(array $in): array {
        $title = trim($in['title'] ?? '');
        $body = trim($in['body'] ?? '');
        if ($title === '') throw new InvalidArgumentException('Title is required.');
        if ($body === '') throw new InvalidArgumentException('Notice text is required.');
        $row = ['id' => $this->noticeRepo->nextId(), 'title' => $title, 'body' => $body, 'date' => date('Y-m-d')];
        $this->noticeRepo->add($row);
        return $row;
    }

    /* ---- Step 5: departments ---- */
    public function listDepartments(): array {
        $counts = [];
        foreach ($this->employeeRepo->all() as $r) {
            $k = strtolower(trim((string)$r['department']));
            $counts[$k] = ($counts[$k] ?? 0) + 1;
        }
        $out = [];
        foreach ($this->deptRepo->all() as $d) {
            $out[] = ['name' => $d['name'], 'employees' => $counts[strtolower($d['name'])] ?? 0];
        }
        return $out;
    }
    public function addDepartment(array $in): array {
        $name = trim($in['name'] ?? '');
        if ($name === '') throw new InvalidArgumentException('Department name is required.');
        foreach ($this->deptRepo->all() as $d) {
            if (strtolower($d['name']) === strtolower($name)) throw new InvalidArgumentException('This department already exists.');
        }
        $row = ['id' => $this->deptRepo->nextId(), 'name' => $name];
        $this->deptRepo->add($row);
        return $row;
    }

    /* ---- Step 5: payslips ---- */
    public function payslips(string $month): array {
        if (!preg_match('/^\d{4}-\d{2}$/', $month)) throw new InvalidArgumentException('Choose a month.');
        $rows = []; $totals = ['gross' => 0.0, 'pf' => 0.0, 'net' => 0.0];
        foreach ($this->employees() as $e) {
            $b = $this->payslipFor($e);
            $rows[] = ['id' => $e->id, 'name' => $e->name, 'type' => $e->type()] + $b;
            $totals['gross'] += $b['gross']; $totals['pf'] += $b['pf']; $totals['net'] += $b['net'];
        }
        foreach ($totals as $k => $v) $totals[$k] = round($v, 2);
        return ['month' => $month, 'rows' => $rows, 'totals' => $totals];
    }
    /* The same per-type salary rules as Employee::monthlySalary(), shown as a breakdown,
       so every payslip total matches the payroll summary exactly. */
    private function payslipFor(Employee $e): array {
        if ($e instanceof PermanentEmployee) {
            $basic = $e->baseSalary;
            $allow = round($basic * 0.20, 2);
            $pf = round($basic * 0.05, 2);
            return ['basic' => $basic, 'allowances' => $allow, 'gross' => $basic + $allow,
                    'pf' => $pf, 'net' => $basic + $allow - $pf,
                    'note' => 'Allowances 20% of basic, PF 5% of basic'];
        }
        if ($e instanceof InternEmployee) {
            $pay = $e->monthlySalary();
            return ['basic' => $pay, 'allowances' => 0, 'gross' => $pay, 'pf' => 0, 'net' => $pay,
                    'note' => $e->baseSalary > 15000 ? 'Stipend capped at 15,000' : 'Fixed stipend'];
        }
        return ['basic' => $e->baseSalary, 'allowances' => 0, 'gross' => $e->baseSalary,
                'pf' => 0, 'net' => $e->baseSalary, 'note' => 'Flat contract pay'];
    }

    /* ---- Step 6: reports (read-only summaries over the same data) ---- */
    public function employeeReport(): array {
        $byType = []; $byDept = []; $cost = 0.0; $rows = [];
        foreach ($this->employees() as $e) {
            $rows[] = $e->toArray();
            $cost += $e->monthlySalary();
            $t = $e->type(); $byType[$t] = ($byType[$t] ?? 0) + 1;
            $d = $e->department; $byDept[$d] = ($byDept[$d] ?? 0) + 1;
        }
        $typeRows = []; foreach ($byType as $t => $c) $typeRows[] = ['type' => $t, 'count' => $c];
        $deptRows = []; foreach ($byDept as $d => $c) $deptRows[] = ['department' => $d, 'count' => $c];
        return ['total' => count($rows), 'monthlyCost' => round($cost, 2),
                'byType' => $typeRows, 'byDepartment' => $deptRows, 'rows' => $rows];
    }
    public function leaveReport(): array {
        $counts = ['pending' => 0, 'approved' => 0, 'rejected' => 0];
        $daysByType = [];
        foreach ($this->leaves() as $l) {
            $counts[$l->status] = ($counts[$l->status] ?? 0) + 1;
            if ($l->status === 'approved') {
                $t = $l->type();
                $daysByType[$t] = ($daysByType[$t] ?? 0) + $l->days();
            }
        }
        $typeRows = []; foreach ($daysByType as $t => $d) $typeRows[] = ['type' => $t, 'days' => $d];
        return ['total' => array_sum($counts), 'counts' => $counts,
                'approvedDaysByType' => $typeRows, 'rows' => $this->listLeaves()];
    }
    public function attendanceReport(string $month): array {
        $rows = $this->monthlyAttendance($month);
        $totals = ['present' => 0, 'late' => 0, 'halfday' => 0, 'absent' => 0, 'workDays' => 0.0];
        foreach ($rows as $i => $r) {
            $marked = $r['present'] + $r['late'] + $r['halfday'] + $r['absent'];
            $rows[$i]['percent'] = $marked > 0 ? round($r['workDays'] / $marked * 100, 1) : 0;
            foreach ($totals as $k => $v) $totals[$k] += $r[$k];
        }
        $totals['workDays'] = round($totals['workDays'], 1);
        return ['month' => $month, 'rows' => $rows, 'totals' => $totals];
    }
    public function payrollReport(string $month): array {
        $slips = $this->payslips($month);
        $groups = [];
        foreach ($slips['rows'] as $r) {
            $t = $r['type'];
            if (!isset($groups[$t])) $groups[$t] = ['type' => $t, 'count' => 0, 'gross' => 0.0, 'pf' => 0.0, 'net' => 0.0];
            $groups[$t]['count']++;
            $groups[$t]['gross'] += $r['gross'];
            $groups[$t]['pf'] += $r['pf'];
            $groups[$t]['net'] += $r['net'];
        }
        foreach ($groups as $t => $g) {
            $groups[$t]['gross'] = round($g['gross'], 2);
            $groups[$t]['pf'] = round($g['pf'], 2);
            $groups[$t]['net'] = round($g['net'], 2);
        }
        return ['month' => $month, 'rows' => array_values($groups), 'totals' => $slips['totals']];
    }

    /* ---- Step 7: recruitment ---- */
    private function jobMap(): array {
        $map = [];
        foreach ($this->jobRepo->all() as $j) $map[(int)$j['id']] = $j;
        return $map;
    }
    private function findJob(int $id): array {
        $map = $this->jobMap();
        if (!isset($map[$id])) throw new InvalidArgumentException('Choose a job opening.');
        return $map[$id];
    }
    private function candMap(): array {
        $map = [];
        foreach ($this->candRepo->all() as $c) $map[(int)$c['id']] = $c;
        return $map;
    }
    private function findCandidate(int $id): array {
        $map = $this->candMap();
        if (!isset($map[$id])) throw new InvalidArgumentException('Choose a candidate.');
        return $map[$id];
    }
    private function setStage(int $id, string $stage): void {
        $rows = $this->candRepo->all();
        foreach ($rows as $i => $r) {
            if ((int)$r['id'] === $id) { $rows[$i]['stage'] = $stage; break; }
        }
        $this->candRepo->saveAll($rows);
    }

    public function listJobs(): array {
        $counts = [];
        foreach ($this->candRepo->all() as $c) $counts[(int)$c['jobId']] = ($counts[(int)$c['jobId']] ?? 0) + 1;
        $out = [];
        foreach ($this->jobRepo->all() as $j) {
            $j['candidates'] = $counts[(int)$j['id']] ?? 0;
            $out[] = $j;
        }
        return array_reverse($out);
    }
    public function addJob(array $in): array {
        $title = trim($in['title'] ?? '');
        $dept = trim($in['department'] ?? '');
        $openings = (int)($in['openings'] ?? 0);
        $deadline = trim($in['deadline'] ?? '');
        if ($title === '') throw new InvalidArgumentException('Job title is required.');
        if ($dept === '') throw new InvalidArgumentException('Department is required.');
        if ($openings < 1) throw new InvalidArgumentException('Openings must be at least 1.');
        parseYmd($deadline);
        $row = ['id' => $this->jobRepo->nextId(), 'title' => $title, 'department' => $dept,
                'openings' => $openings, 'deadline' => $deadline, 'status' => 'open'];
        $this->jobRepo->add($row);
        return $row;
    }
    public function closeJob(int $id): array {
        $rows = $this->jobRepo->all();
        foreach ($rows as $i => $r) {
            if ((int)$r['id'] !== $id) continue;
            if ($r['status'] !== 'open') throw new InvalidArgumentException('This opening is already closed.');
            $rows[$i]['status'] = 'closed';
            $this->jobRepo->saveAll($rows);
            return ['id' => $id, 'status' => 'closed'];
        }
        throw new InvalidArgumentException('Job opening not found.');
    }

    public function listCandidates(): array {
        $jobs = $this->jobMap();
        $out = [];
        foreach ($this->candRepo->all() as $c) {
            $c['jobTitle'] = isset($jobs[(int)$c['jobId']]) ? $jobs[(int)$c['jobId']]['title'] : 'Unknown';
            $out[] = $c;
        }
        return array_reverse($out);
    }
    public function addCandidate(array $in): array {
        $job = $this->findJob((int)($in['jobId'] ?? 0));
        $name = trim($in['name'] ?? '');
        $email = trim($in['email'] ?? '');
        $phone = trim($in['phone'] ?? '');
        if ($name === '') throw new InvalidArgumentException('Name is required.');
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) throw new InvalidArgumentException('Enter a valid email.');
        if ($phone === '') throw new InvalidArgumentException('Phone is required.');
        $row = ['id' => $this->candRepo->nextId(), 'name' => $name, 'email' => $email, 'phone' => $phone,
                'jobId' => (int)$job['id'], 'stage' => 'applied', 'appliedDate' => date('Y-m-d')];
        $this->candRepo->add($row);
        return $row;
    }
    public function setCandidateStage(int $id, string $stage): array {
        $flow = ['applied', 'screening', 'interview', 'offered', 'hired', 'rejected'];
        if (!in_array($stage, $flow, true)) throw new InvalidArgumentException('Invalid stage.');
        $cand = $this->findCandidate($id);
        if (in_array($cand['stage'], ['hired', 'rejected'], true)) {
            throw new InvalidArgumentException('This candidate is already ' . $cand['stage'] . '.');
        }
        $this->setStage($id, $stage);
        return ['id' => $id, 'stage' => $stage];
    }

    public function listInterviews(): array {
        $cands = $this->candMap();
        $jobs = $this->jobMap();
        $out = [];
        foreach ($this->intRepo->all() as $r) {
            $c = $cands[(int)$r['candidateId']] ?? null;
            $r['candidateName'] = $c ? $c['name'] : 'Unknown';
            $r['jobTitle'] = ($c && isset($jobs[(int)$c['jobId']])) ? $jobs[(int)$c['jobId']]['title'] : 'Unknown';
            $out[] = $r;
        }
        return array_reverse($out);
    }
    public function scheduleInterview(array $in): array {
        $cand = $this->findCandidate((int)($in['candidateId'] ?? 0));
        if (in_array($cand['stage'], ['hired', 'rejected'], true)) {
            throw new InvalidArgumentException('Cannot schedule an interview for a ' . $cand['stage'] . ' candidate.');
        }
        $date = trim($in['date'] ?? '');
        parseYmd($date);
        $time = trim($in['time'] ?? '');
        $interviewer = trim($in['interviewer'] ?? '');
        if ($time === '') throw new InvalidArgumentException('Time is required.');
        if ($interviewer === '') throw new InvalidArgumentException('Interviewer is required.');
        $row = ['id' => $this->intRepo->nextId(), 'candidateId' => (int)$cand['id'], 'date' => $date,
                'time' => $time, 'interviewer' => $interviewer, 'status' => 'scheduled', 'result' => null];
        $this->intRepo->add($row);
        if (in_array($cand['stage'], ['applied', 'screening'], true)) $this->setStage((int)$cand['id'], 'interview');
        return $row;
    }
    public function interviewResult(int $id, string $result): array {
        if (!in_array($result, ['selected', 'rejected'], true)) throw new InvalidArgumentException('Invalid result.');
        $rows = $this->intRepo->all();
        foreach ($rows as $i => $r) {
            if ((int)$r['id'] !== $id) continue;
            if ($r['status'] !== 'scheduled') throw new InvalidArgumentException('This interview is already completed.');
            $rows[$i]['status'] = 'completed';
            $rows[$i]['result'] = $result;
            $this->intRepo->saveAll($rows);
            if ($result === 'rejected') $this->setStage((int)$r['candidateId'], 'rejected');
            return ['id' => $id, 'status' => 'completed', 'result' => $result];
        }
        throw new InvalidArgumentException('Interview not found.');
    }

    public function listOffers(): array {
        $cands = $this->candMap();
        $jobs = $this->jobMap();
        $out = [];
        foreach ($this->offerRepo->all() as $o) {
            $c = $cands[(int)$o['candidateId']] ?? null;
            $j = ($c && isset($jobs[(int)$c['jobId']])) ? $jobs[(int)$c['jobId']] : null;
            $o['candidateName'] = $c ? $c['name'] : 'Unknown';
            $o['candidateEmail'] = $c ? $c['email'] : '';
            $o['jobTitle'] = $j ? $j['title'] : 'Unknown';
            $o['department'] = $j ? $j['department'] : '';
            $out[] = $o;
        }
        return array_reverse($out);
    }
    public function createOffer(array $in): array {
        $cand = $this->findCandidate((int)($in['candidateId'] ?? 0));
        if (in_array($cand['stage'], ['hired', 'rejected'], true)) {
            throw new InvalidArgumentException('Cannot make an offer to a ' . $cand['stage'] . ' candidate.');
        }
        $salary = $in['salary'] ?? 0;
        if (!is_numeric($salary) || $salary <= 0) throw new InvalidArgumentException('Salary must be more than 0.');
        $joining = trim($in['joiningDate'] ?? '');
        parseYmd($joining);
        $row = ['id' => $this->offerRepo->nextId(), 'candidateId' => (int)$cand['id'],
                'salary' => (float)$salary, 'joiningDate' => $joining,
                'issueDate' => date('Y-m-d'), 'status' => 'sent'];
        $this->offerRepo->add($row);
        $this->setStage((int)$cand['id'], 'offered');
        return $row;
    }
}
