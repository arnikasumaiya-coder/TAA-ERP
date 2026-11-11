<?php
/* Step 8: reads an attendance sheet uploaded by an employee.
   Accepts .xlsx (read with ZipArchive + SimpleXML, no external library)
   or .csv. Expected columns: Date | Status — a header row is detected
   when a cell contains the word "date"; without a header the first two
   columns are used. Statuses are normalised (P, Late, Half Day, ...)
   and validated later by the Facade through the attendance factories. */
class AttendanceImport {

    public static function parse(string $path, string $originalName): array {
        $ext = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
        if ($ext === 'csv' || $ext === 'txt') $grid = self::readCsv($path);
        elseif ($ext === 'xlsx') $grid = self::readXlsx($path);
        else throw new InvalidArgumentException('Upload an Excel (.xlsx) or .csv file.');
        return self::toRows($grid);
    }

    /* ---------- grid -> row list ---------- */
    private static function toRows(array $grid): array {
        $dateCol = 0; $statusCol = 1; $start = 0;
        foreach ($grid as $i => $row) {
            if ($i > 4) break;
            $found = false;
            foreach ($row as $c => $cell) {
                $v = strtolower(trim((string)$cell));
                if (strpos($v, 'date') !== false) { $dateCol = $c; $found = true; }
                if (strpos($v, 'status') !== false || strpos($v, 'attendance') !== false) $statusCol = $c;
            }
            if ($found) { $start = $i + 1; break; }
        }
        $rows = [];
        for ($i = $start; $i < count($grid); $i++) {
            $date = trim((string)($grid[$i][$dateCol] ?? ''));
            $status = trim((string)($grid[$i][$statusCol] ?? ''));
            if ($date === '' && $status === '') continue;
            $rows[] = ['row' => $i + 1, 'date' => self::normaliseDate($date), 'status' => self::normaliseStatus($status)];
        }
        if (!$rows) throw new InvalidArgumentException('No attendance rows found in the file. Use the template: Date | Status.');
        return $rows;
    }

    private static function normaliseDate(string $v): string {
        if ($v === '') return '';
        // Excel stores dates as day numbers (days since 1899-12-30)
        if (is_numeric($v) && (float)$v > 20000 && (float)$v < 80000) {
            $base = new DateTime('1899-12-30');
            $base->modify('+' . (int)floor((float)$v) . ' days');
            return $base->format('Y-m-d');
        }
        $v = str_replace('/', '-', $v);
        if (preg_match('/^(\d{1,2})-(\d{1,2})-(\d{4})$/', $v, $m)) {
            // 02-11-2026 style is ambiguous; dd-mm-yyyy is the local habit
            if ((int)$m[1] > 12 || (int)$m[2] <= 12) return sprintf('%04d-%02d-%02d', (int)$m[3], (int)$m[2], (int)$m[1]);
        }
        return substr($v, 0, 10);
    }

    private static function normaliseStatus(string $v): string {
        $s = strtolower(str_replace([' ', '_'], '', $v));
        $map = ['p' => 'present', 'l' => 'late', 'h' => 'halfday', 'a' => 'absent',
                'half' => 'halfday', 'yes' => 'present', 'no' => 'absent'];
        return $map[$s] ?? $s;
    }

    /* ---------- CSV ---------- */
    private static function readCsv(string $path): array {
        $fh = fopen($path, 'r');
        if (!$fh) throw new InvalidArgumentException('Could not read the uploaded file.');
        $first = fgets($fh);
        rewind($fh);
        $delim = ($first !== false && substr_count($first, ';') > substr_count($first, ',')) ? ';' : ',';
        $grid = [];
        while (($r = fgetcsv($fh, 0, $delim)) !== false) $grid[] = $r;
        fclose($fh);
        return $grid;
    }

