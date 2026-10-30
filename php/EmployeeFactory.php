<?php
require_once __DIR__ . '/Employee.php';

/* CREATOR of the Factory Method pattern.
   createEmployee() is the "factory method": each subclass decides
   which Employee class to build. */
abstract class EmployeeFactory {
    abstract protected function createEmployee(array $d): Employee;

    public function register(array $d): Employee {
        $this->validate($d);
        return $this->createEmployee($d);
    }

    protected function validate(array $d): void {
        if (trim($d['name']) === '') throw new InvalidArgumentException('Name is required.');
        if (!filter_var($d['email'], FILTER_VALIDATE_EMAIL)) throw new InvalidArgumentException('Enter a valid email.');
        if (trim($d['department']) === '') throw new InvalidArgumentException('Department is required.');
        if (!is_numeric($d['baseSalary']) || $d['baseSalary'] <= 0) throw new InvalidArgumentException('Salary must be more than 0.');
    }

    // Picks the right factory for the chosen type
    public static function forType(string $type): EmployeeFactory {
        switch ($type) {
            case 'permanent': return new PermanentEmployeeFactory();
            case 'contract':  return new ContractEmployeeFactory();
            case 'intern':    return new InternEmployeeFactory();
        }
        throw new InvalidArgumentException('Unknown employee type.');
    }
}

class PermanentEmployeeFactory extends EmployeeFactory {
    protected function createEmployee(array $d): Employee { return new PermanentEmployee($d); }
}
class ContractEmployeeFactory extends EmployeeFactory {
    protected function createEmployee(array $d): Employee { return new ContractEmployee($d); }
}
class InternEmployeeFactory extends EmployeeFactory {
    protected function createEmployee(array $d): Employee { return new InternEmployee($d); }
}
