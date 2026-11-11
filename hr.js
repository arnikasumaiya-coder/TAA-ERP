(function () {
  var API = "php/api.php";
  var loaders = {};
  var OFFLINE = "Cannot reach the PHP server. Start it with: php -S localhost:8000";

  function $(id) { return document.getElementById(id); }
  function money(n) { return Number(n).toLocaleString("en-US", { maximumFractionDigits: 0 }); }
  function label(t) { return t.charAt(0).toUpperCase() + t.slice(1); }
  function esc(s) { var d = document.createElement("div"); d.textContent = s; return d.innerHTML; }
  function errText(e) { return (e instanceof TypeError || e instanceof SyntaxError) ? OFFLINE : e.message; }

  // Colour of the badge for each type or status (same meaning as before)
  var TONE = {
    permanent: "ok", contract: "warn", intern: "info",
    annual: "ok", casual: "ok", sick: "info", emergency: "warn",
    festival: "info", government: "gray",
    open: "ok", closed: "gray",
    applied: "info", screening: "warn", interview: "info", offered: "ok", hired: "ok",
    scheduled: "warn", completed: "gray", selected: "ok",
    sent: "info", accepted: "ok",
    present: "ok", late: "warn", halfday: "info", absent: "bad",
    pending: "warn", approved: "ok", rejected: "bad"
  };
  function badge(t) {
    return "<span class=\"badge " + (TONE[t] || "gray") + "\">" + (t === "halfday" ? "Half day" : label(t)) + "</span>";
  }

  // Every request goes to api.php, which uses the HRFacade
  function call(action, body) {
    var opt = body ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) } : {};
    return fetch(API + "?action=" + action, opt)
      .then(function (r) {
        if (r.status === 401) { if (window.TAA_EXIT) window.TAA_EXIT(); throw new Error("Your session has ended. Please sign in again."); }
        return r.json();
      })
      .then(function (j) { if (!j.ok) throw new Error(j.error); return j.data; });
  }

  /* ---------- Step 8: roles ----------
     Which pages each role may open. This mirrors the PERMS map in
     php/api.php — the server is what actually enforces it. */
  var PAGES = {
    admin: ["dashboard", "employees", "add", "leaveTypes", "leaveApply", "leaveApproval", "leaveBalance", "holidays", "attDaily", "attMonthly", "notices", "departments", "reportEmployee", "reportAttendance", "reportLeave", "reportPayroll", "jobs", "candidates", "interviews", "offers", "payroll", "payslips"],
    hr: ["dashboard", "employees", "add", "leaveTypes", "leaveApply", "leaveApproval", "leaveBalance", "holidays", "attDaily", "attMonthly", "notices", "departments", "reportEmployee", "reportAttendance", "reportLeave", "jobs", "candidates", "interviews", "offers"],
    payroll: ["dashboard", "employees", "payroll", "payslips", "notices", "holidays", "reportPayroll"],
    manager: ["dashboard", "employees", "leaveTypes", "leaveApply", "leaveApproval", "leaveBalance", "holidays", "attMonthly", "attUpload", "payslips", "notices", "departments", "reportAttendance", "reportLeave"],
    employee: ["dashboard", "leaveTypes", "leaveApply", "leaveBalance", "holidays", "attMonthly", "attUpload", "payslips", "notices"]
  };
  var user = null;
  try { user = JSON.parse(sessionStorage.getItem("taa_user") || "null"); } catch (e) { user = null; }

  function canPage(p) { return !!user && (PAGES[user.role] || []).indexOf(p) !== -1; }

  function applyRole() {
    if (!user) return;
    $("chipName").textContent = user.name;
    $("chipEmail").textContent = user.email + " · " + (user.roleLabel || user.role);
    $("chipAvatar").textContent = user.name.charAt(0).toUpperCase();
    document.querySelectorAll("#sidebar .nav-item").forEach(function (b) {
      var p = b.getAttribute("data-page");
      var showIt = p ? canPage(p) : user.role === "admin";
      b.classList.toggle("hide", !showIt);
    });
    document.querySelectorAll("#sidebar .nav-group").forEach(function (g) {
      g.classList.toggle("hide", !g.querySelector(".nav-item:not(.hide)"));
    });
    document.querySelectorAll(".quick [data-page]").forEach(function (b) {
      b.classList.toggle("hide", !canPage(b.getAttribute("data-page")));
    });
    var org = user.role === "admin" || user.role === "hr";
    $("orgKpis").hidden = !org;
    $("orgCards").hidden = !org;
    $("myDash").hidden = org;
  }

  function greeting() {
    var h = new Date().getHours();
    var part = h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
    var first = user ? user.name.split(" ")[0] : "Demo";
    $("dashGreet").textContent = part + ", " + first;
    $("dashDate").textContent = new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" }) + " · Signed in as " + (user ? (user.roleLabel || user.role) : "");
  }

  function loadStats() {
    greeting();
    call("stats").then(function (d) {
      $("stTotal").textContent = d.total;
      $("stPayslips").textContent = d.total;
      $("stPayroll").textContent = money(d.monthlyPayroll);
      $("stPresent").textContent = d.presentToday;
      $("stOnLeave").textContent = d.onLeave;
      $("stPending").textContent = d.pendingLeaves;
    }).catch(function () {});
  }

  function loadList() {
    var body = $("empBody");
    call("list").then(function (rows) {
      body.innerHTML = rows.map(function (e) {
        return "<tr><td>" + e.id + "</td><td>" + esc(e.name) + "<span class=\"sub-line\">" + esc(e.email) + "</span></td>" +
          "<td>" + badge(e.type) + "</td><td>" + esc(e.department) +
          "</td><td class=\"num\">" + e.leaveDays + "</td><td class=\"num\">" + money(e.monthlySalary) + "</td></tr>";
      }).join("") || "<tr><td colspan=\"6\" class=\"empty\">No employees yet.</td></tr>";
    }).catch(function (e) { body.innerHTML = "<tr><td colspan=\"6\" class=\"empty\">" + esc(errText(e)) + "</td></tr>"; });
  }

  function loadPayroll() {
    var body = $("payBody");
    call("payroll").then(function (d) {
      body.innerHTML = d.rows.map(function (r) {
        return "<tr><td>" + badge(r.type) + "</td><td class=\"num\">" + r.count + "</td><td class=\"num\">" + money(r.total) + "</td></tr>";
      }).join("") + "<tr class=\"sum\"><td>Total</td><td></td><td class=\"num\">" + money(d.grandTotal) + "</td></tr>";
    }).catch(function (e) { body.innerHTML = "<tr><td colspan=\"3\" class=\"empty\">" + esc(errText(e)) + "</td></tr>"; });
  }

  function go(p) {
    if (user && !canPage(p)) p = "dashboard";
    document.querySelectorAll(".page[id^=page-]").forEach(function (x) { x.hidden = x.id !== "page-" + p; });
    var title = $("page-" + p).getAttribute("data-title") || "Dashboard";
    $("topTitle").textContent = "TAA Software \u203a " + title;

    // Highlight the sidebar item and open the group it belongs to
    var active = null;
    document.querySelectorAll("#sidebar .nav-item").forEach(function (b) {
      var on = b.getAttribute("data-page") === p;
      b.classList.toggle("active", on);
      if (on) active = b;
    });
    if (active) {
      var group = active.closest(".nav-group");
      if (group) {
        document.querySelectorAll(".nav-group").forEach(function (g) {
          var open = g === group;
          g.classList.toggle("open", open);
          g.querySelector(".nav-head").setAttribute("aria-expanded", open ? "true" : "false");
        });
      }
    }

    if (loaders[p]) loaders[p]();
    window.scrollTo(0, 0);
    $("sidebar").classList.remove("open");
    $("overlay").classList.remove("show");
  }

  /* Personal dashboard for Payroll, Line Manager and Employee:
     only their own numbers, read from the same scoped API actions. */
  function monthNow() { return new Date().toISOString().slice(0, 7); }

  function loadMyDash() {
    greeting();
    var bal = call("leaveBalance").catch(function () { return []; });
    var att = call("attMonthly&month=" + monthNow()).catch(function () { return []; });
    var slips = call("payslips&month=" + monthNow()).catch(function () { return { rows: [] }; });
    var reqs = call("leaveList").catch(function () { return []; });
    Promise.all([bal, att, slips, reqs]).then(function (rs) {
      var b = rs[0][0] || { entitled: 0, used: 0, remaining: 0 };
      var a = rs[1].filter(function (r) { return r.employeeId === user.employeeId; })[0] || { present: 0, late: 0, halfday: 0, absent: 0, workDays: 0 };
      var s = rs[2].rows[0];
      var mine = rs[3].filter(function (l) { return l.employeeId === user.employeeId; }).slice(0, 5);
      $("myDash").innerHTML =
        "<div class=\"dash-grid\">" +
        "<div class=\"card c6\"><div class=\"card-head\"><h3 class=\"grow\">My leave</h3></div><div class=\"card-pad\">" +
        "<div class=\"list-row\"><div class=\"grow\">Leave days entitled</div><b>" + b.entitled + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Used</div><b>" + b.used + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Remaining</div><b>" + b.remaining + "</b></div></div></div>" +
        "<div class=\"card c6\"><div class=\"card-head\"><h3 class=\"grow\">My attendance this month</h3></div><div class=\"card-pad\">" +
        "<div class=\"list-row\"><div class=\"grow\">Present / Late</div><b>" + a.present + " / " + a.late + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Half day / Absent</div><b>" + a.halfday + " / " + a.absent + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Work days</div><b>" + a.workDays + "</b></div></div></div></div>" +
        "<div class=\"dash-grid\" style=\"margin-top:14px\">" +
        "<div class=\"card c6\"><div class=\"card-head\"><h3 class=\"grow\">My payslip this month</h3></div><div class=\"card-pad\">" +
        (s ? "<div class=\"list-row\"><div class=\"grow\">Gross</div><b>" + money(s.gross) + "</b></div>" +
             "<div class=\"list-row\"><div class=\"grow\">PF</div><b>" + money(s.pf) + "</b></div>" +
             "<div class=\"list-row\"><div class=\"grow\">Net pay</div><b>" + money(s.net) + "</b></div>"
           : "<div class=\"muted\">No payslip found.</div>") + "</div></div>" +
        "<div class=\"card c6\"><div class=\"card-head\"><h3 class=\"grow\">My recent leave requests</h3></div><div class=\"card-pad\">" +
        (mine.length ? mine.map(function (l) {
          return "<div class=\"list-row\"><div class=\"grow\">" + label(l.type) + " · " + l.from + " to " + l.to + "</div>" + badge(l.status) + "</div>";
        }).join("") : "<div class=\"muted\">No requests yet.</div>") + "</div></div></div>";
    });
  }

  function loadPayrollDash() {
    greeting();
    Promise.all([call("payroll"), call("payslips&month=" + monthNow())]).then(function (rs) {
      var p = rs[0], slips = rs[1];
      $("myDash").innerHTML =
        "<div class=\"dash-grid\">" +
        "<div class=\"card c6\"><div class=\"card-head\"><h3 class=\"grow\">Payroll by type</h3></div><div class=\"card-pad\">" +
        p.rows.map(function (r) {
          return "<div class=\"list-row\"><div class=\"grow\">" + label(r.type) + " (" + r.count + ")</div><b>" + money(r.total) + "</b></div>";
        }).join("") +
        "<div class=\"list-row\"><div class=\"grow\">Monthly total</div><b>" + money(p.grandTotal) + "</b></div></div></div>" +
        "<div class=\"card c6\"><div class=\"card-head\"><h3 class=\"grow\">Payslips this month</h3></div><div class=\"card-pad\">" +
        "<div class=\"list-row\"><div class=\"grow\">Employees</div><b>" + slips.rows.length + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Gross</div><b>" + money(slips.totals.gross) + "</b></div>" +
        "<div class=\"list-row\"><div class=\"grow\">Net pay</div><b>" + money(slips.totals.net) + "</b></div></div></div></div>";
    }).catch(function () {});
  }

  function loadDashboard() {
    if (!user) return;
    if (user.role === "admin" || user.role === "hr") loadStats();
    else if (user.role === "payroll") loadPayrollDash();
    else loadMyDash();
  }

  loaders.dashboard = loadDashboard; loaders.employees = loadList; loaders.payroll = loadPayroll;
  window.TAA = { call: call, esc: esc, money: money, label: label, errText: errText, badge: badge, loaders: loaders,
                 user: function () { return user; }, canPage: canPage };

  document.querySelectorAll("[data-page]").forEach(function (b) {
    b.addEventListener("click", function () { go(b.getAttribute("data-page")); });
  });

  function empMsg(type, text) {
    var el = $("empMsg");
    el.className = "notice form-msg " + (text ? (type === "ok" ? "ok" : "bad") : "bad hide");
    el.textContent = text || "";
  }

  $("empForm").addEventListener("submit", function (e) {
    e.preventDefault();
    empMsg("", "");
    call("add", {
      name: $("eName").value, email: $("eEmail").value, department: $("eDept").value,
      type: $("eType").value, baseSalary: $("eSalary").value
    }).then(function (emp) {
      $("empForm").reset();
      empMsg("ok", emp.name + " was added as a " + label(emp.type) + " employee (" + emp.leaveDays + " leave days).");
    }).catch(function (err) { empMsg("err", errText(err)); });
  });

  /* Called by script.js after a successful sign-in, and once on page
     load when a PHP session is still alive (so a refresh stays signed in). */
  window.TAA.onLogin = function (u) {
    user = u;
    try { sessionStorage.setItem("taa_user", JSON.stringify(u)); } catch (e) {}
    applyRole();
    loadDashboard();
  };

  if (user) {
    call("me").then(function (u) {
      user = u;
      try { sessionStorage.setItem("taa_user", JSON.stringify(u)); } catch (e) {}
      applyRole();
      if (window.TAA_ENTER) window.TAA_ENTER();
      loadDashboard();
    }).catch(function () {
      user = null;
      try { sessionStorage.removeItem("taa_user"); } catch (e) {}
    });
  }
})();
