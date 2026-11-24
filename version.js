/* advc site: fills version-dependent content from version.json.
 *
 * Markup:  data-bind="text={version}; href={repo}/issues; data-copy={install}"
 * Each entry is `target=template`; `text` sets textContent, anything else is
 * an attribute. `{a.b}` is looked up in version.json. Nothing else on the site
 * hardcodes the version, so a release only edits version.json. */
(function () {
  "use strict";
  function get(o, p) {
    return p.split(".").reduce(function (a, k) { return a == null ? a : a[k]; }, o);
  }
  function fill(tpl, data) {
    return tpl.replace(/\{([\w.]+)\}/g, function (_, p) {
      var v = get(data, p);
      return v == null ? "" : v;
    });
  }
  function apply(data) {
    window.ADVC_VERSION = data;
    Array.prototype.forEach.call(document.querySelectorAll("[data-bind]"), function (el) {
      el.getAttribute("data-bind").split(";").forEach(function (entry) {
        var i = entry.indexOf("=");
        if (i < 0) return;
        var target = entry.slice(0, i).trim(), val = fill(entry.slice(i + 1).trim(), data);
        if (target === "text") el.textContent = val; else el.setAttribute(target, val);
      });
    });
    document.documentElement.classList.add("v-ready");
    document.dispatchEvent(new CustomEvent("advc:version", { detail: data }));
  }
  fetch("version.json", { cache: "no-store" })
    .then(function (r) { if (!r.ok) throw new Error("http " + r.status); return r.json(); })
    .then(apply)
    .catch(function (e) { console.warn("version.json not loaded:", e); });
})();