    /* ---------- XLSX (zip of XML) ---------- */
    private static function readXlsx(string $path): array {
        $entries = self::zipReadAll($path);

        $shared = [];
        if (isset($entries['xl/sharedStrings.xml'])) {
            $sx = self::xml($entries['xl/sharedStrings.xml']);
            foreach ($sx->si as $si) {
                $text = '';
                foreach ($si->xpath('.//t') ?: [] as $t) $text .= (string)$t;
                if ($text === '' && isset($si->t)) $text = (string)$si->t;
                $shared[] = $text;
            }
        }

        $sheetXml = $entries['xl/worksheets/sheet1.xml'] ?? null;
        if ($sheetXml === null) {
            foreach ($entries as $name => $content) {
                if (preg_match('#^xl/worksheets/sheet\d+\.xml$#', $name)) { $sheetXml = $content; break; }
            }
        }
        if ($sheetXml === null) throw new InvalidArgumentException('No worksheet found in the .xlsx file.');

        $sx = self::xml($sheetXml);
        $grid = [];
        foreach ($sx->sheetData->row as $row) {
            $cells = [];
            foreach ($row->c as $c) {
                $ref = (string)$c['r'];
                $col = self::colIndex($ref);
                $type = (string)$c['t'];
                if ($type === 's') $val = $shared[(int)$c->v] ?? '';
                elseif ($type === 'inlineStr') $val = isset($c->is) && isset($c->is->t) ? (string)$c->is->t : '';
                else $val = isset($c->v) ? (string)$c->v : '';
                $cells[$col] = $val;
            }
            if ($cells) { ksort($cells); $grid[] = $cells; }
        }
        return $grid;
    }

    /* Reads every file inside a zip into a name => content map.
       Uses ZipArchive when the server has it; otherwise falls back to a
       small built-in zip reader, so .xlsx works on any PHP setup
       (some XAMPP installs ship with the zip extension switched off). */
    private static function zipReadAll(string $path): array {
        if (class_exists('ZipArchive')) {
            $zip = new ZipArchive();
            if ($zip->open($path) !== true) throw new InvalidArgumentException('The .xlsx file could not be opened.');
            $out = [];
            for ($i = 0; $i < $zip->numFiles; $i++) {
                $content = $zip->getFromIndex($i);
                if ($content !== false) $out[(string)$zip->getNameIndex($i)] = $content;
            }
            $zip->close();
            return $out;
        }
        return self::zipReadManual($path);
    }

    private static function zipReadManual(string $path): array {
        $data = file_get_contents($path);
        if ($data === false) throw new InvalidArgumentException('Could not read the uploaded file.');
        $len = strlen($data);
        $eocd = -1;
        for ($i = $len - 22; $i >= 0 && $i > $len - 65558; $i--) {
            if (substr($data, $i, 4) === "PK\x05\x06") { $eocd = $i; break; }
        }
        if ($eocd < 0) throw new InvalidArgumentException('The .xlsx file could not be opened.');
        $count = unpack('v', substr($data, $eocd + 10, 2))[1];
        $p = unpack('V', substr($data, $eocd + 16, 4))[1];
        $out = [];
        for ($n = 0; $n < $count; $n++) {
            if (substr($data, $p, 4) !== "PK\x01\x02") break;
            $method = unpack('v', substr($data, $p + 10, 2))[1];
            $csize = unpack('V', substr($data, $p + 20, 4))[1];
            $nameLen = unpack('v', substr($data, $p + 28, 2))[1];
            $extraLen = unpack('v', substr($data, $p + 30, 2))[1];
            $commentLen = unpack('v', substr($data, $p + 32, 2))[1];
            $local = unpack('V', substr($data, $p + 42, 4))[1];
            $name = substr($data, $p + 46, $nameLen);
            // local header: fixed 30 bytes + its own name/extra lengths
            $lNameLen = unpack('v', substr($data, $local + 26, 2))[1];
            $lExtraLen = unpack('v', substr($data, $local + 28, 2))[1];
            $raw = substr($data, $local + 30 + $lNameLen + $lExtraLen, $csize);
            if ($method === 8) {
                if (!function_exists('gzinflate')) throw new InvalidArgumentException('This server cannot unzip .xlsx files. Upload a .csv instead.');
                $content = gzinflate($raw);
                if ($content === false) throw new InvalidArgumentException('The .xlsx file could not be opened.');
            } elseif ($method === 0) {
                $content = $raw;
            } else {
                throw new InvalidArgumentException('The .xlsx file uses an unsupported compression.');
            }
            $out[$name] = $content;
            $p += 46 + $nameLen + $extraLen + $commentLen;
        }
        if (!$out) throw new InvalidArgumentException('The .xlsx file could not be opened.');
        return $out;
    }

    private static function colIndex(string $ref): int {
        $letters = preg_replace('/[^A-Z]/', '', strtoupper($ref));
        $n = 0;
        for ($i = 0; $i < strlen($letters); $i++) $n = $n * 26 + (ord($letters[$i]) - 64);
        return $n - 1;
    }

    private static function xml(string $text) {
        // strip namespace prefixes so SimpleXML paths stay simple
        $text = preg_replace('/<(\/?)[a-zA-Z][a-zA-Z0-9]*:/', '<$1', $text);
        $x = simplexml_load_string($text);
        if ($x === false) throw new InvalidArgumentException('The file could not be parsed.');
        return $x;
    }
}
