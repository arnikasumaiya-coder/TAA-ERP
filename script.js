(function () {
  var DEMO = { email: "demo@taa.com", pass: "demo123" };
  var views = ["login", "register", "dashboard"];

  function $(id) { return document.getElementById(id); }

  function show(id) {
    views.forEach(function (v) { $(v).classList.toggle("active", v === id); });
    window.scrollTo(0, 0);
  }

  // Shows or clears a message box. type: "err" or "ok"
  function msg(id, type, text) {
    var el = $(id);
    el.className = "notice form-msg " + (text ? (type === "ok" ? "ok" : "bad") : "bad hide");
    el.textContent = text || "";
  }

  /* ---------- Theme (light / dark) and full screen ---------- */
  var ICON_SUN = '<svg class="ic" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"/></svg>';
  var ICON_MOON = '<svg class="ic" viewBox="0 0 24 24" aria-hidden="true"><path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8z"/></svg>';

  function currentTheme() { return document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light"; }
  function paintThemeBtn() { $("themeBtn").innerHTML = currentTheme() === "dark" ? ICON_SUN : ICON_MOON; }
  function setTheme(t) {
    document.documentElement.setAttribute("data-theme", t);
    try { localStorage.setItem("taa_theme", t); } catch (e) {}
    paintThemeBtn();
  }
  paintThemeBtn();
  $("themeBtn").addEventListener("click", function () { setTheme(currentTheme() === "dark" ? "light" : "dark"); });
  $("fullBtn").addEventListener("click", function () {
    if (!document.fullscreenElement) { if (document.documentElement.requestFullscreen) document.documentElement.requestFullscreen(); }
    else if (document.exitFullscreen) document.exitFullscreen();
  });

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
  function closeGroups() {
    document.querySelectorAll(".nav-group").forEach(function (g) {
      g.classList.remove("open");
      g.querySelector(".nav-head").setAttribute("aria-expanded", "false");
    });
  }
  document.querySelectorAll(".nav-head").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var group = btn.parentElement;
      var wasOpen = group.classList.contains("open");
      closeGroups();
      if (!wasOpen) { group.classList.add("open"); btn.setAttribute("aria-expanded", "true"); }
    });
  });

  /* ---------- Sidebar menu search ---------- */
  $("menuSearch").addEventListener("input", function () {
    var t = this.value.trim().toLowerCase();
    document.querySelectorAll("#sidebar .nav-item").forEach(function (a) {
      a.classList.toggle("hide", !!t && a.getAttribute("data-label").indexOf(t) === -1);
    });
    document.querySelectorAll("#sidebar .nav-group").forEach(function (g) {
      var any = g.querySelector(".nav-item:not(.hide)");
      g.classList.toggle("hide", !!t && !any);
      if (t && any) g.classList.add("open");
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

  /* ---------- User menu and sign out ---------- */
  $("userChip").addEventListener("click", function () { $("userPop").classList.toggle("hide"); });
  document.addEventListener("click", function (ev) {
    if (!$("userChip").contains(ev.target) && !$("userPop").contains(ev.target)) $("userPop").classList.add("hide");
  });
  $("logoutBtn").addEventListener("click", function () {
    $("userPop").classList.add("hide");
    setMenu(false);
    closeGroups();
    msg("loginMsg", "", "");
    show("login");
  });
})();
