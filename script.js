(function () {
  var ADMIN = { email: "admin@taa.com", pass: "admin123" };
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

  /* ---------- Login / Register (Step 8: real accounts, checked by the PHP backend) ---------- */
  window.TAA_ENTER = function () { show("dashboard"); };
  window.TAA_EXIT = function () { show("login"); };

  document.querySelectorAll("[data-go]").forEach(function (b) {
    b.addEventListener("click", function () {
      msg("loginMsg", "", ""); msg("regMsg", "", "");
      show(b.getAttribute("data-go"));
    });
  });

  $("fillDemo").addEventListener("click", function () {
    $("lEmail").value = ADMIN.email;
    $("lPass").value = ADMIN.pass;
    msg("loginMsg", "", "");
  });

  $("loginForm").addEventListener("submit", function (e) {
    e.preventDefault();
    var email = $("lEmail").value.trim().toLowerCase();
    var pass = $("lPass").value;
    if (!email || !pass) { msg("loginMsg", "err", "Enter your email and password."); return; }
    fetch("php/api.php?action=login", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: email, password: pass })
    }).then(function (r) { return r.json(); }).then(function (j) {
      if (!j.ok) { msg("loginMsg", "err", j.error || "Sign-in failed."); return; }
      try { sessionStorage.setItem("taa_user", JSON.stringify(j.data)); } catch (err) {}
      msg("loginMsg", "", "");
      $("loginForm").reset();
      show("dashboard");
      if (window.TAA && window.TAA.onLogin) window.TAA.onLogin(j.data);
    }).catch(function () {
      msg("loginMsg", "err", "Cannot reach the PHP server. Start it with: php -S localhost:8000");
    });
  });

  $("regForm").addEventListener("submit", function (e) {
    e.preventDefault();
    msg("regMsg", "err", "Self-registration is off. Accounts are created by the Super Admin — please sign in with the account provided to you.");
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
    try { sessionStorage.removeItem("taa_user"); } catch (e) {}
    fetch("php/api.php?action=logout", { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" }).catch(function () {});
    show("login");
  });
})();
