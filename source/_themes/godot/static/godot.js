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
      unlock("konami");
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
      unlock("copy");
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
    unlock("glossary");
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

  const readSet = (key) => {
    try {
      return new Set(JSON.parse(localStorage.getItem(key) || "[]"));
    } catch (error) {
      return new Set();
    }
  };
  const writeSet = (key, set) => {
    try {
      localStorage.setItem(key, JSON.stringify([...set]));
    } catch (error) {
    }
  };
  const unlocked = readSet("achievements");
  const demosRun = readSet("demos-run");
  const sectionTrophies = navSections
    .map((item) => item.querySelector(":scope > a"))
    .filter(Boolean)
    .map((head) => ({
      id: `section:${pagePath(head.href)}`,
      name: `Раздел «${head.childNodes[0]?.textContent.trim() || ""}»`,
      text: "Прочитан целиком.",
      icon: "book-open",
    }));
  const trophies = [
    { id: "first", name: "Первый шаг", text: "Прочитана первая статья.", icon: "flag" },
    ...sectionTrophies,
    { id: "all", name: "Нулевой уровень пройден", text: "Прочитана вся документация.", icon: "crown" },
    { id: "demo", name: "Нажми старт", text: "Запущен первый пример в Godot.", icon: "play" },
    { id: "demos", name: "Испытатель", text: "Запущено десять разных примеров.", icon: "joystick" },
    { id: "download", name: "Сохранение", text: "Скачан первый проект.", icon: "download" },
    { id: "copy", name: "Ctrl+C", text: "Скопирован первый пример кода.", icon: "copy" },
    { id: "glossary", name: "Словарь", text: "Открыта подсказка термина.", icon: "library" },
    { id: "trophies", name: "Коллекционер", text: "Найдена стена трофеев.", icon: "star" },
    { id: "level5", name: "Ветеран", text: "Достигнут четвёртый уровень.", icon: "shield" },
    { id: "game:driver", name: "За рулём", text: "Сесть в машину в Нулевом квартале.", icon: "car" },
    { id: "game:hijack", name: "Угонщик", text: "Угнать машину с дороги в Нулевом квартале.", icon: "key" },
    { id: "game:stars", name: "Самый разыскиваемый", text: "Пять звёзд розыска в Нулевом квартале.", icon: "siren" },
    { id: "game:boom", name: "Бабах", text: "Взорвать машину в Нулевом квартале.", icon: "bomb" },
    { id: "mascot", name: "Тык!", text: "Знакомство с роботом.", icon: "robot-face-happy", secret: true },
    { id: "konami", name: "Читер!", text: "Введён код Konami, включён режим CRT.", icon: "keyboard", secret: true },
    { id: "night", name: "Ночная смена", text: "Чтение документации после полуночи.", icon: "moon", secret: true },
    { id: "touch", name: "Геймпад в кармане", text: "Пример пройден на экранном управлении.", icon: "smartphone", secret: true },
    { id: "snake", name: "Змеелов", text: "Десять потерянных страниц найдено на странице 404.", icon: "snake", secret: true },
  ];
  const trophyById = new Map(trophies.map((trophy) => [trophy.id, trophy]));
  function unlock(id) {
    const trophy = trophyById.get(id);
    if (!trophy || unlocked.has(id)) {
      return;
    }
    unlocked.add(id);
    writeSet("achievements", unlocked);
    renderLevel();
    renderTrophies();
  }

  const leafLinks = navLinks.filter((link) => !link.parentElement.querySelector(":scope > ul"));
  const leafPages = [...new Set(leafLinks.map((link) => pagePath(link.href)))];
  const hiscore = document.querySelector(".site-hiscore");
  const pad = (value) => String(value).padStart(3, "0");
  const checkProgress = () => {
    const finished = leafPages.filter((page) => done.has(page)).length;
    if (hiscore && leafPages.length) {
      const left = leafPages.length - finished;
      hiscore.textContent = left
        ? `ПРОЙДЕНО ${pad(finished)} / ${pad(leafPages.length)} · ДО КОНЦА НУЛЕВОГО УРОВНЯ: ${left}`
        : "НУЛЕВОЙ УРОВЕНЬ ПРОЙДЕН";
    }
    if (finished >= 1) {
      unlock("first");
    }
    for (const item of navSections) {
      const head = item.querySelector(":scope > a");
      const pages = [...item.querySelectorAll(":scope > ul a[href]")].map((link) => pagePath(link.href));
      if (head && pages.length && pages.every((page) => done.has(page))) {
        unlock(`section:${pagePath(head.href)}`);
      }
    }
    if (leafPages.length && finished === leafPages.length) {
      unlock("all");
    }
    renderLevel();
    renderTrophies();
  };

  const XP_PAGE = 10;
  const XP_TROPHY = 25;
  const XP_DEMO = 5;
  const levelStart = (level) => 50 * level * (level + 1);
  const stats = () => {
    const pages = leafPages.filter((page) => done.has(page)).length;
    const xp = pages * XP_PAGE + unlocked.size * XP_TROPHY + demosRun.size * XP_DEMO;
    const level = Math.floor((Math.sqrt(1 + (4 * xp) / 50) - 1) / 2);
    return { pages, xp, level };
  };
  const levelBox = document.querySelector(".site-level");
  let shownLevel = null;
  let shownXp = null;
  const floatXp = (amount) => {
    if (calm || amount <= 0) {
      return;
    }
    const visible = levelBox && levelBox.getBoundingClientRect().width > 0 && levelBox.offsetParent !== null;
    const box = visible ? levelBox.getBoundingClientRect() : null;
    const label = document.createElement("div");
    label.className = "site-xp-float";
    label.textContent = `+${amount} XP`;
    label.style.left = box ? `${box.left + box.width / 2}px` : "";
    label.style.translate = box ? "-50% 0" : "";
    label.style.top = box ? `${box.top}px` : "";
    label.classList.toggle("site-xp-float-corner", !box);
    document.body.append(label);
    label.addEventListener("animationend", () => label.remove());
  };
  function renderLevel() {
    const { xp, level } = stats();
    if (shownXp !== null) {
      floatXp(xp - shownXp);
    }
    shownXp = xp;
    if (levelBox) {
      const from = levelStart(level);
      const to = levelStart(level + 1);
      levelBox.querySelector(".site-level-value").textContent = String(level);
      levelBox.querySelector(".site-level-xp").textContent = `${xp - from} / ${to - from} XP`;
      levelBox.querySelector(".site-level-fill").style.transform = `scaleX(${(xp - from) / (to - from)})`;
    }
    let stored = null;
    try {
      stored = Number(localStorage.getItem("level")) || null;
      localStorage.setItem("level", String(level));
    } catch (error) {
    }
    const before = shownLevel ?? stored ?? level;
    shownLevel = level;
    if (level > before) {
      if (levelBox && !calm) {
        const box = levelBox.getBoundingClientRect();
        burst(box.left + box.width / 2, box.top + box.height / 2);
      }
      levelBox?.classList.remove("site-level-up");
      void levelBox?.offsetWidth;
      levelBox?.classList.add("site-level-up");
    }
    if (level >= 4) {
      unlock("level5");
    }
  }

  const wall = document.querySelector("div.site-trophies");
  const iconBase = new URL("icons/", document.querySelector('link[href*="godot.css"]')?.href || window.location.href).href;
  function renderTrophies() {
    if (!wall) {
      return;
    }
    const { pages, xp, level } = stats();
    const facts = [
      ["Уровень", String(level)],
      ["Опыт", `${xp} XP`],
      ["Статьи", `${pages} / ${leafPages.length}`],
      ["Примеры", String(demosRun.size)],
      ["Трофеи", `${trophies.filter((trophy) => unlocked.has(trophy.id)).length} / ${trophies.length}`],
    ];
    const summary = document.createElement("dl");
    summary.className = "site-trophies-stats";
    for (const [label, value] of facts) {
      const term = document.createElement("dt");
      term.textContent = label;
      const data = document.createElement("dd");
      data.textContent = value;
      summary.append(term, data);
    }
    const list = document.createElement("ul");
    list.className = "site-trophies-list";
    for (const trophy of trophies) {
      const open = unlocked.has(trophy.id);
      const hidden = trophy.secret && !open;
      const item = document.createElement("li");
      item.className = open ? "site-trophy site-trophy-open" : "site-trophy";
      item.style.setProperty("--icon", `url("${iconBase}${open ? trophy.icon : "lock"}.svg")`);
      const name = document.createElement("p");
      name.className = "site-trophy-name";
      name.textContent = hidden ? "???" : trophy.name;
      const text = document.createElement("p");
      text.className = "site-trophy-text";
      text.textContent = hidden ? "Секретный трофей." : trophy.text;
      item.append(name, text);
      list.append(item);
    }
    const reset = document.createElement("button");
    reset.type = "button";
    reset.className = "button site-trophies-reset";
    reset.textContent = "Начать заново";
    reset.addEventListener("click", () => {
      if (!window.confirm("Стереть уровень, трофеи и отметки о прочитанных статьях?")) {
        return;
      }
      try {
        for (const key of ["achievements", "demos-run", "done-pages", "level"]) {
          localStorage.removeItem(key);
        }
      } catch (error) {
      }
      window.location.reload();
    });
    wall.replaceChildren(summary, list, reset);
  }

  document.addEventListener("site-page-done", checkProgress);
  checkProgress();
  window.addEventListener("godot-trophy", (event) => unlock(`game:${event.detail}`));
  if (wall) {
    unlock("trophies");
  }
  const hour = new Date().getHours();
  if (hour < 5) {
    unlock("night");
  }
  document.addEventListener("click", (event) => {
    if (event.target.closest("a.project-download")) {
      unlock("download");
    }
  });

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

  const snakeBox = document.querySelector("div.site-snake");
  if (snakeBox) {
    const COLUMNS = 21;
    const ROWS = 13;
    const CELL = 16;
    const canvas = document.createElement("canvas");
    canvas.className = "site-snake-screen";
    canvas.tabIndex = 0;
    canvas.setAttribute("aria-label", "Змейка: WASD или свайпы, пробел — старт");
    const ratio = Math.max(1, Math.round(window.devicePixelRatio || 1));
    canvas.width = COLUMNS * CELL * ratio;
    canvas.height = ROWS * CELL * ratio;
    const board = canvas.getContext("2d");
    board.scale(ratio, ratio);
    const score = document.createElement("p");
    score.className = "site-snake-score";
    snakeBox.replaceChildren(score, canvas);

    let best = 0;
    try {
      best = Number(localStorage.getItem("snake-hiscore")) || 0;
    } catch (error) {
    }
    const color = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    const turns = { w: [0, -1], a: [-1, 0], s: [0, 1], d: [1, 0] };
    const codes = { KeyW: "w", KeyA: "a", KeyS: "s", KeyD: "d" };
    let body = [];
    let heading = [1, 0];
    let queued = [];
    let food = [0, 0];
    let eaten = 0;
    let state = "ready";
    let timer = null;

    const placeFood = () => {
      do {
        food = [Math.floor(Math.random() * COLUMNS), Math.floor(Math.random() * ROWS)];
      } while (body.some(([x, y]) => x === food[0] && y === food[1]));
    };
    const showScore = () => {
      score.textContent = `SCORE ${String(eaten).padStart(3, "0")}   HI ${String(best).padStart(3, "0")}`;
    };
    const cell = (x, y, fill, inset = 1) => {
      board.fillStyle = fill;
      board.fillRect(x * CELL + inset, y * CELL + inset, CELL - inset * 2, CELL - inset * 2);
    };
    const caption = (lines) => {
      board.fillStyle = color("--paper");
      board.globalAlpha = 0.8;
      board.fillRect(0, 0, COLUMNS * CELL, ROWS * CELL);
      board.globalAlpha = 1;
      board.fillStyle = color("--ink");
      board.font = `800 14px ${color("--mono")}`;
      board.textAlign = "center";
      lines.forEach((line, index) => {
        board.fillText(line, (COLUMNS * CELL) / 2, (ROWS * CELL) / 2 + (index - (lines.length - 1) / 2) * 22);
      });
    };
    const draw = () => {
      board.fillStyle = color("--window");
      board.fillRect(0, 0, COLUMNS * CELL, ROWS * CELL);
      board.fillStyle = color("--line");
      board.globalAlpha = 0.15;
      for (let x = 0; x < COLUMNS; x += 1) {
        for (let y = 0; y < ROWS; y += 1) {
          board.fillRect(x * CELL + CELL / 2 - 1, y * CELL + CELL / 2 - 1, 2, 2);
        }
      }
      board.globalAlpha = 1;
      cell(food[0], food[1], color("--accent-2"), 3);
      body.forEach(([x, y], index) => cell(x, y, index === 0 ? color("--ink") : color("--accent")));
      if (state === "ready") {
        caption(["НАЙДИ ПОТЕРЯННЫЕ СТРАНИЦЫ", "WASD / СВАЙП · ПРОБЕЛ / ТАП"]);
      } else if (state === "over") {
        caption(["GAME OVER", "ПРОБЕЛ / ТАП — ЕЩЁ РАЗ"]);
      }
    };
    const reset = () => {
      body = [[6, 6], [5, 6], [4, 6]];
      heading = [1, 0];
      queued = [];
      eaten = 0;
      placeFood();
      showScore();
    };
    const finish = () => {
      clearInterval(timer);
      timer = null;
      state = "over";
      draw();
    };
    const tick = () => {
      const next = queued.shift();
      if (next) {
        heading = next;
      }
      const head = [body[0][0] + heading[0], body[0][1] + heading[1]];
      const outside = head[0] < 0 || head[1] < 0 || head[0] >= COLUMNS || head[1] >= ROWS;
      if (outside || body.slice(0, -1).some(([x, y]) => x === head[0] && y === head[1])) {
        finish();
        return;
      }
      body.unshift(head);
      if (head[0] === food[0] && head[1] === food[1]) {
        eaten += 1;
        if (eaten > best) {
          best = eaten;
          try {
            localStorage.setItem("snake-hiscore", String(best));
          } catch (error) {
          }
        }
        if (eaten >= 10) {
          unlock("snake");
        }
        showScore();
        placeFood();
        clearInterval(timer);
        timer = setInterval(tick, Math.max(70, 140 - eaten * 4));
      } else {
        body.pop();
      }
      draw();
    };
    const start = () => {
      if (state === "playing") {
        return;
      }
      reset();
      state = "playing";
      draw();
      timer = setInterval(tick, 140);
    };
    const steer = (key) => {
      const turn = turns[key];
      const last = queued[queued.length - 1] || heading;
      if (turn && queued.length < 3 && turn[0] !== -last[0] && turn[1] !== -last[1]) {
        queued.push(turn);
      }
    };

    canvas.addEventListener("keydown", (event) => {
      if (event.code === "Space" || event.code === "Enter") {
        event.preventDefault();
        start();
        return;
      }
      const key = codes[event.code];
      if (key) {
        event.preventDefault();
        if (state !== "playing") {
          start();
        }
        steer(key);
      }
    });
    let touch = null;
    canvas.addEventListener("pointerdown", (event) => {
      canvas.focus({ preventScroll: true });
      touch = [event.clientX, event.clientY];
      if (state !== "playing") {
        start();
      }
    });
    canvas.addEventListener("pointermove", (event) => {
      if (!touch) {
        return;
      }
      const dx = event.clientX - touch[0];
      const dy = event.clientY - touch[1];
      if (Math.hypot(dx, dy) > 24) {
        steer(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "d" : "a") : dy > 0 ? "s" : "w");
        touch = [event.clientX, event.clientY];
      }
    });
    for (const type of ["pointerup", "pointercancel"]) {
      canvas.addEventListener(type, () => {
        touch = null;
      });
    }
    document.addEventListener("visibilitychange", () => {
      if (document.hidden && state === "playing") {
        finish();
      }
    });
    new MutationObserver(draw).observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
    reset();
    draw();
  }

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
      unlock("mascot");
    });
  }

  const padKeys = {
    move_left: { code: "KeyA", key: "a" },
    move_right: { code: "KeyD", key: "d" },
    move_up: { code: "KeyW", key: "w" },
    move_down: { code: "KeyS", key: "s" },
    jump: { code: "Space", key: " " },
    handbrake: { code: "Space", key: " " },
    ui_accept: { code: "Space", key: " " },
    dash: { code: "ShiftLeft", key: "Shift" },
    interact: { code: "KeyE", key: "e" },
    shoot: { code: "KeyF", key: "f" },
  };

  const setupPad = (demo) => {
    const pad = demo.querySelector(".godot-demo-pad");
    if (!pad) {
      return () => {};
    }
    const sources = { stick: new Set(), keys: new Set() };
    pad.addEventListener("pointerdown", () => unlock("touch"));
    const pressed = new Set();
    const send = (action, down) => {
      const frame = demo.querySelector("iframe");
      try {
        const canvas = frame?.contentWindow?.document.querySelector("canvas");
        if (!canvas) {
          return;
        }
        const event = new frame.contentWindow.KeyboardEvent(down ? "keydown" : "keyup", {
          ...padKeys[action],
          bubbles: true,
          cancelable: true,
        });
        canvas.dispatchEvent(event);
      } catch (error) {
      }
    };
    const sync = () => {
      const next = new Set([...sources.stick, ...sources.keys]);
      for (const action of [...pressed]) {
        if (!next.has(action)) {
          pressed.delete(action);
          send(action, false);
        }
      }
      for (const action of next) {
        if (!pressed.has(action)) {
          pressed.add(action);
          send(action, true);
        }
      }
    };
    const release = () => {
      sources.stick.clear();
      sources.keys.clear();
      sync();
    };

    const stick = pad.querySelector(".godot-demo-stick");
    if (stick) {
      const knob = stick.querySelector(".godot-demo-knob");
      const directions = new Set(stick.dataset.directions.split(" "));
      const steer = (event) => {
        const rect = stick.getBoundingClientRect();
        const radius = rect.width / 2;
        const vertical = directions.has("up") || directions.has("down");
        let x = (event.clientX - rect.left - radius) / radius;
        let y = vertical ? (event.clientY - rect.top - rect.height / 2) / radius : 0;
        const length = Math.hypot(x, y);
        if (length > 1) {
          x /= length;
          y /= length;
        }
        knob.style.transform = `translate(${x * radius * 0.6}px, ${y * radius * 0.6}px)`;
        const edge = vertical ? 0.38 : 0;
        sources.stick.clear();
        if (Math.hypot(x, y) > 0.25) {
          const unit = Math.hypot(x, y);
          const want = {
            left: x / unit < -edge,
            right: x / unit > edge,
            up: y / unit < -0.38,
            down: y / unit > 0.38,
          };
          for (const direction of directions) {
            if (want[direction]) {
              sources.stick.add(`move_${direction}`);
            }
          }
        }
        sync();
      };
      const stop = () => {
        knob.style.transform = "";
        sources.stick.clear();
        sync();
      };
      stick.addEventListener("pointerdown", (event) => {
        event.preventDefault();
        stick.setPointerCapture(event.pointerId);
        stick.classList.add("godot-demo-active");
        steer(event);
      });
      stick.addEventListener("pointermove", (event) => {
        if (stick.hasPointerCapture(event.pointerId)) {
          steer(event);
        }
      });
      for (const type of ["pointerup", "pointercancel", "lostpointercapture"]) {
        stick.addEventListener(type, () => {
          stick.classList.remove("godot-demo-active");
          stop();
        });
      }
    }

    for (const key of pad.querySelectorAll(".godot-demo-key")) {
      const action = key.dataset.action;
      key.addEventListener("pointerdown", (event) => {
        event.preventDefault();
        key.setPointerCapture(event.pointerId);
        key.classList.add("godot-demo-active");
        sources.keys.add(action);
        sync();
      });
      for (const type of ["pointerup", "pointercancel", "lostpointercapture"]) {
        key.addEventListener(type, () => {
          key.classList.remove("godot-demo-active");
          sources.keys.delete(action);
          sync();
        });
      }
    }

    pad.addEventListener("contextmenu", (event) => event.preventDefault());
    document.addEventListener("visibilitychange", release);
    return () => {
      pad.hidden = !window.matchMedia("(pointer: coarse)").matches;
    };
  };

  for (const demo of document.querySelectorAll(".godot-demo[data-src]")) {
    const showPad = setupPad(demo);
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
      showPad();
      demosRun.add(demo.dataset.src);
      writeSet("demos-run", demosRun);
      unlock("demo");
      if (demosRun.size >= 10) {
        unlock("demos");
      }
      renderLevel();
      renderTrophies();
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
