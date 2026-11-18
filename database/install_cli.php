<?php
/** Command line installer:  php database/install_cli.php [--demo] [--host=127.0.0.1] [--user=root] [--pass=] [--db=hr_payroll_erp] */
require __DIR__ . '/../app/bootstrap.php';
$opts = [];
foreach (array_slice($argv, 1) as $a) if (preg_match('/^--([a-z]+)(?:=(.*))?$/', $a, $m)) $opts[$m[1]] = $m[2] ?? true;
$db = ['host' => $opts['host'] ?? '127.0.0.1', 'port' => (int) ($opts['port'] ?? 3306), 'user' => $opts['user'] ?? 'root', 'pass' => $opts['pass'] ?? '', 'charset' => 'utf8mb4', 'name' => $opts['db'] ?? 'hr_payroll_erp'];
if (\App\Helpers\Installer::locked() && !isset($opts['force'])) { fwrite(STDERR, "Already installed (storage/installed.lock). Use --force to reinstall.\n"); exit(1); }
if (isset($opts['force']) && is_file(APP_ROOT . '/storage/installed.lock')) unlink(APP_ROOT . '/storage/installed.lock');
if (isset($opts['force'])) { $pdo = \App\Core\Database::connectServer($db); $pdo->exec('DROP DATABASE IF EXISTS `' . preg_replace('/\W/', '', $db['name']) . '`'); }
try { foreach (\App\Helpers\Installer::run($db, isset($opts['demo']), $opts['admin'] ?? 'admin123') as $l) echo "✔ $l\n"; }
catch (Throwable $e) { fwrite(STDERR, "✘ " . $e->getMessage() . "\n  at " . $e->getFile() . ':' . $e->getLine() . "\n"); exit(1); }
