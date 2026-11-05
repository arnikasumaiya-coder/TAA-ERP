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
  var NEXT = { applied: "screening", screening: "interview", interview: "offered", offered: "hired" };
  var NEXT_LABEL = { applied: "Start screening", screening: "Call for interview", interview: "Mark offered", offered: "Mark hired" };

  function jobOptions(selId, onlyOpen) {
    T.call("jobs").then(function (rows) {
      var list = onlyOpen ? rows.filter(function (j) { return j.status === "open"; }) : rows;
      $(selId).innerHTML = list.map(function (j) { return "<option value=\"" + j.id + "\">" + T.esc(j.title) + " (" + T.esc(j.department) + ")</option>"; }).join("");
    }).catch(function () {});
  }
  function candidateOptions(selId) {
    T.call("candidates").then(function (rows) {
      var list = rows.filter(function (c) { return c.stage !== "hired" && c.stage !== "rejected"; });
      $(selId).innerHTML = list.map(function (c) { return "<option value=\"" + c.id + "\">" + T.esc(c.name) + " — " + T.esc(c.jobTitle) + "</option>"; }).join("");
    }).catch(function () {});
  }
  function deptOptions(selId) {
    T.call("departments").then(function (rows) {
      $(selId).innerHTML = rows.map(function (d) { return "<option value=\"" + T.esc(d.name) + "\">" + T.esc(d.name) + "</option>"; }).join("");
    }).catch(function () {});
  }

  /* ----- Job openings ----- */
  function loadJobs() {
    deptOptions("jDept");
    T.call("jobs").then(function (rows) {
      fill("jobBody", rows.map(function (j) {
        var act = j.status === "open" ? "<button class=\"btn sm danger\" type=\"button\" data-close=\"" + j.id + "\">Close</button>" : "";
        return "<tr><td>" + T.esc(j.title) + "</td><td>" + T.esc(j.department) + "</td><td class=\"num\">" + j.openings + "</td><td class=\"num\">" + j.candidates + "</td><td>" + j.deadline + "</td><td>" + tag(j.status) + "</td><td>" + act + "</td></tr>";
      }).join(""), 7, "No job openings yet.");
    }).catch(function (e) { fail("jobBody", 7, e); });
  }
  $("jobForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("jobMsg", "", "");
    T.call("jobAdd", { title: $("jTitle").value, department: $("jDept").value, openings: $("jOpenings").value, deadline: $("jDeadline").value })
      .then(function () { $("jobForm").reset(); $("jOpenings").value = 1; msg("jobMsg", "ok", "Job posted."); loadJobs(); })
      .catch(function (err) { msg("jobMsg", "err", T.errText(err)); });
  });
  $("jobBody").addEventListener("click", function (e) {
    var b = e.target.closest("button[data-close]");
    if (!b) return;
    T.call("jobClose", { id: b.getAttribute("data-close") }).then(loadJobs).catch(function (err) { alert(T.errText(err)); });
  });

  /* ----- Candidates ----- */
  function loadCandidates() {
    jobOptions("cJob", true);
    T.call("candidates").then(function (rows) {
      fill("cdBody", rows.map(function (c) {
        var act = "";
        if (NEXT[c.stage]) {
          act = "<div class=\"row-actions\" style=\"justify-content:flex-start\"><button class=\"btn sm success\" type=\"button\" data-id=\"" + c.id + "\" data-stage=\"" + NEXT[c.stage] + "\">" + NEXT_LABEL[c.stage] + "</button> <button class=\"btn sm danger\" type=\"button\" data-id=\"" + c.id + "\" data-stage=\"rejected\">Reject</button></div>";
        }
        return "<tr><td>" + T.esc(c.name) + "<span class=\"sub-line\">" + T.esc(c.email) + " · " + T.esc(c.phone) + "</span></td><td>" + T.esc(c.jobTitle) + "</td><td>" + c.appliedDate + "</td><td>" + tag(c.stage) + "</td><td>" + act + "</td></tr>";
      }).join(""), 5, "No candidates yet.");
    }).catch(function (e) { fail("cdBody", 5, e); });
  }
  $("candForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("cdMsg", "", "");
    T.call("candidateAdd", { name: $("cName").value, email: $("cEmail").value, phone: $("cPhone").value, jobId: $("cJob").value })
      .then(function () { $("candForm").reset(); msg("cdMsg", "ok", "Candidate added."); loadCandidates(); })
      .catch(function (err) { msg("cdMsg", "err", T.errText(err)); });
  });
  $("cdBody").addEventListener("click", function (e) {
    var b = e.target.closest("button[data-id]");
    if (!b) return;
    T.call("candidateStage", { id: b.getAttribute("data-id"), stage: b.getAttribute("data-stage") })
      .then(loadCandidates).catch(function (err) { alert(T.errText(err)); });
  });

  /* ----- Interviews ----- */
  function loadInterviews() {
    candidateOptions("iCand");
    T.call("interviews").then(function (rows) {
      fill("inBody", rows.map(function (r) {
        var status = r.status === "completed" ? tag(r.result) : tag(r.status);
        var act = r.status === "scheduled"
          ? "<div class=\"row-actions\" style=\"justify-content:flex-start\"><button class=\"btn sm success\" type=\"button\" data-id=\"" + r.id + "\" data-res=\"selected\">Selected</button> <button class=\"btn sm danger\" type=\"button\" data-id=\"" + r.id + "\" data-res=\"rejected\">Rejected</button></div>" : "";
        return "<tr><td>" + T.esc(r.candidateName) + "</td><td>" + T.esc(r.jobTitle) + "</td><td>" + r.date + " " + T.esc(r.time) + "</td><td>" + T.esc(r.interviewer) + "</td><td>" + status + "</td><td>" + act + "</td></tr>";
      }).join(""), 6, "No interviews yet.");
    }).catch(function (e) { fail("inBody", 6, e); });
  }
  $("intForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("inMsg", "", "");
    T.call("interviewAdd", { candidateId: $("iCand").value, date: $("iDate").value, time: $("iTime").value, interviewer: $("iInterviewer").value })
      .then(function () { $("intForm").reset(); msg("inMsg", "ok", "Interview scheduled. The candidate moved to the Interview stage."); loadInterviews(); })
      .catch(function (err) { msg("inMsg", "err", T.errText(err)); });
  });
  $("inBody").addEventListener("click", function (e) {
    var b = e.target.closest("button[data-id]");
    if (!b) return;
    T.call("interviewResult", { id: b.getAttribute("data-id"), result: b.getAttribute("data-res") })
      .then(loadInterviews).catch(function (err) { alert(T.errText(err)); });
  });

  /* ----- Offer letters ----- */
  var lastOffers = [];
  function loadOffers() {
    candidateOptions("oCand");
    T.call("offers").then(function (rows) {
      lastOffers = rows;
      fill("ofBody", rows.map(function (o) {
        return "<tr><td>" + T.esc(o.candidateName) + "</td><td>" + T.esc(o.jobTitle) + "</td><td class=\"num\">" + T.money(o.salary) + "</td><td>" + o.joiningDate + "</td><td>" + o.issueDate + "</td><td>" + tag(o.status) + "</td><td><button class=\"btn sm\" type=\"button\" data-view=\"" + o.id + "\">View letter</button></td></tr>";
      }).join(""), 7, "No offers yet.");
    }).catch(function (e) { fail("ofBody", 7, e); });
  }
  $("offerForm").addEventListener("submit", function (e) {
    e.preventDefault(); msg("ofMsg", "", "");
    T.call("offerAdd", { candidateId: $("oCand").value, salary: $("oSalary").value, joiningDate: $("oJoining").value })
      .then(function () { $("offerForm").reset(); msg("ofMsg", "ok", "Offer created. The candidate moved to the Offered stage."); loadOffers(); })
      .catch(function (err) { msg("ofMsg", "err", T.errText(err)); });
  });
  $("ofBody").addEventListener("click", function (e) {
    var b = e.target.closest("button[data-view]");
    if (!b) return;
    var o = null;
    lastOffers.forEach(function (x) { if (String(x.id) === b.getAttribute("data-view")) o = x; });
    if (!o) return;
    $("ofLetter").innerHTML =
      "<div class=\"card narrow\" style=\"margin-top:16px\"><div class=\"card-pad\">" +
      "<div class=\"small muted\">TAA Software · Offer of employment</div>" +
      "<p style=\"margin:14px 0 4px\">Date: " + o.issueDate + "</p>" +
      "<p style=\"margin:0 0 14px\">To<br><b>" + T.esc(o.candidateName) + "</b><br>" + T.esc(o.candidateEmail) + "</p>" +
      "<p>Dear " + T.esc(o.candidateName) + ",</p>" +
      "<p>We are pleased to offer you the position of <b>" + T.esc(o.jobTitle) + "</b> in our <b>" + T.esc(o.department) + "</b> department. " +
      "Your monthly salary will be <b>" + T.money(o.salary) + "</b>. Your joining date is <b>" + o.joiningDate + "</b>.</p>" +
      "<p>Please confirm your acceptance. We look forward to welcoming you to the team.</p>" +
      "<p style=\"margin-top:20px\">HR Department<br>TAA Software</p>" +
      "</div></div>";
    $("ofLetter").scrollIntoView({ behavior: "smooth", block: "start" });
  });

  T.loaders.jobs = loadJobs;
  T.loaders.candidates = loadCandidates;
  T.loaders.interviews = loadInterviews;
  T.loaders.offers = loadOffers;
})();
