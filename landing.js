/* advc landing page: highlighting, the code ⇄ game tabs and small effects. */
(function () {
  "use strict";
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------- ADVL / .play highlighting ---------- */
  var DECL = /^(func|anim|ui|voice|str|var|verb|inventory|collection|actor|import|default)$/;
  var KW = /^(end|if|switch|when|source|duration|before|wait|call|start|select|sequence|all|random|play|sound|image|noimage|text|stopall|nothing|talk|say|walkto|walkat|pose|inside|scale|tint|en|mouse_enter|mouse_leave|mouse_click|_)$/;
  var PLAY = /^(names|wait|click|rclick|echo|exit|screenshot|start-video|stop-video|play|esc|save|load|camera)$/;

  function esc(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }

  function words(text, first, lang) {
    // Tokens: strings, paths, attrs, numbers/durations, $vars, identifiers.
    var out = "", re = /("(?:[^"\\]|\\.)*")|(\$[\w]+)|([A-Za-z_][\w-]*(?:::[\w]+)+)|([a-z_]+)(=)|(\d+(?:\.\d+)?(?:ms|s|min)?\b)|([A-Za-z_][\w-]*)|(\s+)|(.)/g, m, i = 0;
    var prevDecl = false;
    while ((m = re.exec(text))) {
      var t = m[0];
      if (m[1]) out += '<span class="s">' + esc(t) + "</span>";
      else if (m[2]) out += '<span class="v">' + esc(t) + "</span>";
      else if (m[3]) out += '<span class="p">' + esc(t) + "</span>";
      else if (m[4]) out += '<span class="a">' + esc(m[4]) + "</span>" + esc(m[5]);
      else if (m[6]) out += '<span class="n">' + esc(t) + "</span>";
      else if (m[7]) {
        if (i === 0 && first && lang === "advl" && DECL.test(t)) { out += '<span class="d">' + t + "</span>"; prevDecl = true; i++; continue; }
        if (i === 0 && first && (lang === "advl" ? KW.test(t) : PLAY.test(t))) out += '<span class="k">' + t + "</span>";
        else if (prevDecl) out += '<span class="f">' + t + "</span>";
        else if (i === 0 && first) out += '<span class="k">' + t + "</span>";
        else if (lang === "advl" && /^(call|start)$/.test(text.trim().split(/\s+/)[0]) && i === 1) out += '<span class="f">' + t + "</span>";
        else if (lang === "play" && /^(ui|var|actor|idle|timeout)$/.test(t)) out += '<span class="k">' + t + "</span>";
        else out += esc(t);
        prevDecl = false; i++;
      } else { out += esc(t); if (!m[8]) i++; }
    }
    return out;
  }

  function highlight(pre) {
    var lang = pre.getAttribute("data-lang") || "advl";
    var lines = pre.textContent.replace(/\n$/, "").split("\n");
    pre.innerHTML = lines.map(function (line) {
      var indent = line.match(/^\s*/)[0], body = line.slice(indent.length), html;
      var cm = lang === "advl" ? body.indexOf("//") : (body.charAt(0) === "#" ? 0 : body.indexOf("  #"));
      var code = cm >= 0 ? body.slice(0, cm) : body;
      var comment = cm >= 0 ? body.slice(cm) : "";
      html = esc(indent) + words(code, true, lang) + (comment ? '<span class="c">' + esc(comment) + "</span>" : "");
      return '<span class="ln">' + (html || " ") + "</span>";
    }).join("");
  }
  $$("pre.code").forEach(highlight);

  /* ---------- code ⇄ game tabs ---------- */
  var STATUS = {
    lair: ["$ advc --release", "✓", "target/release/king-relic · 4.7 MB executable · 47 MB .pak", "king-relic"],
    combat: ["$ advc --release", "✓", "13 files · 127 coroutines · 27 animations · linked with LLVM O3", "king-relic"],
    room: ["$ advc --release", "✓", "target/release/crime-scene · lip-sync built for 69 voice lines", "crime-scene"],
    play: ["$ ADVC_HEADLESS=1 ADVC_STDIN=1 ./target/release/king-relic < walkthrough.play", "✓", "96 steps · exit 0 · 0.08 s", "king-relic"],
  };
  $$("[data-ide]").forEach(function (ide) {
    var tabs = $$("[data-tab]", ide), timer = null, user = false, idx = 0, DUR = 6500;
    var cmd = ide.querySelector("[data-status-cmd]"), out = ide.querySelector("[data-status-out]"), title = ide.querySelector("[data-game-title]");
    function show(i) {
      idx = (i + tabs.length) % tabs.length;
      var key = tabs[idx].getAttribute("data-tab");
      tabs.forEach(function (t, k) { t.setAttribute("aria-selected", String(k === idx)); });
      $$("[data-pane]", ide).forEach(function (p) { p.classList.toggle("is-on", p.getAttribute("data-pane") === key); });
      $$("[data-shot]", ide).forEach(function (p) { p.classList.toggle("is-on", p.getAttribute("data-shot") === key); });
      var s = STATUS[key];
      cmd.textContent = s[0];
      out.innerHTML = "<b>" + s[1] + "</b> " + s[2];
      title.textContent = s[3];
      schedule();
    }
    function schedule() {
      clearTimeout(timer);
      if (user || reduce) return;
      timer = setTimeout(function () { if (inView) show(idx + 1); else schedule(); }, DUR);
    }
    var inView = true;
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (es) { inView = es[0].isIntersecting; }).observe(ide);
    }
    ide.addEventListener("click", function (e) {
      var t = e.target.closest("[data-tab]");
      if (!t) return;
      user = true;
      show(tabs.indexOf(t));
    });
    ide.addEventListener("keydown", function (e) {
      if (!e.target.closest("[data-tab]")) return;
      if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
        user = true;
        show(idx + (e.key === "ArrowRight" ? 1 : -1));
        tabs[idx].focus();
      }
    });
    schedule();
  });

  /* ---------- copy buttons ---------- */
  document.addEventListener("click", function (e) {
    var b = e.target.closest("[data-copy]");
    if (!b || !navigator.clipboard) return;
    navigator.clipboard.writeText(b.getAttribute("data-copy")).then(function () {
      var label = b.querySelector("span");
      b.classList.add("done");
      label.textContent = "Copied";
      setTimeout(function () { b.classList.remove("done"); label.textContent = "Copy"; }, 1600);
    });
  });

  /* ---------- scroll effects ---------- */
  if ("IntersectionObserver" in window && !reduce) {
    // Sections drift in once.
    var rev = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); rev.unobserve(e.target); } });
    }, { rootMargin: "0px 0px -8% 0px" });
    $$(".sec-head, .stage, .card, .split-copy, .split-media, .tool, .publish, .show-card, .faq, .stats-grid").forEach(function (el) {
      el.classList.add("reveal"); rev.observe(el);
    });

    // The pipeline lights up stage by stage.
    var pipe = document.querySelector(".pipeline");
    if (pipe) new IntersectionObserver(function (es, o) {
      if (!es[0].isIntersecting) return;
      o.disconnect();
      $$(".stage", pipe).forEach(function (s, i) { setTimeout(function () { s.classList.add("lit", "in"); }, 250 + i * 280); });
    }, { threshold: 0.4 }).observe(pipe);

    // The publish terminal prints line by line.
    $$("[data-typing]").forEach(function (term) {
      var spans = $$("pre > span", term);
      spans.forEach(function (s) { s.style.opacity = "0"; });
      new IntersectionObserver(function (es, o) {
        if (!es[0].isIntersecting) return;
        o.disconnect();
        spans.forEach(function (s, i) { setTimeout(function () { s.style.opacity = "1"; }, 200 + i * (i < 2 ? 380 : 260)); });
      }, { threshold: 0.5 }).observe(term);
    });

    // Videos play only while on screen.
    $$("video[data-autoplay]").forEach(function (v) {
      new IntersectionObserver(function (es) {
        if (es[0].isIntersecting) { v.preload = "auto"; v.play().catch(function () {}); } else v.pause();
      }, { threshold: 0.35 }).observe(v);
    });

    // Highlight the nav link of the section in view.
    var links = $$(".nav-links a[href^='#']");
    var secs = links.map(function (a) { return document.querySelector(a.getAttribute("href")); }).filter(Boolean);
    var navObs = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (e.isIntersecting) links.forEach(function (a) { a.classList.toggle("on", a.getAttribute("href") === "#" + e.target.id); });
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    secs.forEach(function (s) { navObs.observe(s); });
  } else {
    $$("video[data-autoplay]").forEach(function (v) { v.preload = "metadata"; v.controls = true; });
  }

  /* ---------- showcase video plays on hover ---------- */
  $$("video[data-hoverplay]").forEach(function (v) {
    var card = v.closest(".show-card") || v;
    card.addEventListener("mouseenter", function () { v.preload = "auto"; v.play().catch(function () {}); });
    card.addEventListener("mouseleave", function () { v.pause(); });
  });

  /* ---------- cards: a glow follows the pointer ---------- */
  document.addEventListener("pointermove", function (e) {
    var c = e.target.closest && e.target.closest(".card");
    if (!c) return;
    var r = c.getBoundingClientRect();
    c.style.setProperty("--mx", e.clientX - r.left + "px");
    c.style.setProperty("--my", e.clientY - r.top + "px");
  });
})();
