import pytest

PAGES = [
    "index.html",
    "intro/index.html",
    "intro/godot.html",
    "intro/comparison.html",
    "intro/gdscript.html",
    "intro/install.html",
    "gdscript/index.html",
    "gdscript/first_script.html",
    "gdscript/classes.html",
    "basics/index.html",
    "basics/script_and_node.html",
    "basics/nodes_and_scenes.html",
    "appendix/glossary.html",
    "search.html",
]


@pytest.mark.parametrize("name", PAGES)
def test_page_has_theme_layout(page, name):
    html = page(name)
    assert html.select_one("aside.site-sidebar") is not None
    assert html.select_one("main.site-main div.body[role=main]") is not None
    assert html.select_one("footer.site-footer") is not None


@pytest.mark.parametrize("name", PAGES)
def test_brand_links_to_root(page, name):
    brand = page(name).select_one("a.site-brand")
    assert brand is not None
    assert " ".join(brand.stripped_strings) == "Godot: нулевой уровень"
    assert brand["href"].endswith("index.html") or brand["href"] in ("#", "")


def test_html_language_is_russian(page):
    assert page("index.html").html["lang"] == "ru"


def test_search_form_points_to_search_page(page):
    form = page("intro/godot.html").select_one("form.site-search")
    assert form["action"].endswith("search.html")
    assert form.select_one("input[name=q]") is not None


def test_navigation_contains_chapters(page):
    links = [a.get_text(strip=True) for a in page("index.html").select("nav.site-nav a")]
    assert "0. Знакомство с Godot" in links
    assert "1. GDScript" in links
    assert "0.1. Движок Godot" in links
    assert "0.2. Godot, Unity и Unreal Engine" in links
    assert "0.3. Язык GDScript" in links
    assert "0.4. Установка Godot" in links
    assert "1.1. Первый скрипт" in links
    assert "1.11. Классы" in links
    assert "2. Основы Godot" in links
    assert "2.1. Скрипт и узел" in links
    assert "2.2. Узлы и сцены" in links
    assert "2.3. Обращение к узлам" in links
    assert "2.4. Жизненный цикл узла" in links
    assert "2.5. Координаты и Vector2" in links
    assert "2.6. Ввод" in links
    assert "2.7. Экспорт переменных" in links
    assert "2.8. Сигналы" in links
    assert "2.9. Экземпляры сцен из кода" in links
    assert "3. Создание игры" in links
    assert "3.1. Замысел игры" in links
    assert "3.2. Проект и пиксельная графика" in links
    assert "3.3. Лабиринт" in links
    assert "3.4. Движение по клеткам" in links
    assert "3.5. Поворот заранее" in links
    assert "3.6. Туннель" in links
    assert "3.7. Анимация героя" in links
    assert "4. Рецепты" in links
    assert "4.1. Движение" in links
    assert "4.1.3. Платформер" in links
    assert "4.2. Враги" in links
    assert "Восемь направлений" in links
    assert "Глоссарий" in links


def test_current_page_is_marked(page):
    current = page("intro/godot.html").select("nav.site-nav a.current")
    assert [a.get_text(strip=True) for a in current][-1] == "0.1. Движок Godot"


def test_local_toc_lists_sections(page):
    links = page("intro/comparison.html").select("aside.site-toc a")
    assert len(links) > 5


def test_index_has_no_local_toc(page):
    assert page("index.html").select("aside.site-toc a") == []


def test_pager_links_neighbours(page):
    html = page("intro/godot.html")
    prev = html.select_one("nav.site-pager a.site-pager-prev")
    assert prev is not None
    assert prev["href"].endswith("index.html")


def test_headerlink_icon(page):
    links = page("intro/godot.html").select("a.headerlink")
    assert links
    assert all(a.get_text() == "#" for a in links)


def test_mobile_menu_toggle(page):
    html = page("index.html")
    assert html.select_one("input#nav-toggle") is not None
    assert html.select_one("label[for=nav-toggle]") is not None


