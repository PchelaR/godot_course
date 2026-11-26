document.addEventListener("DOMContentLoaded", () => {
  const progress = document.createElement("div");
  progress.className = "site-progress";
  document.body.append(progress);

  const navSections = [...document.querySelectorAll(".site-nav li.toctree-l1")]
    .filter((item) => item.querySelector(":scope > ul"));
  const updateExpand = () => {
    for (const item of navSections) {
      const open = item.classList.contains("site-nav-open");
      const button = item.querySelector(":scope > .site-nav-expand");
      button.setAttribute("aria-expanded", String(open));
      button.setAttribute("aria-label", open ? "Свернуть раздел" : "Развернуть раздел");
    }
  };
  for (const item of navSections) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "site-nav-expand";
    button.addEventListener("click", () => {
      const open = !item.classList.contains("site-nav-open");
      for (const other of navSections) {
        other.classList.remove("site-nav-open");
      }
      item.classList.toggle("site-nav-open", open);
      updateExpand();
    });
    item.querySelector(":scope > a")?.after(button);
  }
  updateExpand();

  const pagePath = (href) => new URL(href, window.location.href).pathname.replace(/index\.html$/, "");
  const readDone = () => {
    try {
      return new Set(JSON.parse(localStorage.getItem("done-pages") || "[]"));
    } catch (error) {
      return new Set();
    }
  };
  const done = readDone();
  const here = pagePath(window.location.href);
  const navLinks = [...document.querySelectorAll(".site-nav a[href]")];
  const inNav = navLinks.some((link) => pagePath(link.href) === here);

  const markNav = () => {
    for (const link of navLinks) {
      link.classList.toggle("site-nav-done", done.has(pagePath(link.href)));
    }
    for (const item of document.querySelectorAll(".site-nav li.toctree-l1")) {
      const head = item.querySelector(":scope > a");
      const pages = [...item.querySelectorAll(":scope > ul a[href]")];
      if (!head || !pages.length) {
        continue;
      }
      let count = head.querySelector(".site-nav-count");
      if (!count) {
        count = document.createElement("span");
        count.className = "site-nav-count";
        head.append(count);
      }
      const finished = pages.filter((link) => done.has(pagePath(link.href))).length;
      count.textContent = `${finished}/${pages.length}`;
      head.classList.toggle("site-nav-done", finished === pages.length);
    }
  };
  markNav();

  const finishPage = () => {
    if (!inNav || done.has(here)) {
      return;
    }
    done.add(here);
    try {
      localStorage.setItem("done-pages", JSON.stringify([...done]));
    } catch (error) {
    }
    markNav();
    document.dispatchEvent(new CustomEvent("site-page-done"));
  };

  const updateProgress = () => {
    const max = document.documentElement.scrollHeight - window.innerHeight;
    const ratio = max > 0 ? window.scrollY / max : 1;
    progress.style.transform = `scaleX(${max > 0 ? ratio : 0})`;
    if (ratio >= 0.9) {
      finishPage();
    }
  };

  const links = [...document.querySelectorAll(".site-toc a[href^='#']")];
  const sections = links
    .map((link) => [link, document.getElementById(decodeURIComponent(link.hash.slice(1)))])
    .filter(([, section]) => section);

  const updateToc = () => {
    if (!sections.length) {
      return;
    }
    let current = sections[0][0];
    for (const [link, section] of sections) {
      if (section.getBoundingClientRect().top < 120) {
        current = link;
      }
    }
    for (const link of links) {
      link.classList.toggle("site-toc-active", link === current);
    }
  };

  let scheduled = false;
  const onScroll = () => {
    if (scheduled) {
      return;
    }
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      updateProgress();
      updateToc();
    });
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onScroll);
  onScroll();

  document.querySelector(".site-theme-toggle")?.addEventListener("click", () => {
    const root = document.documentElement;
    const theme = root.dataset.theme === "light" ? "dark" : "light";
    root.dataset.theme = theme;
    try {
      localStorage.setItem("theme", theme);
    } catch (error) {
    }
  });

  document.addEventListener("dragstart", (event) => {
    if (event.target instanceof HTMLImageElement) {
      event.preventDefault();
    }
  });

  const sidebar = document.querySelector(".site-sidebar");
  window.addEventListener("pagehide", () => {
    try {
      sessionStorage.setItem("sidebar-scroll", String(sidebar?.scrollTop ?? 0));
    } catch (error) {
    }
  });

  const search = document.querySelector(".site-search input");
  document.addEventListener("keydown", (event) => {
    const typing = ["INPUT", "TEXTAREA"].includes(document.activeElement?.tagName);
    if (event.key === "/" && !typing && search) {
      event.preventDefault();
      search.focus();
    }
  });

  const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const title = document.querySelector('.site[data-page="index"] div.body > section > h1');
  const titleText = title?.firstChild;
  if (!calm && titleText?.nodeType === Node.TEXT_NODE) {
    const full = titleText.textContent;
    title.setAttribute("aria-label", full.trim());
    titleText.textContent = "";
    const cursor = document.createElement("span");
    cursor.className = "site-cursor";
    cursor.setAttribute("aria-hidden", "true");
    titleText.after(cursor);
    let shown = 0;
    const type = setInterval(() => {
      shown += 1;
      titleText.textContent = full.slice(0, shown);
      if (shown >= full.length) {
        clearInterval(type);
      }
    }, 70);
  }

  const windows = document.querySelectorAll(
    "div.example, div.admonition, div.in-game, .godot-demo, .sd-card, table.docutils, figure.screenshot",
  );
  if (!calm && "IntersectionObserver" in window) {
    const reveal = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("site-reveal-shown");
          reveal.unobserve(entry.target);
        }
      }
    }, { rootMargin: "0px 0px -40px 0px" });
    for (const element of windows) {
      if (element.getBoundingClientRect().top > window.innerHeight) {
        element.classList.add("site-reveal");
        reveal.observe(element);
      }
    }
  }

  const burst = (x, y) => {
    for (let i = 0; i < 12; i += 1) {
      const pixel = document.createElement("span");
      pixel.className = `site-pixel site-pixel-${(i % 3) + 1}`;
      pixel.style.left = `${x - 6}px`;
      pixel.style.top = `${y - 6}px`;
      document.body.append(pixel);
      const angle = (Math.PI * 2 * i) / 12 + Math.random() * 0.4;
      const distance = 40 + Math.random() * 50;
      const dx = Math.round(Math.cos(angle) * distance / 4) * 4;
      const dy = Math.round(Math.sin(angle) * distance / 4) * 4;
      pixel.animate(
        [
          { transform: "translate(0, 0)", opacity: 1 },
          { transform: `translate(${dx}px, ${dy + 24}px)`, opacity: 0 },
        ],
        { duration: 600, easing: "steps(6)" },
      ).finished.then(() => pixel.remove());
    }
  };

  if (!calm) {
    document.addEventListener("click", (event) => {
      const button = event.target.closest(".button, .site-theme-toggle, a.project-download");
      if (button && event.detail > 0) {
        burst(event.clientX, event.clientY);
      }
    });
  }

  const toast = (text) => {
    document.querySelector(".site-toast")?.remove();
    const message = document.createElement("div");
    message.className = "site-toast";
    message.setAttribute("role", "status");
    message.textContent = text;
    document.body.append(message);
    setTimeout(() => message.remove(), 2000);
  };

  const konami = [
    "ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown",
    "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight",
    "KeyB", "KeyA",
  ];
  let progressKey = 0;
  document.addEventListener("keydown", (event) => {
    progressKey = event.code === konami[progressKey] ? progressKey + 1 : Number(event.code === konami[0]);
    if (progressKey < konami.length) {
      return;
    }
    progressKey = 0;
    const enabled = document.documentElement.classList.toggle("site-crt");
    try {
      localStorage.setItem("crt", enabled ? "on" : "off");
    } catch (error) {
    }
    toast(enabled ? "CRT: ВКЛ" : "CRT: ВЫКЛ");
    if (enabled) {
      unlock("konami", "Читер!", "Вы ввели код Konami и включили режим CRT.");
    }
  });

  const copyText = async (text) => {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (error) {
      const area = document.createElement("textarea");
      area.value = text;
      area.style.position = "fixed";
      area.style.opacity = "0";
      document.body.append(area);
      area.select();
      const done = document.execCommand("copy");
      area.remove();
      return done;
    }
  };

  for (const block of document.querySelectorAll("div:not(.highlight-text) > div.highlight")) {
    const code = block.querySelector("pre");
    if (!code) {
      continue;
    }
    block.classList.add("site-copyable");
    block.tabIndex = 0;
    block.setAttribute("role", "button");
    block.setAttribute("aria-label", "Скопировать код");
    let timer = 0;
    const copy = async (x, y) => {
      if (!(await copyText(block.dataset.code ?? code.innerText.replace(/\n$/, "")))) {
        return;
      }
      block.classList.remove("site-copied");
      void block.offsetWidth;
      block.classList.add("site-copied");
      clearTimeout(timer);
      timer = setTimeout(() => block.classList.remove("site-copied"), 1500);
      if (!calm) {
        burst(x, y);
      }
      unlock("copy", "Ctrl+C", "Вы скопировали первый пример кода.");
    };
    block.addEventListener("click", (event) => {
      if (String(window.getSelection())) {
        return;
      }
      copy(event.clientX, event.clientY);
    });
    block.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        const box = block.getBoundingClientRect();
        copy(box.left + box.width / 2, box.top + box.height / 2);
      }
    });
  }

  document.addEventListener("keydown", (event) => {
    if (progressKey > 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
      return;
    }
    const focused = document.activeElement;
    if (["INPUT", "TEXTAREA", "SELECT"].includes(focused?.tagName) || focused?.isContentEditable) {
      return;
    }
    const selector = { ArrowLeft: ".site-pager-prev", ArrowRight: ".site-pager-next" }[event.key];
    const link = selector && document.querySelector(selector);
    if (link) {
      event.preventDefault();
      window.location.href = link.href;
    }
  });

  const tip = document.createElement("div");
  tip.className = "site-term-tip";
  tip.setAttribute("role", "tooltip");
  tip.hidden = true;
  document.body.append(tip);
  const glossaries = new Map();
  const loadGlossary = (url) => {
    if (!glossaries.has(url)) {
      glossaries.set(url, fetch(url)
        .then((response) => (response.ok ? response.text() : ""))
        .then((html) => new DOMParser().parseFromString(html, "text/html"))
        .catch(() => null));
    }
    return glossaries.get(url);
  };
  let tipFor = null;
  const showTip = async (link) => {
    tipFor = link;
    const url = new URL(link.href);
    const id = decodeURIComponent(url.hash.slice(1));
    url.hash = "";
    const page = await loadGlossary(url.href);
    const term = page?.getElementById(id);
    const definition = term?.nextElementSibling;
    if (tipFor !== link || !term || !definition) {
      return;
    }
    const title = document.createElement("p");
    title.className = "site-term-tip-title";
    title.textContent = term.textContent.replace(/#\s*$/, "").trim();
    const text = document.createElement("p");
    text.className = "site-term-tip-text";
    text.textContent = definition.textContent.replace(/\s+/g, " ").trim();
    tip.replaceChildren(title, text);
    tip.hidden = false;
    const box = link.getBoundingClientRect();
    const width = tip.offsetWidth;
    const left = Math.min(Math.max(8, box.left), window.innerWidth - width - 16);
    tip.style.left = `${left + window.scrollX}px`;
    tip.style.top = `${box.bottom + window.scrollY + 8}px`;
  };
  const hideTip = () => {
    tipFor = null;
    tip.hidden = true;
  };
  const touch = window.matchMedia("(pointer: coarse)");
  window.addEventListener("scroll", () => {
    if (touch.matches) {
      hideTip();
    }
  }, { passive: true });
  document.addEventListener("click", (event) => {
    if (touch.matches && !event.target.closest('a[href*="#term-"]')) {
      hideTip();
    }
  });
  for (const link of document.querySelectorAll('a.reference.internal[href*="#term-"]')) {
    link.addEventListener("click", (event) => {
      if (touch.matches && tipFor !== link) {
        event.preventDefault();
        showTip(link);
      }
    });
    link.addEventListener("mouseenter", () => {
      if (!touch.matches) {
        showTip(link);
      }
    });
    link.addEventListener("focus", () => {
      if (!touch.matches) {
        showTip(link);
      }
    });
    link.addEventListener("mouseleave", () => {
      if (!touch.matches) {
        hideTip();
      }
    });
    link.addEventListener("blur", hideTip);
  }

  const unlocked = (() => {
    try {
      return new Set(JSON.parse(localStorage.getItem("achievements") || "[]"));
    } catch (error) {
      return new Set();
    }
  })();
  const queue = [];
  let showing = false;
  const showNext = () => {
    const next = queue.shift();
    if (!next) {
      showing = false;
      return;
    }
    showing = true;
    const box = document.createElement("div");
    box.className = "site-achievement";
    box.setAttribute("role", "status");
    const title = document.createElement("p");
    title.className = "site-achievement-title";
    title.textContent = "ACHIEVEMENT UNLOCKED";
    const name = document.createElement("p");
    name.className = "site-achievement-name";
    name.textContent = next.name;
    const text = document.createElement("p");
    text.className = "site-achievement-text";
    text.textContent = next.text;
    box.append(title, name, text);
    document.body.append(box);
    setTimeout(() => {
      box.remove();
      showNext();
    }, 3500);
  };
  function unlock(id, name, text) {
    if (unlocked.has(id)) {
      return;
    }
    unlocked.add(id);
    try {
      localStorage.setItem("achievements", JSON.stringify([...unlocked]));
    } catch (error) {
    }
    queue.push({ name, text });
    if (!showing) {
      showNext();
    }
  }

  const leafLinks = navLinks.filter((link) => !link.parentElement.querySelector(":scope > ul"));
  const leafPages = [...new Set(leafLinks.map((link) => pagePath(link.href)))];
  const hiscore = document.querySelector(".site-hiscore");
  const pad = (value) => String(value).padStart(3, "0");
  const checkProgress = () => {
    const finished = leafPages.filter((page) => done.has(page)).length;
    if (hiscore && leafPages.length) {
      hiscore.textContent = `HI-SCORE ${pad(finished)} / ${pad(leafPages.length)}`;
    }
    if (finished >= 1) {
      unlock("first", "Первый шаг", "Прочитана первая статья.");
    }
    for (const item of navSections) {
      const head = item.querySelector(":scope > a");
      const pages = [...item.querySelectorAll(":scope > ul a[href]")].map((link) => pagePath(link.href));
      if (head && pages.length && pages.every((page) => done.has(page))) {
        const title = head.childNodes[0]?.textContent.trim() || "";
        unlock(`section:${pagePath(head.href)}`, "Раздел пройден", `«${title}» прочитан целиком.`);
      }
    }
    if (leafPages.length && finished === leafPages.length) {
      unlock("all", "Нулевой уровень пройден", "Прочитана вся документация.");
    }
  };
  document.addEventListener("site-page-done", checkProgress);
  checkProgress();

  const top = document.createElement("button");
  top.type = "button";
  top.className = "site-top";
  top.textContent = "\u25B2 1UP";
  top.setAttribute("aria-label", "Наверх");
  top.hidden = true;
  document.body.append(top);
  window.addEventListener("scroll", () => {
    top.hidden = window.scrollY < 600;
  }, { passive: true });
  top.addEventListener("click", () => {
    if (calm) {
      window.scrollTo({ top: 0, behavior: "instant" });
      return;
    }
    const start = window.scrollY;
    let step = 0;
    const climb = setInterval(() => {
      step += 1;
      window.scrollTo({ top: Math.round(start * (1 - step / 8)), behavior: "instant" });
      if (step >= 8) {
        clearInterval(climb);
      }
    }, 40);
  });

  const heroSection = document.querySelector('.site[data-page="index"] div.hero');
  if (heroSection) {
    const mascot = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    mascot.setAttribute("class", "site-mascot");
    mascot.setAttribute("viewBox", "0 0 32 32");
    mascot.setAttribute("shape-rendering", "crispEdges");
    mascot.setAttribute("aria-hidden", "true");
    mascot.innerHTML = '<path class="site-mascot-k" d="M6 12h20v1h-20zM6 13h20v1h-20zM6 14h20v1h-20zM6 15h20v1h-20zM6 16h6v1h-6zM14 16h8v1h-8zM24 16h2v1h-2zM6 17h6v1h-6zM14 17h8v1h-8zM24 17h2v1h-2zM6 18h6v1h-6zM14 18h8v1h-8zM24 18h2v1h-2zM6 19h6v1h-6zM14 19h8v1h-8zM24 19h2v1h-2zM6 20h20v1h-20zM6 21h20v1h-20zM6 22h10v1h-10zM20 22h6v1h-6zM6 23h10v1h-10zM20 23h6v1h-6zM6 24h20v1h-20zM6 25h20v1h-20z"/><path class="site-mascot-a" d="M11 4h4v1h-4zM11 5h4v1h-4zM15 6h2v1h-2zM15 7h2v1h-2zM15 8h2v1h-2zM15 9h2v1h-2zM6 10h20v1h-20zM6 11h20v1h-20zM4 12h2v1h-2zM26 12h2v1h-2zM4 13h2v1h-2zM26 13h2v1h-2zM4 14h2v1h-2zM26 14h2v1h-2zM4 15h2v1h-2zM26 15h2v1h-2zM2 16h4v1h-4zM26 16h4v1h-4zM2 17h4v1h-4zM26 17h4v1h-4zM2 18h4v1h-4zM26 18h4v1h-4zM2 19h4v1h-4zM26 19h4v1h-4zM2 20h4v1h-4zM26 20h4v1h-4zM2 21h4v1h-4zM26 21h4v1h-4zM4 22h2v1h-2zM26 22h2v1h-2zM4 23h2v1h-2zM26 23h2v1h-2zM4 24h2v1h-2zM26 24h2v1h-2zM4 25h2v1h-2zM26 25h2v1h-2zM6 26h20v1h-20zM6 27h20v1h-20zM16 22h4v1h-4zM16 23h4v1h-4z"/><path class="site-mascot-e" d="M12 16h2v1h-2zM22 16h2v1h-2zM12 17h2v1h-2zM22 17h2v1h-2zM12 18h2v1h-2zM22 18h2v1h-2zM12 19h2v1h-2zM22 19h2v1h-2z"/>';
    heroSection.prepend(mascot);
    mascot.addEventListener("click", (event) => {
      if (!calm) {
        burst(event.clientX, event.clientY);
      }
      unlock("mascot", "Тык!", "Вы познакомились с роботом.");
    });
  }

  for (const demo of document.querySelectorAll(".godot-demo[data-src]")) {
    const debug = demo.querySelector(".godot-demo-debug");
    const applyDebug = () => {
      const on = debug?.getAttribute("aria-pressed") === "true";
      const frame = demo.querySelector("iframe");
      try {
        if (frame?.contentWindow) {
          frame.contentWindow.godotDebug = on;
        }
      } catch (error) {
      }
    };
    debug?.addEventListener("click", () => {
      const on = debug.getAttribute("aria-pressed") !== "true";
      debug.setAttribute("aria-pressed", String(on));
      debug.textContent = on ? "МЫСЛИ: ВКЛ" : "МЫСЛИ: ВЫКЛ";
      applyDebug();
    });
    demo.querySelector(".godot-demo-start")?.addEventListener("click", () => {
      const frame = document.createElement("iframe");
      frame.addEventListener("load", applyDebug);
      frame.src = demo.dataset.src;
      frame.title = demo.dataset.title || "";
      frame.allow = "autoplay; fullscreen; gamepad";
      const screen = demo.querySelector(".godot-demo-screen");
      screen.replaceChildren(frame);
      screen.classList.add("godot-demo-running");
      frame.focus();
    });
  }
});

if ("serviceWorker" in navigator && window.location.protocol === "https:") {
  const manifest = document.querySelector('link[rel="manifest"]');
  if (manifest) {
    navigator.serviceWorker.register(new URL("sw.js", manifest.href)).catch(() => {});
  }
}
