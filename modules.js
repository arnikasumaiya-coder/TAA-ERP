(function () {
  var T = window.TAA;
  function $(id) { return document.getElementById(id); }
  function fill(id, html, cols, empty) { $(id).innerHTML = html || "<tr><td colspan=\"" + cols + "\">" + empty + "</td></tr>"; }
  function fail(id, cols, e) { fill(id, "", cols, T.esc(T.errText(e))); }
  function msg(id, type, text) { var el = $(id); el.className = "msg " + (text ? "show " + type : ""); el.textContent = text || ""; }
  function tag(t) { return "<span class=\"tag " + t + "\">" + (t === "halfday" ? "Half day" : T.label(t)) + "</span>"; }
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
          ? "<button class=\"mini ok\" data-id=\"" + l.id + "\" data-st=\"approved\">Approve</button> <button class=\"mini no\" data-id=\"" + l.id + "\" data-st=\"rejected\">Reject</button>" : "";
        return "<tr><td>" + l.id + "</td><td>" + T.esc(l.employeeName) + "</td><td>" + tag(l.type) + "</td><td>" + l.from + " to " + l.to + " (" + l.days + "d)<small>" + T.esc(l.reason) + "</small></td><td>" + tag(l.status) + "</td><td>" + act + "</td></tr>";
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
        return "<tr><td>" + T.esc(r.name) + "</td><td>" + tag(r.type) + "</td><td>" + r.entitled + "</td><td>" + r.used + "</td><td><b>" + r.remaining + "</b></td></tr>";
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
        return "<tr><td>" + r.date + "</td><td>" + T.esc(r.employeeName) + "</td><td>" + tag(r.status) + "</td><td>" + r.workDays + "</td></tr>";
      }).join(""), 4, "No records yet.");
    }).catch(function (e) { fail("atBody", 4, e); });
  }

  function loadMonthly() {
    if (!$("atMonth").value) $("atMonth").value = today().slice(0, 7);
    T.call("attMonthly&month=" + $("atMonth").value).then(function (rows) {
      fill("amBody", rows.map(function (r) {
        return "<tr><td>" + T.esc(r.name) + "</td><td>" + r.present + "</td><td>" + r.late + "</td><td>" + r.halfday + "</td><td>" + r.absent + "</td><td><b>" + r.workDays + "</b></td></tr>";
      }).join(""), 6, "No employees yet.");
    }).catch(function (e) { fail("amBody", 6, e); });
  }
  $("atMonth").addEventListener("change", loadMonthly);

  T.loaders.leaveApply = function () { employeeOptions("lvEmp"); };
  T.loaders.leaveApproval = loadApproval;
  T.loaders.leaveBalance = loadBalance;
  T.loaders.attDaily = loadDaily;
  T.loaders.attMonthly = loadMonthly;
})();
