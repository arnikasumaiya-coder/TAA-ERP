(function () {
  var DEMO = { email: "demo@taa.com", pass: "demo123" };
  var views = ["login", "register", "dashboard"];

  function $(id) { return document.getElementById(id); }

  function show(id) {
    views.forEach(function (v) { $(v).classList.toggle("active", v === id); });
    window.scrollTo(0, 0);
  }

  function msg(id, type, text) {
    var el = $(id);
    el.className = "msg " + (text ? "show " + type : "");
    el.textContent = text || "";
  }

  /* ---------- Login / Register ---------- */
  document.querySelectorAll("[data-go]").forEach(function (b) {
    b.addEventListener("click", function () {
      msg("loginMsg", "", ""); msg("regMsg", "", "");
      show(b.getAttribute("data-go"));
    });
  });

  $("fillDemo").addEventListener("click", function () {
    $("lEmail").value = DEMO.email;
    $("lPass").value = DEMO.pass;
    msg("loginMsg", "", "");
  });

  $("loginForm").addEventListener("submit", function (e) {
    e.preventDefault();
    var email = $("lEmail").value.trim().toLowerCase();
    var pass = $("lPass").value;
    if (!email || !pass) { msg("loginMsg", "err", "Enter your email and password."); return; }
    if (email === DEMO.email && pass === DEMO.pass) {
      msg("loginMsg", "", "");
      $("loginForm").reset();
      show("dashboard");
    } else {
      msg("loginMsg", "err", "Email or password is incorrect. Use the demo account below.");
    }
  });

  $("regForm").addEventListener("submit", function (e) {
    e.preventDefault();
    var f = ["rName", "rCompany", "rEmail", "rPass", "rPass2"].map(function (i) { return $(i).value.trim(); });
    if (f.some(function (v) { return !v; })) { msg("regMsg", "err", "Fill in all fields."); return; }
    if (f[3].length < 6) { msg("regMsg", "err", "Password must be at least 6 characters."); return; }
    if (f[3] !== f[4]) { msg("regMsg", "err", "Passwords do not match."); return; }
    $("regForm").reset();
    msg("regMsg", "", "");
    show("login");
    msg("loginMsg", "ok", "Account request received. This preview does not save data, so sign in with the demo account.");
  });

  /* ---------- Sidebar dropdowns (one open at a time) ---------- */
  document.querySelectorAll(".nav-parent").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var open = btn.getAttribute("aria-expanded") === "true";
      document.querySelectorAll(".nav-parent").forEach(function (other) {
        other.setAttribute("aria-expanded", "false");
        $(other.getAttribute("aria-controls")).hidden = true;
      });
      if (!open) {
        btn.setAttribute("aria-expanded", "true");
        $(btn.getAttribute("aria-controls")).hidden = false;
      }
    });
  });

  /* ---------- Mobile menu ---------- */
  function setMenu(open) {
    $("sidebar").classList.toggle("open", open);
    $("overlay").classList.toggle("show", open);
  }
  $("menuBtn").addEventListener("click", function () {
    setMenu(!$("sidebar").classList.contains("open"));
  });
  $("overlay").addEventListener("click", function () { setMenu(false); });

  /* ---------- Sign out ---------- */
  $("logoutBtn").addEventListener("click", function () {
    setMenu(false);
    document.querySelectorAll(".nav-parent").forEach(function (btn) {
      btn.setAttribute("aria-expanded", "false");
      $(btn.getAttribute("aria-controls")).hidden = true;
    });
    msg("loginMsg", "", "");
    show("login");
  });
})();