def test_cards_on_index(page):
    cards = page("index.html").select(".sd-card")
    assert len(cards) == 5


def test_chapter_links_glossary(page):
    hrefs = [a["href"] for a in page("intro/godot.html").select("a.reference.internal")]
    assert any("glossary.html#term" in h for h in hrefs)


def test_glossary_is_sorted(page):
    terms = [dt.get_text(strip=True).rstrip("#") for dt in page("appendix/glossary.html").select("dl.glossary dt")]
    assert terms == sorted(terms)
    assert "Узел" in terms


def test_examples_archive_published(site):
    import zipfile

    archive = site / "downloads" / "examples.zip"
    assert archive.is_file()
    names = zipfile.ZipFile(archive).namelist()
    assert "examples/project.godot" in names
    assert "examples/gdscript/first_script/first_script.gd" in names
    assert "examples/gdscript/first_script/first_script.out" in names
    assert not any(".godot/" in n for n in names)


def test_gdscript_articles_show_code_and_output(page):
    from conftest import SOURCE

    for rst in sorted((SOURCE / "gdscript").glob("*.rst")):
        if rst.stem == "index":
            continue
        html = page(f"gdscript/{rst.stem}.html")
        assert html.select("div.example div.highlight-gdscript"), rst.stem
        assert html.select("div.example div.example-output div.highlight-text"), rst.stem
        assert all(e.select_one(".example-file").get_text().endswith(".gd") for e in html.select("div.example"))


def test_gdscript_articles_are_numbered_in_order(page):
    titles = [a.get_text(strip=True) for a in page("gdscript/index.html").select("div.body li.toctree-l1 > a")]
    numbers = [t.split(" ", 1)[0] for t in titles]
    assert numbers == [f"1.{i}." for i in range(1, len(numbers) + 1)]


def test_index_has_hero_actions(page):
    html = page("index.html")
    assert html.select_one("div.site[data-page=index]") is not None
    links = html.select("div.hero-actions a:has(> span.button)")
    assert [a.get_text(strip=True) for a in links] == ["Начать с установки", "Первый скрипт"]
    assert links[0]["href"].endswith("intro/install.html")
    assert "button-primary" in links[0].select_one("span.button")["class"]
    assert "button-secondary" in links[1].select_one("span.button")["class"]


def test_buttons_share_one_style(site):
    import re

    css = (site / "_static" / "godot.css").read_text(encoding="utf-8")
    assert "sd-btn" not in css
    hover_rules = [body for selector, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css) if ":hover" in selector]
    assert not any("translate" in body for body in hover_rules)
    demo_button = page_html(site, "basics/script_and_node.html").select_one("button.godot-demo-start")
    assert {"button", "button-primary"} <= set(demo_button["class"])


def page_html(site, name):
    from bs4 import BeautifulSoup

    return BeautifulSoup((site / name).read_text(encoding="utf-8"), "html.parser")


def test_search_has_shortcut_hint(page):
    assert page("index.html").select_one("form.site-search kbd.site-search-key").get_text() == "/"


def test_theme_toggle(page):
    html = page("index.html")
    assert html.select_one(".site-sidebar-head button.site-theme-toggle") is not None
    head_scripts = [s.get_text() for s in html.head.select("script") if not s.get("src")]
    assert any("localStorage" in s and "dataset.theme" in s for s in head_scripts)


def test_sidebar_scroll_is_restored(page):
    html = page("index.html")
    script = html.select_one("aside.site-sidebar + script")
    assert script is not None
    assert "sidebar-scroll" in script.get_text()


def test_code_blocks_copy_on_click(site):
    script = (site / "_static" / "godot.js").read_text(encoding="utf-8")
    css = (site / "_static" / "godot.css").read_text(encoding="utf-8")
    assert "site-copyable" in script and "clipboard" in script
    assert "div.highlight.site-copied::after" in css
    assert "copybtn" not in css


