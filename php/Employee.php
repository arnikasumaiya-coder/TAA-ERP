<?php
/* PRODUCTS of the Factory Method pattern.
   Every employee type has its own leave and salary rule. */
abstract class Employee {
    public $id; public $name; public $email; public $department; public $baseSalary;

    public function __construct(array $d) {
        $this->id = $d['id'];
        $this->name = $d['name'];
        $this->email = $d['email'];
        $this->department = $d['department'];
        $this->baseSalary = (float)$d['baseSalary'];
    }
    abstract public function type(): string;
    abstract public function leaveDays(): int;
    abstract public function monthlySalary(): float;

    public function toArray(): array {
        return [
            'id' => $this->id, 'type' => $this->type(), 'name' => $this->name,
            'email' => $this->email, 'department' => $this->department,
            'baseSalary' => $this->baseSalary, 'leaveDays' => $this->leaveDays(),
            'monthlySalary' => round($this->monthlySalary(), 2),
        ];
    }
}

class PermanentEmployee extends Employee {
    public function type(): string { return 'permanent'; }
    public function leaveDays(): int { return 20; }
    // base + 20% allowances - 5% provident fund
    public function monthlySalary(): float { return $this->baseSalary * 1.15; }
}

class ContractEmployee extends Employee {
    public function type(): string { return 'contract'; }
    public function leaveDays(): int { return 10; }
    public function monthlySalary(): float { return $this->baseSalary; }
}

class InternEmployee extends Employee {
    public function type(): string { return 'intern'; }
    public function leaveDays(): int { return 5; }
    // fixed stipend, capped at 15,000
    public function monthlySalary(): float { return min($this->baseSalary, 15000); }
}

/* Shared helper: strict date parser (YYYY-MM-DD) */
function parseYmd(string $s): DateTime {
    $d = DateTime::createFromFormat('Y-m-d', $s);
    if (!$d || $d->format('Y-m-d') !== $s) throw new InvalidArgumentException('Enter a valid date.');
    return $d;
}
