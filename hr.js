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
      .then(function (r) { return r.json(); })
      .then(function (j) { if (!j.ok) throw new Error(j.error); return j.data; });
  }

  function greeting() {
    var h = new Date().getHours();
    var part = h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
    $("dashGreet").textContent = part + ", Demo";
    $("dashDate").textContent = new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" }) + " \u00b7 Here is an overview of your workspace";
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

  loaders.dashboard = loadStats; loaders.employees = loadList; loaders.payroll = loadPayroll;
  window.TAA = { call: call, esc: esc, money: money, label: label, errText: errText, badge: badge, loaders: loaders };

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

  loadStats();
})();
