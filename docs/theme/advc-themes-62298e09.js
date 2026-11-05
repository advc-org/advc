/*!
 * advc-themes.js — shared runtime theming for the advc web surfaces.
 *
 * One file, three surfaces: the landing page, the advland.store, and the
 * mdBook docs. Each named theme is a palette of semantic roles; per-surface
 * adapters map those roles onto the CSS variable names that surface actually
 * uses (landing's --ink-dim, the store's --dim, mdBook's --fg, …). The engine
 * writes every variable as an inline style on <html>, which beats mdBook's
 * .navy/.coal/.ayu class rules, so a single switch drives all three surfaces.
 *
 * The canonical --advc-* namespace is always emitted alongside the
 * surface-specific names, so the floating switcher widget (and any future
 * shared UI) can style itself identically everywhere.
 *
 * Canonical source: web/landing-page/advc-themes.js
 * Synced into docs/theme/ and web/advland/static/ via `just themes`.
 */
(function () {
  "use strict";

  var STORAGE_KEY = "advc-theme";

  /* ---- Named palettes (semantic roles) ----
   * a1..a6 are the six accent slots, in canonical order:
   *   a1 magenta  a2 violet  a3 cyan  a4 lime  a5 amber  a6 coral
   * Gradients and ambient glows are derived from these, so a palette only
   * has to name its accents + the core surfaces to recolor the whole site.
   */
  var THEMES = {
    aurora: {
      name: "Aurora", mode: "dark",
      bg: "#0b0613", bg2: "#140a26",
      ink: "#f5efff", inkDim: "#b8a8d6", inkFade: "#7d6ba0",
      card: "rgba(255,255,255,.04)", border: "rgba(255,255,255,.10)",
      shadow: "rgba(0,0,0,.70)", radius: "18px",
      codeBg: "#06030c", onGrad: "#0b0613",
      a1: "#ec4899", a2: "#8b5cf6", a3: "#22d3ee", a4: "#a3e635", a5: "#fbbf24", a6: "#fb7185",
    },
    carbon: {
      name: "Carbon", mode: "dark",
      bg: "#0a0b0e", bg2: "#13161b",
      ink: "#e7ecf3", inkDim: "#9aa7b5", inkFade: "#5f6b78",
      card: "rgba(255,255,255,.035)", border: "rgba(255,255,255,.09)",
      shadow: "rgba(0,0,0,.65)", radius: "14px",
      codeBg: "#05070a", onGrad: "#0a0b0e",
      a1: "#22d3ee", a2: "#7c8a9a", a3: "#5eead4", a4: "#86efac", a5: "#facc15", a6: "#94a3b8",
    },
    sunset: {
      name: "Sunset", mode: "dark",
      bg: "#160a0a", bg2: "#23110f",
      ink: "#ffece6", inkDim: "#d8a89c", inkFade: "#9c6f63",
      card: "rgba(255,255,255,.04)", border: "rgba(255,255,255,.10)",
      shadow: "rgba(0,0,0,.65)", radius: "18px",
      codeBg: "#1a0807", onGrad: "#160a0a",
      a1: "#fb7185", a2: "#f97316", a3: "#fbbf24", a4: "#facc15", a5: "#f59e0b", a6: "#ec4899",
    },
    paper: {
      name: "Paper", mode: "light",
      bg: "#f6f1ea", bg2: "#ffffff",
      ink: "#241c14", inkDim: "#6b5d4f", inkFade: "#9a8b7b",
      card: "rgba(0,0,0,.03)", border: "rgba(0,0,0,.10)",
      shadow: "rgba(60,40,20,.15)", radius: "16px",
      codeBg: "#1c140d", onGrad: "#241c14",
      a1: "#c026b3", a2: "#7c3aed", a3: "#0891b2", a4: "#65a30d", a5: "#d97706", a6: "#e11d48",
    },
    mint: {
      name: "Mint", mode: "light",
      bg: "#eef7f4", bg2: "#ffffff",
      ink: "#0f2a26", inkDim: "#3f5f59", inkFade: "#6b8a82",
      card: "rgba(0,0,0,.03)", border: "rgba(0,0,0,.10)",
      shadow: "rgba(20,60,50,.15)", radius: "16px",
      codeBg: "#06171a", onGrad: "#0f2a26",
      a1: "#0d9488", a2: "#10b981", a3: "#22d3ee", a4: "#84cc16", a5: "#f59e0b", a6: "#e11d48",
    },
  };

  function hexToRgb(h) {
    h = String(h).replace("#", "");
    if (h.length === 3) h = h.split("").map(function (c) { return c + c; }).join("");
    var n = parseInt(h, 16);
    return ((n >> 16) & 255) + ", " + ((n >> 8) & 255) + ", " + (n & 255);
  }

  function grads(t) {
    return {
      hot: "linear-gradient(135deg, " + t.a6 + " 0%, " + t.a1 + " 35%, " + t.a2 + " 75%, " + t.a3 + " 100%)",
      cool: "linear-gradient(135deg, " + t.a3 + " 0%, " + t.a2 + " 50%, " + t.a1 + " 100%)",
      warm: "linear-gradient(135deg, " + t.a5 + " 0%, " + t.a6 + " 50%, " + t.a1 + " 100%)",
    };
  }

  // Resolve a theme into the full value table every adapter can read from.
  function values(t) {
    var r = {
      a1: hexToRgb(t.a1), a2: hexToRgb(t.a2), a3: hexToRgb(t.a3),
      a4: hexToRgb(t.a4), a5: hexToRgb(t.a5), a6: hexToRgb(t.a6),
      bg: hexToRgb(t.bg), code: hexToRgb(t.codeBg),
    };
    var g = grads(t);
    return {
      bg: t.bg, bg2: t.bg2, ink: t.ink, inkDim: t.inkDim, inkFade: t.inkFade,
      card: t.card, border: t.border, shadow: t.shadow, radius: t.radius,
      codeBg: t.codeBg, onGrad: t.onGrad,
      navBg: "rgba(" + r.bg + ", .55)",
      a1: t.a1, a2: t.a2, a3: t.a3, a4: t.a4, a5: t.a5, a6: t.a6,
      a1rgb: r.a1, a2rgb: r.a2, a3rgb: r.a3, a4rgb: r.a4, a5rgb: r.a5, a6rgb: r.a6,
      gradHot: g.hot, gradCool: g.cool, gradWarm: g.warm,
      // mdBook composite tokens (accent + alpha).
      icBg: "rgba(" + r.a2 + ", .18)",
      themeHover: "rgba(" + r.a2 + ", .25)",
      quoteBg: "rgba(" + r.a2 + ", .08)",
      tableAlt: "rgba(" + r.a2 + ", .05)",
      searchShadow: "rgba(" + r.a1 + ", .35)",
      searchLi: "rgba(" + r.a2 + ", .06)",
      searchmark: "rgba(" + r.a3 + ", .30)",
      searchBorder: "rgba(" + r.a2 + ", .25)",
    };
  }

  /* The canonical --advc-* namespace — always emitted, used by the switcher
   * and any shared UI. Identical on every surface. */
  var BASE_MAP = {
    "--advc-bg": "bg", "--advc-bg2": "bg2",
    "--advc-ink": "ink", "--advc-ink-dim": "inkDim", "--advc-ink-fade": "inkFade",
    "--advc-card": "card", "--advc-border": "border", "--advc-shadow": "shadow",
    "--advc-radius": "radius", "--advc-code-bg": "codeBg", "--advc-on-grad": "onGrad",
    "--advc-nav-bg": "navBg",
    "--advc-accent1": "a1", "--advc-accent2": "a2", "--advc-accent3": "a3",
    "--advc-accent4": "a4", "--advc-accent5": "a5", "--advc-accent6": "a6",
    "--advc-accent1-rgb": "a1rgb", "--advc-accent2-rgb": "a2rgb", "--advc-accent3-rgb": "a3rgb",
    "--advc-accent4-rgb": "a4rgb", "--advc-accent5-rgb": "a5rgb", "--advc-accent6-rgb": "a6rgb",
    "--advc-grad-hot": "gradHot", "--advc-grad-cool": "gradCool", "--advc-grad-warm": "gradWarm",
  };

  /* Per-surface maps: surface CSS variable -> canonical role (key into values()). */
  var ADAPTERS = {
    landing: {
      "--bg": "bg", "--bg-2": "bg2", "--ink": "ink", "--ink-dim": "inkDim", "--ink-fade": "inkFade",
      "--violet": "a2", "--magenta": "a1", "--cyan": "a3", "--lime": "a4", "--amber": "a5", "--orange": "a6",
      "--card": "card", "--card-brd": "border", "--shadow": "shadow", "--radius": "radius",
      "--on-grad": "onGrad", "--code-bg": "codeBg", "--nav-bg": "navBg",
      "--magenta-rgb": "a1rgb", "--cyan-rgb": "a3rgb", "--violet-rgb": "a2rgb",
    },
    store: {
      "--bg": "bg", "--bg-2": "bg2", "--card": "card", "--brd": "border",
      "--ink": "ink", "--dim": "inkDim", "--fade": "inkFade",
      "--magenta": "a1", "--violet": "a2", "--cyan": "a3", "--lime": "a4",
      "--grad-hot": "gradHot", "--radius": "radius", "--on-grad": "onGrad", "--nav-bg": "navBg",
      "--magenta-rgb": "a1rgb", "--cyan-rgb": "a3rgb", "--violet-rgb": "a2rgb", "--lime-rgb": "a4rgb",
      "--amber": "a5", "--coral": "a6", "--amber-rgb": "a5rgb", "--coral-rgb": "a6rgb",
    },
    docs: {
      "--bg": "bg", "--fg": "ink", "--fg-heading": "ink", "--non-existant-color": "inkFade",
      "--sidebar-bg": "bg2", "--sidebar-fg": "inkDim", "--sidebar-non-existant": "inkFade",
      "--sidebar-active": "a1", "--sidebar-spacer": "bg2",
      "--scrollbar": "a2", "--scrollbar-hover": "a1",
      "--icons": "inkFade", "--icons-hover": "ink",
      "--links": "a3", "--links-hover": "a1",
      "--inline-code-color": "ink", "--inline-code-bg": "icBg",
      "--theme-popup-bg": "bg2", "--theme-popup-fg": "ink", "--theme-hover": "themeHover",
      "--quote-bg": "quoteBg", "--quote-border": "a2",
      "--table-border-color": "border", "--table-header-bg": "bg2", "--table-alternate-row-bg": "tableAlt",
      "--searchbar-border-color": "border", "--searchbar-bg": "bg2", "--searchbar-fg": "ink",
      "--searchbar-shadow-color": "searchShadow",
      "--searchresults-header-fg": "inkDim", "--searchresults-border-color": "searchBorder",
      "--searchresults-li-bg": "searchLi", "--searchmark-bg": "searchmark",
      "--warning-border": "a5",
    },
  };

  function detectSurface() {
    var meta = document.querySelector('meta[name="advc-surface"]');
    if (meta && meta.content) return meta.content;
    if (document.getElementById("mdbook-theme-toggle")) return "docs";
    if (document.querySelector('link[href$="/static/style.css"], link[href*="style.css"][href*="static"]')) return "store";
    return "landing";
  }

  function resolve(map, v) {
    var out = {};
    for (var k in map) if (Object.prototype.hasOwnProperty.call(map, k)) out[k] = v[map[k]];
    return out;
  }

  var surface = "landing";
  var current = "aurora";

  function apply(name) {
    var t = THEMES[name] || THEMES.aurora;
    current = name in THEMES ? name : "aurora";
    var v = values(t);
    var root = document.documentElement;
    var merged = resolve(BASE_MAP, v);
    var extra = ADAPTERS[surface] ? resolve(ADAPTERS[surface], v) : {};
    for (var k in merged) root.style.setProperty(k, merged[k]);
    for (var kk in extra) root.style.setProperty(kk, extra[kk]);
    root.setAttribute("data-theme", current);
    root.setAttribute("data-advc-mode", t.mode);
    try { localStorage.setItem(STORAGE_KEY, current); } catch (e) {}
    syncSwitcherActive();
  }

  /* ---- Floating switcher widget (lives on every surface) ---- */
  var SWITCHER_CSS = [
    "#advc-theme-switcher{position:fixed;right:18px;bottom:18px;z-index:99999;",
    "font-family:inherit;--ats-pop-bg:var(--advc-bg2);}",
    "#advc-theme-switcher .ats-btn{width:44px;height:44px;border-radius:50%;",
    "border:1px solid var(--advc-border);background:var(--advc-bg2);color:var(--advc-ink);",
    "box-shadow:0 10px 28px -10px var(--advc-shadow);cursor:pointer;",
    "display:grid;place-items:center;padding:0;transition:transform .15s,box-shadow .15s;}",
    "#advc-theme-switcher .ats-btn:hover{transform:translateY(-2px);",
    "box-shadow:0 14px 32px -10px var(--advc-shadow);}",
    "#advc-theme-switcher .ats-ic{width:20px;height:20px;border-radius:50%;",
    "background:conic-gradient(var(--advc-accent1),var(--advc-accent2),var(--advc-accent3),",
    "var(--advc-accent4),var(--advc-accent5),var(--advc-accent6),var(--advc-accent1));",
    "box-shadow:inset 0 0 0 3px var(--advc-bg2);}",
    "#advc-theme-switcher .ats-pop{position:absolute;right:0;bottom:54px;min-width:190px;",
    "background:var(--ats-pop-bg);border:1px solid var(--advc-border);border-radius:14px;",
    "padding:6px;box-shadow:0 18px 44px -12px var(--advc-shadow);",
    "display:flex;flex-direction:column;gap:2px;",
    "opacity:0;transform:translateY(6px) scale(.98);pointer-events:none;",
    "transition:opacity .15s,transform .15s;}",
    "#advc-theme-switcher[data-open] .ats-pop{opacity:1;transform:none;pointer-events:auto;}",
    "#advc-theme-switcher .ats-item{display:flex;align-items:center;gap:10px;width:100%;",
    "border:none;background:transparent;color:var(--advc-ink);padding:9px 10px;border-radius:9px;",
    "cursor:pointer;font:inherit;text-align:left;transition:background .12s;}",
    "#advc-theme-switcher .ats-item:hover{background:rgba(var(--advc-accent2-rgb),.18);}",
    "#advc-theme-switcher .ats-item[aria-current=\"true\"]{background:rgba(var(--advc-accent1-rgb),.16);}",
    "#advc-theme-switcher .ats-sw{width:22px;height:22px;border-radius:6px;flex:0 0 auto;",
    "border:1px solid var(--advc-border);}",
    "#advc-theme-switcher .ats-name{font-size:14px;font-weight:600;}",
    "#advc-theme-switcher .ats-dot{margin-left:auto;width:8px;height:8px;border-radius:50%;",
    "border:1px solid var(--advc-border);}",
    "#advc-theme-switcher .ats-dot.dark{background:#0b0613;}",
    "#advc-theme-switcher .ats-dot.light{background:#f6f1ea;}",
  ].join("");

  function buildSwitcher() {
    if (document.getElementById("advc-theme-switcher")) return;
    var style = document.createElement("style");
    style.id = "advc-theme-switcher-css";
    style.textContent = SWITCHER_CSS;
    document.head.appendChild(style);

    var host = document.createElement("div");
    host.id = "advc-theme-switcher";
    var items = Object.keys(THEMES).map(function (key) {
      var t = THEMES[key];
      return '<button class="ats-item" data-theme="' + key + '" role="menuitem">' +
        '<span class="ats-sw" style="background:' + grads(t).hot + '"></span>' +
        '<span class="ats-name">' + t.name + "</span>" +
        '<span class="ats-dot ' + t.mode + '"></span></button>';
    }).join("");
    host.innerHTML =
      '<button class="ats-btn" aria-label="Change theme" aria-haspopup="menu" aria-expanded="false"></button>' +
      '<div class="ats-pop" role="menu">' + items + "</div>";
    var btn = host.querySelector(".ats-btn");
    btn.innerHTML = '<span class="ats-ic"></span>';
    document.body.appendChild(host);

    function setOpen(open) {
      host.toggleAttribute("data-open", open);
      btn.setAttribute("aria-expanded", open ? "true" : "false");
    }
    btn.addEventListener("click", function (e) {
      e.stopPropagation();
      setOpen(!host.hasAttribute("data-open"));
    });
    host.addEventListener("click", function (e) {
      var item = e.target.closest(".ats-item");
      if (!item) return;
      apply(item.getAttribute("data-theme"));
      setOpen(false);
    });
    document.addEventListener("click", function (e) {
      if (!host.contains(e.target)) setOpen(false);
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") setOpen(false);
    });
  }

  function syncSwitcherActive() {
    var host = document.getElementById("advc-theme-switcher");
    if (!host) return;
    host.querySelectorAll(".ats-item").forEach(function (item) {
      item.setAttribute("aria-current", item.getAttribute("data-theme") === current ? "true" : "false");
    });
  }

  function init() {
    surface = detectSurface();
    var saved = null;
    try { saved = localStorage.getItem(STORAGE_KEY); } catch (e) {}
    apply(saved && THEMES[saved] ? saved : "aurora");
    if (document.body) buildSwitcher();
    else document.addEventListener("DOMContentLoaded", buildSwitcher);
  }

  // Public API (handy for debugging or wiring custom controls later).
  window.advcTheme = {
    apply: apply,
    list: function () { return Object.keys(THEMES); },
    current: function () { return current; },
    surface: function () { return surface; },
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();