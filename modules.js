(function () {
  var T = window.TAA;
  function $(id) { return document.getElementById(id); }
  function fill(id, html, cols, empty) { $(id).innerHTML = html || "<tr><td colspan=\"" + cols + "\" class=\"empty\">" + empty + "</td></tr>"; }
  function fail(id, cols, e) { fill(id, "", cols, T.esc(T.errText(e))); }
  function msg(id, type, text) {
    var el = $(id);
    el.className = "notice form-msg " + (text ? (type === "ok" ? "ok" : "bad") : "bad hide");
    el.textContent = text || "";
  }
  function tag(t) { return T.badge(t); }
  function today() { return new Date().toISOString().slice(0, 10); }

  function employeeOptions(selId) {
    T.call("list").then(function (rows) {
      $(selId).innerHTML = rows.map(function (e) { return "<option value=\"" + e.id + "\">" + T.esc(e.name) + "</option>"; }).join("");
    }).catch(function () {});
  }

  /* ----- Leave ----- */
  $("leaveForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("leaveMsg", "", "");
    T.call("leaveApply", { employeeId: $("lvEmp").value, type: $("lvType").value, from: $("lvFrom").value, to: $("lvTo").value, reason: $("lvReason").value })
      .then(function (l) { $("leaveForm").reset(); msg("leaveMsg", "ok", "Request sent for " + l.days + " day(s). Waiting for approval."); })
      .catch(function (err) { msg("leaveMsg", "err", T.errText(err)); });
  });

  function loadApproval() {
    T.call("leaveList").then(function (rows) {
      fill("lvBody", rows.map(function (l) {
        var act = l.status === "pending"
          ? "<div class=\"row-actions\" style=\"justify-content:flex-start\"><button class=\"btn sm success\" type=\"button\" data-id=\"" + l.id + "\" data-st=\"approved\">Approve</button> <button class=\"btn sm danger\" type=\"button\" data-id=\"" + l.id + "\" data-st=\"rejected\">Reject</button></div>" : "";
        return "<tr><td>" + l.id + "</td><td>" + T.esc(l.employeeName) + "</td><td>" + tag(l.type) + "</td><td>" + l.from + " to " + l.to + " (" + l.days + "d)<span class=\"sub-line\">" + T.esc(l.reason) + "</span></td><td>" + tag(l.status) + "</td><td>" + act + "</td></tr>";
      }).join(""), 6, "No leave requests yet.");
    }).catch(function (e) { fail("lvBody", 6, e); });
  }
  $("lvBody").addEventListener("click", function (e) {
    var b = e.target.closest("button[data-id]");
    if (!b) return;
    T.call("leaveDecide", { id: b.getAttribute("data-id"), status: b.getAttribute("data-st") })
      .then(loadApproval).catch(function (err) { alert(T.errText(err)); });
  });

  function loadBalance() {
    T.call("leaveBalance").then(function (rows) {
      fill("lbBody", rows.map(function (r) {
        return "<tr><td>" + T.esc(r.name) + "</td><td>" + tag(r.type) + "</td><td class=\"num\">" + r.entitled + "</td><td class=\"num\">" + r.used + "</td><td class=\"num\"><b>" + r.remaining + "</b></td></tr>";
      }).join(""), 5, "No employees yet.");
    }).catch(function (e) { fail("lbBody", 5, e); });
  }

  /* ----- Attendance ----- */
  $("attForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("attMsg", "", "");
    T.call("attMark", { employeeId: $("atEmp").value, date: $("atDate").value, status: $("atStatus").value })
      .then(function () { msg("attMsg", "ok", "Attendance saved."); loadDaily(false); })
      .catch(function (err) { msg("attMsg", "err", T.errText(err)); });
  });

  function loadDaily(withOptions) {
    if (withOptions !== false) { employeeOptions("atEmp"); if (!$("atDate").value) $("atDate").value = today(); }
    T.call("attList").then(function (rows) {
      fill("atBody", rows.map(function (r) {
        return "<tr><td>" + r.date + "</td><td>" + T.esc(r.employeeName) + "</td><td>" + tag(r.status) + "</td><td class=\"num\">" + r.workDays + "</td></tr>";
      }).join(""), 4, "No records yet.");
    }).catch(function (e) { fail("atBody", 4, e); });
  }

  function loadMonthly() {
    if (!$("atMonth").value) $("atMonth").value = today().slice(0, 7);
    T.call("attMonthly&month=" + $("atMonth").value).then(function (rows) {
      fill("amBody", rows.map(function (r) {
        return "<tr><td>" + T.esc(r.name) + "</td><td class=\"num\">" + r.present + "</td><td class=\"num\">" + r.late + "</td><td class=\"num\">" + r.halfday + "</td><td class=\"num\">" + r.absent + "</td><td class=\"num\"><b>" + r.workDays + "</b></td></tr>";
      }).join(""), 6, "No employees yet.");
    }).catch(function (e) { fail("amBody", 6, e); });
  }
  $("atMonth").addEventListener("change", loadMonthly);

  T.loaders.leaveApply = function () { employeeOptions("lvEmp"); };
  T.loaders.leaveApproval = loadApproval;
  T.loaders.leaveBalance = loadBalance;
  T.loaders.attDaily = loadDaily;
  T.loaders.attMonthly = loadMonthly;

  /* ----- Step 4: leave types & holiday calendar ----- */
  function loadLeaveTypes() {
    T.call("leaveTypes").then(function (rows) {
      fill("ltBody", rows.map(function (r) {
        return "<tr><td>" + tag(r.type) + "</td><td class=\"num\">" + r.maxDays + "</td><td>" + (r.deductsBalance ? "Yes" : "No (own allowance)") + "</td></tr>";
      }).join(""), 3, "No leave types found.");
    }).catch(function (e) { fail("ltBody", 3, e); });
  }

  function loadHolidays() {
    T.call("holidays").then(function (rows) {
      fill("holBody", rows.map(function (r) {
        return "<tr><td>" + r.date + "</td><td>" + T.esc(r.day) + "</td><td>" + T.esc(r.name) + "</td><td>" + tag(String(r.type).toLowerCase()) + "</td></tr>";
      }).join(""), 4, "No holidays found.");
    }).catch(function (e) { fail("holBody", 4, e); });
  }

  /* ----- Step 5: notices ----- */
  function loadNotices() {
    T.call("notices").then(function (rows) {
      $("ntList").innerHTML = rows.map(function (n) {
        return "<div class=\"card narrow\" style=\"margin-bottom:14px\"><div class=\"card-pad\"><b>" + T.esc(n.title) + "</b><div class=\"small muted\" style=\"margin:2px 0 6px\">" + n.date + "</div><div>" + T.esc(n.body) + "</div></div></div>";
      }).join("") || "<div class=\"card narrow\"><div class=\"card-pad muted\">No notices yet.</div></div>";
    }).catch(function () { $("ntList").innerHTML = ""; });
  }
  $("noticeForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("ntMsg", "", "");
    T.call("noticeAdd", { title: $("ntTitle").value, body: $("ntBody").value })
      .then(function () { $("noticeForm").reset(); msg("ntMsg", "ok", "Notice published."); loadNotices(); })
      .catch(function (err) { msg("ntMsg", "err", T.errText(err)); });
  });

  /* ----- Step 5: payslips ----- */
  function loadPayslips() {
    if (!$("psMonth").value) $("psMonth").value = today().slice(0, 7);
    T.call("payslips&month=" + $("psMonth").value).then(function (d) {
      fill("psBody", d.rows.map(function (r) {
        return "<tr><td>" + T.esc(r.name) + "</td><td>" + tag(r.type) + "</td><td class=\"num\">" + T.money(r.basic) + "</td><td class=\"num\">" + T.money(r.allowances) + "</td><td class=\"num\">" + T.money(r.gross) + "</td><td class=\"num\">" + T.money(r.pf) + "</td><td class=\"num\"><b>" + T.money(r.net) + "</b></td><td class=\"small muted\">" + T.esc(r.note) + "</td></tr>";
      }).join("") + "<tr class=\"sum\"><td>Total</td><td></td><td></td><td></td><td class=\"num\">" + T.money(d.totals.gross) + "</td><td class=\"num\">" + T.money(d.totals.pf) + "</td><td class=\"num\">" + T.money(d.totals.net) + "</td><td></td></tr>", 8, "No employees yet.");
    }).catch(function (e) { fail("psBody", 8, e); });
  }
  $("psMonth").addEventListener("change", loadPayslips);

  /* ----- Step 5: departments ----- */
  function loadDepartments() {
    T.call("departments").then(function (rows) {
      fill("dpBody", rows.map(function (r) {
        return "<tr><td>" + T.esc(r.name) + "</td><td class=\"num\">" + r.employees + "</td></tr>";
      }).join(""), 2, "No departments yet.");
      var dl = $("deptList");
      if (dl) dl.innerHTML = rows.map(function (r) { return "<option value=\"" + T.esc(r.name) + "\">"; }).join("");
    }).catch(function (e) { fail("dpBody", 2, e); });
  }
  $("deptForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("dpMsg", "", "");
    T.call("deptAdd", { name: $("dpName").value })
      .then(function () { $("deptForm").reset(); msg("dpMsg", "ok", "Department added."); loadDepartments(); })
      .catch(function (err) { msg("dpMsg", "err", T.errText(err)); });
  });

  T.loaders.leaveTypes = loadLeaveTypes;
  T.loaders.holidays = loadHolidays;
  T.loaders.notices = loadNotices;
  T.loaders.payslips = loadPayslips;
  T.loaders.departments = loadDepartments;

  /* ----- Step 6: reports ----- */
  function downloadCsv(name, header, rows) {
    var lines = [header].concat(rows).map(function (r) {
      return r.map(function (c) { return "\"" + String(c == null ? "" : c).replace(/"/g, "\"\"") + "\""; }).join(",");
    });
    var a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([lines.join("\n")], { type: "text/csv" }));
    a.download = name;
    a.click();
    URL.revokeObjectURL(a.href);
  }
  var lastReport = {};

  function loadEmpReport() {
    T.call("empReport").then(function (d) {
      lastReport.employee = d;
      $("erSummary").innerHTML =
        "<div class=\"list-row\"><div class=\"grow\">Total employees</div><b>" + d.total + "</b></div>" +
        d.byType.map(function (r) { return "<div class=\"list-row\"><div class=\"grow\">" + T.label(r.type) + "</div><b>" + r.count + "</b></div>"; }).join("") +
        d.byDepartment.map(function (r) { return "<div class=\"list-row\"><div class=\"grow\">Department: " + T.esc(r.department) + "</div><b>" + r.count + "</b></div>"; }).join("") +
        "<div class=\"list-row\"><div class=\"grow\">Total monthly salary cost</div><b>" + T.money(d.monthlyCost) + "</b></div>";
      fill("erBody", d.rows.map(function (e) {
        return "<tr><td>" + e.id + "</td><td>" + T.esc(e.name) + "<span class=\"sub-line\">" + T.esc(e.email) + "</span></td><td>" + tag(e.type) + "</td><td>" + T.esc(e.department) + "</td><td class=\"num\">" + e.leaveDays + "</td><td class=\"num\">" + T.money(e.monthlySalary) + "</td></tr>";
      }).join(""), 6, "No employees yet.");
    }).catch(function (e) { fail("erBody", 6, e); });
  }
  $("erCsv").addEventListener("click", function () {
    var d = lastReport.employee; if (!d) return;
    downloadCsv("employee-report.csv", ["ID", "Name", "Email", "Type", "Department", "Leave days", "Monthly salary"],
      d.rows.map(function (e) { return [e.id, e.name, e.email, e.type, e.department, e.leaveDays, e.monthlySalary]; }));
  });

  function loadAttReport() {
    if (!$("arMonth").value) $("arMonth").value = today().slice(0, 7);
    T.call("attReport&month=" + $("arMonth").value).then(function (d) {
      lastReport.attendance = d;
      fill("arBody", d.rows.map(function (r) {
        return "<tr><td>" + T.esc(r.name) + "</td><td class=\"num\">" + r.present + "</td><td class=\"num\">" + r.late + "</td><td class=\"num\">" + r.halfday + "</td><td class=\"num\">" + r.absent + "</td><td class=\"num\">" + r.workDays + "</td><td class=\"num\"><b>" + r.percent + "%</b></td></tr>";
      }).join("") + "<tr class=\"sum\"><td>Total</td><td class=\"num\">" + d.totals.present + "</td><td class=\"num\">" + d.totals.late + "</td><td class=\"num\">" + d.totals.halfday + "</td><td class=\"num\">" + d.totals.absent + "</td><td class=\"num\">" + d.totals.workDays + "</td><td></td></tr>", 7, "No employees yet.");
    }).catch(function (e) { fail("arBody", 7, e); });
  }
  $("arMonth").addEventListener("change", loadAttReport);
  $("arCsv").addEventListener("click", function () {
    var d = lastReport.attendance; if (!d) return;
    downloadCsv("attendance-report-" + d.month + ".csv", ["Employee", "Present", "Late", "Half day", "Absent", "Work days", "Work day %"],
      d.rows.map(function (r) { return [r.name, r.present, r.late, r.halfday, r.absent, r.workDays, r.percent]; }));
  });

  function loadLeaveReport() {
    T.call("leaveReport").then(function (d) {
      lastReport.leave = d;
      $("lrSummary").innerHTML =
        "<div class=\"list-row\"><div class=\"grow\">Total requests</div><b>" + d.total + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Pending</div><b>" + d.counts.pending + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Approved</div><b>" + d.counts.approved + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Rejected</div><b>" + d.counts.rejected + "</b></div>" +
        d.approvedDaysByType.map(function (r) { return "<div class=\"list-row\"><div class=\"grow\">Approved " + T.label(r.type) + " days</div><b>" + r.days + "</b></div>"; }).join("");
      fill("lrBody", d.rows.map(function (l) {
        return "<tr><td>" + l.id + "</td><td>" + T.esc(l.employeeName) + "</td><td>" + tag(l.type) + "</td><td>" + l.from + " to " + l.to + "</td><td class=\"num\">" + l.days + "</td><td>" + tag(l.status) + "</td></tr>";
      }).join(""), 6, "No leave requests yet.");
    }).catch(function (e) { fail("lrBody", 6, e); });
  }
  $("lrCsv").addEventListener("click", function () {
    var d = lastReport.leave; if (!d) return;
    downloadCsv("leave-report.csv", ["ID", "Employee", "Type", "From", "To", "Days", "Status", "Reason"],
      d.rows.map(function (l) { return [l.id, l.employeeName, l.type, l.from, l.to, l.days, l.status, l.reason]; }));
  });

  function loadPayrollReport() {
    if (!$("prMonth").value) $("prMonth").value = today().slice(0, 7);
    T.call("payrollReport&month=" + $("prMonth").value).then(function (d) {
      lastReport.payroll = d;
      fill("prBody", d.rows.map(function (r) {
        return "<tr><td>" + tag(r.type) + "</td><td class=\"num\">" + r.count + "</td><td class=\"num\">" + T.money(r.gross) + "</td><td class=\"num\">" + T.money(r.pf) + "</td><td class=\"num\"><b>" + T.money(r.net) + "</b></td></tr>";
      }).join("") + "<tr class=\"sum\"><td>Total</td><td></td><td class=\"num\">" + T.money(d.totals.gross) + "</td><td class=\"num\">" + T.money(d.totals.pf) + "</td><td class=\"num\">" + T.money(d.totals.net) + "</td></tr>", 5, "No employees yet.");
    }).catch(function (e) { fail("prBody", 5, e); });
  }
  $("prMonth").addEventListener("change", loadPayrollReport);
  $("prCsv").addEventListener("click", function () {
    var d = lastReport.payroll; if (!d) return;
    downloadCsv("payroll-report-" + d.month + ".csv", ["Type", "Employees", "Gross", "PF", "Net pay"],
      d.rows.map(function (r) { return [r.type, r.count, r.gross, r.pf, r.net]; }));
  });

  T.loaders.reportEmployee = loadEmpReport;
  T.loaders.reportAttendance = loadAttReport;
  T.loaders.reportLeave = loadLeaveReport;
  T.loaders.reportPayroll = loadPayrollReport;
})();
