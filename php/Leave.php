<?php
require_once __DIR__ . '/Employee.php';

/* PRODUCTS: each leave type has its own rules. */
abstract class LeaveRequest {
    public $id; public $employeeId; public $from; public $to; public $reason; public $status;

    public function __construct(array $d) {
        $this->id = $d['id']; $this->employeeId = (int)$d['employeeId'];
        $this->from = $d['from']; $this->to = $d['to'];
        $this->reason = $d['reason']; $this->status = $d['status'];
    }
    abstract public function type(): string;
    abstract public function maxDays(): int;          // longest single request
    abstract public function deductsBalance(): bool;  // counts against yearly leave days?

    public function days(): int {
        return (new DateTime($this->from))->diff(new DateTime($this->to))->days + 1;
    }
    public function toArray(): array {
        return ['id' => $this->id, 'employeeId' => $this->employeeId, 'type' => $this->type(),
                'from' => $this->from, 'to' => $this->to, 'days' => $this->days(),
                'reason' => $this->reason, 'status' => $this->status];
    }
}
class AnnualLeave extends LeaveRequest {
    public function type(): string { return 'annual'; }
    public function maxDays(): int { return 15; }
    public function deductsBalance(): bool { return true; }
}
class CasualLeave extends LeaveRequest {
    public function type(): string { return 'casual'; }
    public function maxDays(): int { return 3; }
    public function deductsBalance(): bool { return true; }
}
class SickLeave extends LeaveRequest {
    public function type(): string { return 'sick'; }
    public function maxDays(): int { return 14; }
    public function deductsBalance(): bool { return false; } // sick leave has its own allowance
}

/* CREATOR: createLeave() is the factory method. */
abstract class LeaveFactory {
    abstract protected function createLeave(array $d): LeaveRequest;

    public function register(array $d): LeaveRequest {
        $from = parseYmd((string)$d['from']);
        $to = parseYmd((string)$d['to']);
        if ($to < $from) throw new InvalidArgumentException('End date must not be before start date.');
        if (trim((string)$d['reason']) === '') throw new InvalidArgumentException('Reason is required.');
        $leave = $this->createLeave($d);
        if ($leave->days() > $leave->maxDays()) {
            throw new InvalidArgumentException(ucfirst($leave->type()) . ' leave allows at most ' . $leave->maxDays() . ' days at a time.');
        }
        return $leave;
    }
    public static function forType(string $type): LeaveFactory {
        switch ($type) {
            case 'annual': return new AnnualLeaveFactory();
            case 'casual': return new CasualLeaveFactory();
            case 'sick':   return new SickLeaveFactory();
        }
        throw new InvalidArgumentException('Unknown leave type.');
    }
}
class AnnualLeaveFactory extends LeaveFactory { protected function createLeave(array $d): LeaveRequest { return new AnnualLeave($d); } }
class CasualLeaveFactory extends LeaveFactory { protected function createLeave(array $d): LeaveRequest { return new CasualLeave($d); } }
class SickLeaveFactory extends LeaveFactory   { protected function createLeave(array $d): LeaveRequest { return new SickLeave($d); } }
