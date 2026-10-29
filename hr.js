(function () {
  var API = "php/api.php";
  var loaders = {};
  var OFFLINE = "Cannot reach the PHP server. Start it with: php -S localhost:8000";

  function $(id) { return document.getElementById(id); }
  function money(n) { return Number(n).toLocaleString("en-US", { maximumFractionDigits: 0 }); }
  function label(t) { return t.charAt(0).toUpperCase() + t.slice(1); }
  function esc(s) { var d = document.createElement("div"); d.textContent = s; return d.innerHTML; }
  function errText(e) { return (e instanceof TypeError || e instanceof SyntaxError) ? OFFLINE : e.message; }

  // Every request goes to api.php, which uses the HRFacade
  function call(action, body) {
    var opt = body ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) } : {};
    return fetch(API + "?action=" + action, opt)
      .then(function (r) { return r.json(); })
      .then(function (j) { if (!j.ok) throw new Error(j.error); return j.data; });
  }

  function loadStats() {
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
        return "<tr><td>" + e.id + "</td><td>" + esc(e.name) + "<small>" + esc(e.email) + "</small></td>" +
          "<td><span class=\"tag " + e.type + "\">" + label(e.type) + "</span></td><td>" + esc(e.department) +
          "</td><td>" + e.leaveDays + "</td><td>" + money(e.monthlySalary) + "</td></tr>";
      }).join("") || "<tr><td colspan=\"6\">No employees yet.</td></tr>";
    }).catch(function (e) { body.innerHTML = "<tr><td colspan=\"6\">" + esc(errText(e)) + "</td></tr>"; });
  }

  function loadPayroll() {
    var body = $("payBody");
    call("payroll").then(function (d) {
      body.innerHTML = d.rows.map(function (r) {
        return "<tr><td><span class=\"tag " + r.type + "\">" + label(r.type) + "</span></td><td>" + r.count + "</td><td>" + money(r.total) + "</td></tr>";
      }).join("") + "<tr class=\"sum\"><td>Total</td><td></td><td>" + money(d.grandTotal) + "</td></tr>";
    }).catch(function (e) { body.innerHTML = "<tr><td colspan=\"3\">" + esc(errText(e)) + "</td></tr>"; });
  }

  function go(p) {
    document.querySelectorAll(".content[id^=page-]").forEach(function (x) { x.hidden = x.id !== "page-" + p; });
    $("topTitle").textContent = $("page-" + p).getAttribute("data-title") || "Dashboard";
    document.querySelectorAll(".nav-item").forEach(function (b) {
      b.classList.toggle("current", b.getAttribute("data-page") === p);
    });
    if (loaders[p]) loaders[p]();
    $("sidebar").classList.remove("open");
    $("overlay").classList.remove("show");
  }

  loaders.dashboard = loadStats; loaders.employees = loadList; loaders.payroll = loadPayroll;
  window.TAA = { call: call, esc: esc, money: money, label: label, errText: errText, loaders: loaders };

  document.querySelectorAll("[data-page]").forEach(function (b) {
    b.addEventListener("click", function () { go(b.getAttribute("data-page")); });
  });

  function empMsg(type, text) {
    var el = $("empMsg");
    el.className = "msg " + (text ? "show " + type : "");
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

  loadStats();
})();
