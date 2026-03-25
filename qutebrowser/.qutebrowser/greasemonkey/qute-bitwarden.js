// ==UserScript==
// @name         qute-bitwarden
// @namespace    qute-bitwarden
// @match        *://*/*
// @run-at       document-end
// @qute-js-world main
// ==/UserScript==

(() => {
  if (window.__quteBitwardenController) {
    return;
  }

  const EVENT_NAME = "__quteBitwardenPayload";
  const ROOT_ID = "__qute_bitwarden_root";
  const state = {
    payload: null,
    lastRequestId: 0,
    pendingReady: false,
    uiKind: null,
    anchor: null,
    panel: null,
    chooserItems: [],
    chooserContext: null,
    selectedIndex: 0,
  };

  function text(value) {
    return typeof value === "string" ? value.trim() : "";
  }

  function lower(value) {
    return text(value).toLowerCase();
  }

  function escapeHtml(value) {
    return text(value).replace(/[&<>"']/g, (character) => {
      return {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
      }[character];
    });
  }

  function hostFromUrl(value) {
    try {
      return new URL(value, location.href).hostname.toLowerCase();
    } catch {
      return location.hostname.toLowerCase();
    }
  }

  function rootDomain(host) {
    const parts = lower(host).split(".").filter(Boolean);
    return parts.length >= 2 ? parts.slice(-2).join(".") : parts.join(".");
  }

  function activeElementDeep() {
    let element = document.activeElement;
    while (element instanceof Element) {
      if (element.shadowRoot && element.shadowRoot.activeElement) {
        element = element.shadowRoot.activeElement;
        continue;
      }
      if (element instanceof HTMLIFrameElement) {
        try {
          if (element.contentDocument && element.contentDocument.activeElement) {
            element = element.contentDocument.activeElement;
            continue;
          }
        } catch {
          // Cross-origin frames are not accessible.
        }
      }
      break;
    }
    return element instanceof Element ? element : null;
  }

  function isEditable(element) {
    if (element instanceof HTMLTextAreaElement) {
      return !element.disabled && !element.readOnly;
    }
    if (!(element instanceof HTMLInputElement)) {
      return false;
    }
    if (element.disabled || element.readOnly) {
      return false;
    }
    const type = lower(element.type || "text");
    return ![
      "hidden",
      "button",
      "submit",
      "reset",
      "checkbox",
      "radio",
      "file",
      "image",
      "range",
      "color",
    ].includes(type);
  }

  function isVisible(element) {
    if (!(element instanceof Element)) {
      return false;
    }
    const style = window.getComputedStyle(element);
    if (style.display === "none" || style.visibility === "hidden") {
      return false;
    }
    const rect = element.getBoundingClientRect();
    return rect.width >= 4 && rect.height >= 4;
  }

  function descriptorText(element) {
    if (!(element instanceof HTMLElement)) {
      return "";
    }
    return lower(
      [
        element.id,
        element.getAttribute("name"),
        element.getAttribute("placeholder"),
        element.getAttribute("aria-label"),
        element.getAttribute("autocomplete"),
        element.getAttribute("data-testid"),
        ...(element.labels ? Array.from(element.labels).map((label) => label.textContent || "") : []),
      ]
        .filter(Boolean)
        .join(" "),
    );
  }

  function roleScores(element) {
    const scores = { username: 0, password: 0, otp: 0 };
    if (!(element instanceof HTMLElement)) {
      return scores;
    }

    const type = lower(element.getAttribute("type") || "text");
    const autocomplete = lower(element.getAttribute("autocomplete"));
    const descriptor = descriptorText(element);

    if (type === "password") {
      scores.password += 320;
    }
    if (type === "email") {
      scores.username += 220;
    }
    if (type === "tel" && /\b(phone|mobile)\b/.test(descriptor)) {
      scores.username += 140;
    }

    if (autocomplete.includes("current-password") || autocomplete.includes("new-password")) {
      scores.password += 260;
    }
    if (autocomplete.includes("username")) {
      scores.username += 240;
    }
    if (autocomplete.includes("email")) {
      scores.username += 220;
    }
    if (autocomplete.includes("one-time-code")) {
      scores.otp += 300;
    }

    if (/\b(password|passcode|passwd|secret)\b/.test(descriptor)) {
      scores.password += 180;
    }
    if (/\b(otp|one[- ]?time|verification|authenticator|security code|2fa|mfa|code)\b/.test(descriptor)) {
      scores.otp += 190;
    }
    if (/\b(email|e-mail|user|username|login|member|account|card|mileage|phone|mobile)\b/.test(descriptor)) {
      scores.username += 120;
    }
    if (/\b(search|coupon|promo|gift|zip|postal|first name|last name|address)\b/.test(descriptor)) {
      scores.username -= 160;
    }

    return scores;
  }

  function primaryRole(element) {
    const scores = roleScores(element);
    let bestRole = "other";
    let bestScore = 0;
    for (const role of ["password", "otp", "username"]) {
      if (scores[role] > bestScore) {
        bestRole = role;
        bestScore = scores[role];
      }
    }
    return { role: bestScore >= 60 ? bestRole : "other", scores };
  }

  function scopeRootFor(element) {
    if (!(element instanceof Element)) {
      return document;
    }
    const scoped = element.closest(
      [
        "form",
        "dialog",
        "[role='dialog']",
        "[aria-modal='true']",
        "[data-testid*='login' i]",
        "[data-testid*='sign' i]",
        "[class*='login' i]",
        "[class*='sign' i]",
        "[class*='auth' i]",
        "[class*='drawer' i]",
        "[class*='modal' i]",
      ].join(","),
    );
    if (scoped) {
      return scoped;
    }
    const root = element.getRootNode();
    if (root instanceof ShadowRoot || root instanceof Document) {
      return root;
    }
    return document;
  }

  function normalizeUsernameHint(value) {
    const normalized = text(value);
    if (!normalized || normalized.length < 3) {
      return "";
    }
    if (/[*!•]/.test(normalized)) {
      return "";
    }
    return normalized.toLowerCase();
  }

  function collectContext() {
    const active = activeElementDeep();
    if (!isEditable(active) || !isVisible(active)) {
      return null;
    }

    const activeInfo = primaryRole(active);
    if (activeInfo.role === "other") {
      return null;
    }

    const scopeRoot = scopeRootFor(active);
    const fields = Array.from(
      new Set(
        [
          active,
          ...(scopeRoot && typeof scopeRoot.querySelectorAll === "function"
            ? Array.from(scopeRoot.querySelectorAll("input, textarea"))
                .filter(isEditable)
                .filter(isVisible)
            : []),
        ].filter(Boolean),
      ),
    );
    const analysed = fields.map((element) => {
      const analysis = primaryRole(element);
      return { element, role: analysis.role, scores: analysis.scores };
    });
    const topField = (role) =>
      analysed
        .filter((entry) => entry.role === role)
        .sort((left, right) => right.scores[role] - left.scores[role])[0]?.element || null;
    const usernameField = topField("username");
    const passwordField = topField("password");
    const otpField = topField("otp");

    return {
      activeField: active,
      activeRole: activeInfo.role,
      usernameField,
      passwordField,
      otpField,
      typedUsername: normalizeUsernameHint(
        (usernameField instanceof HTMLInputElement || usernameField instanceof HTMLTextAreaElement
          ? usernameField.value
          : "") ||
          (active instanceof HTMLInputElement || active instanceof HTMLTextAreaElement ? active.value : ""),
      ),
    };
  }

  function normalizeUri(uri) {
    const raw = text(uri);
    if (!raw) {
      return "";
    }
    if (/^[a-z][a-z0-9+.-]*:\/\//i.test(raw)) {
      return raw;
    }
    return `${location.protocol}//${raw.replace(/^\/\//, "")}`;
  }

  function uriMatchScore(item, currentUrl) {
    const currentHost = hostFromUrl(currentUrl);
    const currentOrigin = (() => {
      try {
        return new URL(currentUrl, location.href).origin.toLowerCase();
      } catch {
        return location.origin.toLowerCase();
      }
    })();
    const currentHref = lower(currentUrl);
    let best = 0;

    for (const rawUri of Array.isArray(item.uris) ? item.uris : []) {
      const value = normalizeUri(rawUri);
      if (!value) {
        continue;
      }
      let score = 0;
      try {
        const parsed = new URL(value, currentUrl);
        const origin = parsed.origin.toLowerCase();
        const host = parsed.hostname.toLowerCase();
        const href = parsed.href.toLowerCase();
        if (currentHref.startsWith(href)) {
          score = 520;
        } else if (origin === currentOrigin) {
          score = 420;
        } else if (host === currentHost) {
          score = 360;
        } else if (currentHost.endsWith(`.${host}`) || host.endsWith(`.${currentHost}`)) {
          score = 260;
        } else if (rootDomain(host) && rootDomain(host) === rootDomain(currentHost)) {
          score = 170;
        }
      } catch {
        const host = lower(value);
        if (host === currentHost) {
          score = 360;
        } else if (currentHost.endsWith(`.${host}`) || host.endsWith(`.${currentHost}`)) {
          score = 260;
        } else if (rootDomain(host) && rootDomain(host) === rootDomain(currentHost)) {
          score = 170;
        }
      }
      best = Math.max(best, score);
    }

    return best;
  }

  function rankItems(items, context, payload) {
    const typedUsername = lower(context.typedUsername);

    return items
      .map((item, index) => {
        const username = lower(item.username);
        const siteScore = uriMatchScore(item, payload.currentUrl);
        const typedScore = typedUsername && username === typedUsername ? 1 : 0;
        return {
          item,
          siteScore,
          typedScore,
          sortScore: typedScore * 50000 + siteScore * 100 + (item.username ? 10 : 0) - index,
        };
      })
      .sort((left, right) => right.sortScore - left.sortScore);
  }

  function setFieldValue(element, value) {
    if (!(element instanceof HTMLInputElement || element instanceof HTMLTextAreaElement) || value == null) {
      return false;
    }

    const prototype = element instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    const descriptor = Object.getOwnPropertyDescriptor(prototype, "value");
    if (descriptor && typeof descriptor.set === "function") {
      descriptor.set.call(element, value);
    } else {
      element.value = value;
    }

    try {
      element.dispatchEvent(
        new InputEvent("input", {
          bubbles: true,
          composed: true,
          inputType: "insertText",
          data: value,
        }),
      );
    } catch {
      element.dispatchEvent(new Event("input", { bubbles: true, composed: true }));
    }
    element.dispatchEvent(new Event("change", { bubbles: true, composed: true }));
    return true;
  }

  function hideUi() {
    if (state.panel) {
      state.panel.remove();
    }
    state.uiKind = null;
    state.panel = null;
    state.anchor = null;
    state.chooserItems = [];
    state.chooserContext = null;
  }

  function ensureRoot() {
    let host = document.getElementById(ROOT_ID);
    if (!(host instanceof HTMLElement)) {
      host = document.createElement("div");
      host.id = ROOT_ID;
      host.style.position = "fixed";
      host.style.inset = "0";
      host.style.pointerEvents = "none";
      host.style.zIndex = "2147483647";
      document.documentElement.appendChild(host);
    }
    let shadow = host.shadowRoot;
    if (!shadow) {
      shadow = host.attachShadow({ mode: "open" });
      shadow.innerHTML = `<style>
        :host{all:initial}
        .panel{position:fixed;min-width:280px;max-width:min(360px,calc(100vw - 24px));max-height:min(320px,calc(100vh - 24px));overflow:auto;pointer-events:auto;border:1px solid rgba(255,255,255,.12);border-radius:12px;background:rgba(18,23,31,.98);color:#f7f8fa;box-shadow:0 20px 50px rgba(0,0,0,.35);font:13px/1.35 ui-sans-serif,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;backdrop-filter:blur(10px)}
        .status{padding:12px 14px}
        .status.loading{border-left:3px solid #7ac8ff}
        .status.info{border-left:3px solid #9fd17b}
        .status.error{border-left:3px solid #ff7b72}
        .chooser{padding:8px;outline:none}
        .chooserHeader{padding:6px 8px 10px;color:rgba(247,248,250,.7);font-size:12px}
        .chooserFooter{padding:8px 8px 4px;color:rgba(247,248,250,.5);font-size:11px}
        .choice{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:8px;border-radius:10px}
        .choice:hover,.choice[data-active="true"]{background:rgba(122,200,255,.12)}
        .choicePick{display:grid;grid-template-columns:24px minmax(0,1fr);gap:10px;width:100%;padding:10px 8px;border:0;background:transparent;color:inherit;text-align:left;cursor:pointer}
        .choiceIndex{display:inline-flex;align-items:center;justify-content:center;width:24px;height:24px;border-radius:999px;background:rgba(255,255,255,.08);color:rgba(247,248,250,.72);font-size:11px}
        .choiceTitle,.choiceSubtitle{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
        .choiceTitle{font-weight:600}
        .choiceSubtitle{color:rgba(247,248,250,.68);font-size:12px;margin-top:2px}
        .choiceHint{color:rgba(247,248,250,.52);font-size:11px;margin-top:3px}
        .choiceSecret{display:none;color:rgba(247,248,250,.9);font:12px/1.35 ui-monospace,SFMono-Regular,Menlo,monospace;margin-top:6px;word-break:break-all}
        .choice[data-revealed="true"] .choiceSecret{display:block}
        .choiceReveal{align-self:start;margin:8px 8px 0 0;padding:5px 9px;border:0;border-radius:999px;background:rgba(255,255,255,.08);color:rgba(247,248,250,.78);font:11px/1.2 ui-sans-serif,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;cursor:pointer}
        .choiceReveal:hover{background:rgba(255,255,255,.14)}
      </style>`;
    }
    return shadow;
  }

  function positionPanel(panel, anchor) {
    const margin = 12;
    let left = window.innerWidth - panel.offsetWidth - margin;
    let top = margin;

    if (anchor instanceof Element && isVisible(anchor)) {
      const rect = anchor.getBoundingClientRect();
      left = Math.min(
        Math.max(margin, rect.left),
        Math.max(margin, window.innerWidth - panel.offsetWidth - margin),
      );
      top = rect.bottom + 10;
      if (top + panel.offsetHeight > window.innerHeight - margin) {
        top = Math.max(margin, rect.top - panel.offsetHeight - 10);
      }
    }

    panel.style.left = `${Math.round(left)}px`;
    panel.style.top = `${Math.round(top)}px`;
  }

  function createPanel(className, anchor) {
    const shadow = ensureRoot();
    hideUi();
    const panel = document.createElement("div");
    panel.className = className;
    shadow.appendChild(panel);
    state.panel = panel;
    state.anchor = anchor instanceof Element ? anchor : activeElementDeep();
    return panel;
  }

  function renderStatus(kind, message, anchor = null) {
    const panel = createPanel("panel", anchor);
    panel.innerHTML = `<div class="status ${kind}">${message}</div>`;
    state.uiKind = "status";
    positionPanel(panel, state.anchor);
  }

  function setSelectedIndex(index) {
    if (state.uiKind !== "chooser" || !state.panel || !state.chooserItems.length) {
      return;
    }
    state.selectedIndex = (index + state.chooserItems.length) % state.chooserItems.length;
    state.panel.querySelectorAll(".choice").forEach((button, index) => {
      button.setAttribute("data-active", index === state.selectedIndex ? "true" : "false");
    });
  }

  function chooseIndex(index) {
    if (state.uiKind !== "chooser") {
      return;
    }
    const entry = state.chooserItems[index];
    if (!entry || !state.payload) {
      return;
    }
    const filled = fillItem(entry.item, state.chooserContext, state.payload);
    if (!filled) {
      renderStatus("error", "Could not fill the focused login fields.", state.anchor);
    }
  }

  function toggleChoiceReveal(choice) {
    if (!(choice instanceof HTMLElement)) {
      return;
    }
    const next = choice.dataset.revealed !== "true";
    choice.dataset.revealed = next ? "true" : "false";
    const toggle = choice.querySelector(".choiceReveal");
    if (toggle instanceof HTMLButtonElement) {
      toggle.textContent = next ? "Hide" : "Show";
      toggle.setAttribute("aria-label", next ? "Hide password" : "Show password");
      toggle.setAttribute("aria-pressed", next ? "true" : "false");
    }
  }

  function renderChooser(ranked, context) {
    const items = ranked.slice(0, 9);
    const panel = createPanel("panel chooser", context.activeField);
    panel.tabIndex = 0;
    panel.innerHTML =
      `<div class="chooserHeader">Choose Bitwarden login</div>` +
      items
        .map((entry, index) => {
          const subtitle = text(entry.item.username) || text(entry.item.name);
          const hint =
            entry.siteScore >= 360
              ? "Exact site match"
              : entry.siteScore >= 260
                ? "Domain match"
                : entry.typedScore
                  ? "Matches typed username"
                  : "";
          return `<div class="choice" data-index="${index}" data-active="${index === 0}" data-revealed="false">
            <button type="button" class="choicePick" data-index="${index}">
              <span class="choiceIndex">${index + 1}</span>
              <span>
                <div class="choiceTitle">${escapeHtml(entry.item.name || "Unnamed item")}</div>
                <div class="choiceSubtitle">${escapeHtml(subtitle || "No username")}</div>
                ${hint ? `<div class="choiceHint">${escapeHtml(hint)}</div>` : ""}
                ${entry.item.password ? `<div class="choiceSecret">${escapeHtml(entry.item.password)}</div>` : ""}
              </span>
            </button>
            ${
              entry.item.password
                ? `<button type="button" class="choiceReveal" aria-label="Show password" aria-pressed="false">Show</button>`
                : ""
            }
          </div>`;
        })
        .join("") +
      `<div class="chooserFooter">Enter to fill. Ctrl-n/Ctrl-p, arrows, or j/k to move.</div>`;
    panel.addEventListener("click", (event) => {
      const target = event.target instanceof Element ? event.target : null;
      const reveal = target ? target.closest(".choiceReveal") : null;
      if (reveal instanceof HTMLElement) {
        toggleChoiceReveal(reveal.closest(".choice"));
        return;
      }
      const choice = target ? target.closest(".choice") : null;
      if (choice instanceof HTMLElement) {
        chooseIndex(Number(choice.dataset.index || 0));
      }
    });

    state.uiKind = "chooser";
    state.chooserItems = items;
    state.chooserContext = context;
    setSelectedIndex(0);
    positionPanel(panel, state.anchor);
    panel.focus({ preventScroll: true });
  }

  function fillItem(item, context, payload) {
    const activeContext = context || collectContext();
    if (!activeContext) {
      return false;
    }

    let didFill = false;
    const mode = payload.mode || "auto";

    const fillUsername =
      mode === "username" ||
      (mode === "auto" && !!activeContext.usernameField && (activeContext.activeRole === "username" || !!activeContext.passwordField));
    const fillPassword =
      mode === "password" ||
      (mode === "auto" &&
        !!activeContext.passwordField &&
        (activeContext.activeRole === "password" || !!activeContext.usernameField));
    const fillOtp = mode === "totp" || (mode === "auto" && activeContext.activeRole === "otp");

    if (fillUsername && activeContext.usernameField && text(item.username)) {
      didFill = setFieldValue(activeContext.usernameField, item.username) || didFill;
    }
    if (fillPassword && activeContext.passwordField && text(item.password)) {
      didFill = setFieldValue(activeContext.passwordField, item.password) || didFill;
    }
    if (fillOtp && activeContext.otpField && text(item.totpCode)) {
      didFill = setFieldValue(activeContext.otpField, item.totpCode) || didFill;
    }

    if (didFill) {
      state.payload = null;
      state.pendingReady = false;
      hideUi();
      const focusTarget =
        activeContext.passwordField || activeContext.usernameField || activeContext.otpField || activeContext.activeField;
      if (focusTarget instanceof HTMLElement) {
        focusTarget.focus({ preventScroll: true });
      }
    }

    return didFill;
  }

  function handleRankedItems(ranked, context, payload) {
    if (!ranked.length) {
      renderStatus("error", "No usable Bitwarden logins were returned for this page.", context.activeField);
      state.pendingReady = false;
      return;
    }
    if (ranked.length === 1 && fillItem(ranked[0].item, context, payload)) {
      state.pendingReady = false;
      return;
    }
    renderChooser(ranked, context);
    state.pendingReady = false;
  }

  function rankedPayloadItems(payload, context) {
    return rankItems(Array.isArray(payload.items) ? payload.items : [], context, payload);
  }

  function presentReadyPayload(payload) {
    const pageHost = location.hostname.toLowerCase();
    if (hostFromUrl(payload.currentUrl) !== pageHost) {
      renderStatus("info", "Page changed. Focus the login field and press Ctrl-Space again.", activeElementDeep());
      state.pendingReady = true;
      return;
    }

    const context = collectContext();
    if (!context) {
      renderStatus("info", "Focus a username or password field, then press Ctrl-Space.", activeElementDeep());
      state.pendingReady = true;
      return;
    }

    handleRankedItems(rankedPayloadItems(payload, context), context, payload);
  }

  function receive(payload) {
    if (!payload || typeof payload !== "object") {
      return;
    }
    const requestId = Number(payload.requestId || 0);
    if (requestId && requestId < state.lastRequestId) {
      return;
    }
    if (requestId) {
      state.lastRequestId = requestId;
    }

    if (payload.phase === "loading") {
      state.payload = null;
      state.pendingReady = false;
      renderStatus("loading", "Looking up Bitwarden matches...", collectContext()?.activeField || activeElementDeep());
      return;
    }

    if (payload.phase === "error") {
      state.payload = null;
      state.pendingReady = false;
      renderStatus("error", text(payload.message) || "Bitwarden failed.", collectContext()?.activeField || activeElementDeep());
      return;
    }

    if (payload.phase !== "ready") {
      return;
    }

    state.payload = payload;
    presentReadyPayload(payload);
  }

  function handleFocusIn() {
    if (!state.payload) {
      return;
    }
    if (state.pendingReady) {
      presentReadyPayload(state.payload);
      return;
    }

    const context = collectContext();
    if (!context) {
      return;
    }

    if (state.uiKind === "chooser" && state.panel) {
      state.anchor = context.activeField;
      state.chooserContext = context;
      positionPanel(state.panel, context.activeField);
      return;
    }

    if (context.activeRole !== "password" && context.activeRole !== "otp") {
      return;
    }

    handleRankedItems(rankedPayloadItems(state.payload, context), context, state.payload);
  }

  function handleKeyDown(event) {
    if (state.uiKind !== "chooser" || !state.panel || !state.chooserItems.length) {
      return;
    }

    const key = lower(event.key);
    const isCtrlN = event.ctrlKey && !event.metaKey && !event.altKey && (key === "n" || event.code === "KeyN");
    const isCtrlP = event.ctrlKey && !event.metaKey && !event.altKey && (key === "p" || event.code === "KeyP");

    if (key === "arrowdown" || key === "down" || key === "j" || isCtrlN) {
      event.preventDefault();
      event.stopPropagation();
      setSelectedIndex(state.selectedIndex + 1);
      return;
    }
    if (key === "arrowup" || key === "up" || key === "k" || isCtrlP) {
      event.preventDefault();
      event.stopPropagation();
      setSelectedIndex(state.selectedIndex - 1);
      return;
    }
    if (key === "enter") {
      event.preventDefault();
      event.stopPropagation();
      chooseIndex(state.selectedIndex);
      return;
    }
    if (key === "escape") {
      event.preventDefault();
      event.stopPropagation();
      hideUi();
      return;
    }
    if (/^[1-9]$/.test(key)) {
      const index = Number(key) - 1;
      if (index < state.chooserItems.length) {
        event.preventDefault();
        event.stopPropagation();
        chooseIndex(index);
      }
    }
  }

  window.__quteBitwardenController = { receive };
  window.addEventListener(EVENT_NAME, (event) => receive(event.detail));
  document.addEventListener("focusin", handleFocusIn, true);
  document.addEventListener("keydown", handleKeyDown, true);
  document.addEventListener(
    "pointerdown",
    (event) => {
      if (!state.panel) {
        return;
      }
      const path = typeof event.composedPath === "function" ? event.composedPath() : [];
      if (!path.includes(state.panel) && (state.uiKind === "chooser" || state.uiKind === "status")) {
        hideUi();
      }
    },
    true,
  );
  window.addEventListener("scroll", () => state.panel && positionPanel(state.panel, state.anchor), true);
  window.addEventListener("resize", () => state.panel && positionPanel(state.panel, state.anchor), true);
  window.addEventListener("pagehide", hideUi, true);
})();
