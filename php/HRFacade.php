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

    public function __construct(string $dir) {
        $this->employeeRepo = new JsonRepository($dir . '/employees.json');
        $this->leaveRepo = new JsonRepository($dir . '/leaves.json');
        $this->attRepo = new JsonRepository($dir . '/attendance.json');
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
}
