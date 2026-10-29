<?php
require_once __DIR__ . '/Employee.php';

/* PRODUCTS: each attendance status counts differently. */
abstract class AttendanceRecord {
    public $id; public $employeeId; public $date;

    public function __construct(array $d) {
        $this->id = $d['id']; $this->employeeId = (int)$d['employeeId']; $this->date = $d['date'];
    }
    abstract public function status(): string;
    abstract public function workDays(): float;

    public function toArray(): array {
        return ['id' => $this->id, 'employeeId' => $this->employeeId, 'date' => $this->date,
                'status' => $this->status(), 'workDays' => $this->workDays()];
    }
}
class PresentAttendance extends AttendanceRecord {
    public function status(): string { return 'present'; }
    public function workDays(): float { return 1.0; }
}
class LateAttendance extends AttendanceRecord {
    public function status(): string { return 'late'; }
    public function workDays(): float { return 1.0; }
}
class HalfDayAttendance extends AttendanceRecord {
    public function status(): string { return 'halfday'; }
    public function workDays(): float { return 0.5; }
}
class AbsentAttendance extends AttendanceRecord {
    public function status(): string { return 'absent'; }
    public function workDays(): float { return 0.0; }
}

/* CREATOR: createRecord() is the factory method. */
abstract class AttendanceFactory {
    abstract protected function createRecord(array $d): AttendanceRecord;

    public function register(array $d): AttendanceRecord {
        parseYmd((string)$d['date']);
        return $this->createRecord($d);
    }
    public static function forStatus(string $status): AttendanceFactory {
        switch ($status) {
            case 'present': return new PresentAttendanceFactory();
            case 'late':    return new LateAttendanceFactory();
            case 'halfday': return new HalfDayAttendanceFactory();
            case 'absent':  return new AbsentAttendanceFactory();
        }
        throw new InvalidArgumentException('Unknown attendance status.');
    }
}
class PresentAttendanceFactory extends AttendanceFactory { protected function createRecord(array $d): AttendanceRecord { return new PresentAttendance($d); } }
class LateAttendanceFactory extends AttendanceFactory    { protected function createRecord(array $d): AttendanceRecord { return new LateAttendance($d); } }
class HalfDayAttendanceFactory extends AttendanceFactory { protected function createRecord(array $d): AttendanceRecord { return new HalfDayAttendance($d); } }
class AbsentAttendanceFactory extends AttendanceFactory  { protected function createRecord(array $d): AttendanceRecord { return new AbsentAttendance($d); } }