def test_not_found_page(page):
    html = page("404.html")
    assert html.select_one("div.body h1").get_text(strip=True).startswith("GAME OVER")
    link = html.select_one("p.button-row a")
    assert link["href"].endswith("index.html")
    assert link.get_text(strip=True) == "Continue?"


@pytest.mark.parametrize(
    "name",
    [
        "script_and_node",
        "nodes_and_scenes",
        "node_access",
        "lifecycle",
        "vectors",
        "input",
        "export",
        "signals",
        "instancing",
    ],
)
def test_basics_articles_end_with_exercise(page, name):
    html = page(f"basics/{name}.html")
    exercise = html.select_one("div.exercise")
    assert exercise is not None
    assert exercise.select_one("p.exercise-label").get_text() == "Задание"
    solution = exercise.select_one("details.exercise-solution")
    assert solution.select_one("summary").get_text() == "Решение"


def test_theme_script_has_reading_features(site):
    script = (site / "_static" / "godot.js").read_text(encoding="utf-8")
    assert "done-pages" in script
    assert "site-term-tip" in script
    assert "ArrowLeft" in script and ".site-pager-prev" in script


def test_sidebar_opens_only_current_section(site, page):
    script = page("basics/vectors.html").select_one("aside.site-sidebar + script").get_text()
    assert "site-nav-open" in script and "site-nav-ready" in script
    css = (site / "_static" / "godot.css").read_text(encoding="utf-8")
    assert ".site-nav li.toctree-l1 > ul {\n  display: none;" in css
    current = page("basics/vectors.html").select("nav.site-nav li.toctree-l1.current")
    assert len(current) == 1


def test_footer_has_hiscore_slot(page):
    assert page("index.html").select_one("footer.site-footer p.site-hiscore") is not None


def test_theme_script_has_game_features(site):
    script = (site / "_static" / "godot.js").read_text(encoding="utf-8")
    for marker in ("site-achievement", "site-top", "site-mascot", "HI-SCORE"):
        assert marker in script
    assert "AudioContext" not in script


def test_brand_logo_and_favicons(site, page):
    html = page("basics/vectors.html")
    logo = html.select_one("a.site-brand img.site-brand-logo")
    assert logo["src"].endswith("_static/logo_32x32.svg")
    assert (site / "basics" / logo["src"]).resolve().is_file()
    assert html.select_one('link[rel="icon"]')["href"].endswith("favicon_32x32.png")
    touch = html.select_one('link[rel="apple-touch-icon"]')["href"]
    assert (site / "basics" / touch).resolve().is_file()


def test_game_section_has_intro(site, page):
    html = page("game/design.html")
    intro = html.select_one("div.game-intro")
    assert intro is not None
    images = intro.select("img")
    assert len(images) == 2
    for image in images:
        assert (site / "game" / image["src"]).resolve().is_file()


@pytest.mark.parametrize("name", ["intro/godot", "basics/script_and_node", "game/design", "game/project"])
def test_fun_fact_blocks(page, name):
    block = page(f"{name}.html").select_one("div.fun-fact")
    assert block is not None
    assert block.select_one("p.fun-fact-label").get_text() == "Интересное"


def test_game_demo_uses_project_pack(site, page):
    demo = page("game/maze.html").select_one("div.godot-demo")
    assert demo["data-src"].endswith("_static/godot/index.html?pack=maze-03_maze.pck")
    shell = (site / "_static" / "godot" / "index.html").read_text(encoding="utf-8")
    assert 'get("pack")' in shell
    pack = (site / "_static" / "godot" / "maze-03_maze.pck").read_bytes()
    assert b"global_script_class_cache" in pack, "pack was exported without class_name cache, rerun make demos"


def test_theme_stylesheet_loads_last(page):
    sheets = [link["href"].split("?")[0] for link in page("index.html").select('link[rel="stylesheet"]')]
    assert sheets[-1].endswith("godot.css"), sheets


def test_demo_hint_matches_demo_kind(page):
    game = page("game/maze.html").select_one("p.godot-demo-hint")
    assert game.select_one(".godot-demo-mouse") is None
    assert "камеры" not in game.get_text()
