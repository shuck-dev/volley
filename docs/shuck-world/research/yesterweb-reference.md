# Yesterweb.org Design Reference Analysis

**Retrieval date:** 2026-06-15
**Source:** https://yesterweb.org/ (main site, CSS, community page, webring page, zine page, pubmats page, no-to-web3 page, sitemap)

---

## One-line answer

Yesterweb.org reads as an authentic Neocities-era revival site (circa 2020-2022) that correctly reproduces the structural feel of a late-90s personal website while diverging in predictable ways: CSS flexbox layout instead of tables, custom webfonts instead of pure system fonts, and a deliberate muted/readable color palette instead of the maximalist eye-strain of the actual 90s.

---

## 1. Layout Structure

### What it actually uses

The site uses **CSS flexbox** with a two-column layout: a fixed-width sidebar nav (300px) on the left and a fluid content area on the right. The structure is:

```
body
  div.headbar (full-width purple bar with SVG logo)
  div.flex (display: flex)
    nav (sidebar, 300px max-width, purple background, tiled sidebar image)
    main
      div.content (max-width 950px, black background, 80px padding)
```

The headbar is fixed-height (110px), purple, with the SVG logo left-aligned inside it. Below that, the flex row contains the nav and content area.

### What this means for authenticity

**Not using tables is the biggest tell.** An actual 90s site of this era would almost certainly use an HTML `<table>` for layout — either a `width="100%"` table with a fixed-width left column for navigation or a frameset. Yesterweb uses semantic HTML5 elements (`<nav>`, `<main>`) with CSS flexbox.

**However**, the sidebared two-column structure is visually period-accurate. The "left nav, right content" layout is the most common 90s personal site layout. The `max-width: 950px` on the content area also reads right — 90s sites were designed for 800x600 or 1024x768 screens, not infinite-width responsive layouts.

The responsive breakpoint at 981px collapses the sidebar into a horizontal nav row, which is a modern concession. 90s sites did not do responsive layouts.

### What shuck.gg should do differently

- **Use a `<table>` for layout** if authenticity is the priority. A `<table width="100%" cellpadding="10" cellspacing="0">` with a fixed-width left column is the most period-accurate choice. Alternatively, a `<frameset cols="200,*">` if you want to go full 1997.
- If avoiding tables for accessibility reasons (which is legitimate), the flexbox two-column with fixed sidebar is the next-best option. Avoid making it responsive below 800px — 90s sites assumed a minimum 800x600 viewport.
- Keep content column around 750-950px wide. Do not use fluid full-width layouts.

---

## 2. Font Choices

### What it actually uses

Two custom fonts loaded via `@font-face`:

- **Technique** (loaded from `/fonts/neuropol.ttf`) — used for nav links (`font-size: 22px`) and `<h1>` headings (`30px`). This is a geometric, slightly techno/cyberpunk face that evokes late-90s rave and cyberculture aesthetics.
- **Roboto** (loaded from local TTF files with weight variants) — used as the primary body font (`font-family: 'Roboto', sans-serif; font-size: 1.1em`).

Body text color is `#d1c7dd` (a muted lavender-gray) on black background. Headings (`h1`, `h2`) use CSS variable `--readable-bluish` which maps to `#6D9DD5`. Link color is `--readable-purple`: `#AA92E3`.

### What this means for authenticity

**Custom fonts are less authentic than system fonts.** A genuinely period 90s site would use the visitor's system fonts: `Arial`, `Helvetica`, `Verdana`, `Times New Roman`, `Georgia`, `Courier New`, or the dreaded `Comic Sans MS`. Fancy fonts were embedded as full-image headers or used the browser's `font-family` fallback chain.

**The Technique font is a deliberate 90s-revival choice.** Neuropol (the actual TTF name) was popular in the 90s cyber/techno scene, used on demo scene sites, rave flyers, and cyberpunk-adjacent personal pages. Using it only for nav and headings is a restrained choice — a more authentic 90s site might use it everywhere, including body text.

**Roboto is a dead giveaway of modernity.** Roboto was designed in 2011 for Android. It did not exist in the 90s. A period-accurate site would use `Verdana` or `Arial` for body text.

### What shuck.gg should do differently

- **Use system fonts only** for the most authentic feel: `font-family: Verdana, Geneva, Arial, Helvetica, sans-serif` for body text. `font-family: "Times New Roman", Times, serif` for a different vibe.
- **If custom fonts, keep them in display contexts only** (headings, nav, banners). Never use a post-2000 font (Roboto, Open Sans, Lato, etc.).
- Consider the actual 90s staple combinations:
  - Verdana 10pt/12pt for body, Arial or Impact for headings
  - Georgia for body, Times New Roman for headings (academic/gothic sites)
  - Comic Sans MS for personal/amateur pages (yes, it was ubiquitous)
- Font sizes in the 90s were smaller: 10pt-12pt for body, 14pt-18pt for headings. The 1.1em (roughly 17.6px) body text on yesterweb.org is larger than typical.

---

## 3. Color Palette

### What it actually uses

Defined via CSS custom properties:

| Variable | Hex | Usage |
|----------|-----|-------|
| `--green` | `#cad53c` | Accent highlights, list markers |
| `--pink` | `#C26AB7` | Window title backgrounds |
| `--purple` | `#56289b` | Nav sidebar background |
| `--dark-green` | `#45c83c` | Secondary accent |
| `--bluish` | `#6385AC` | h2 underline border |
| `--bg-color` | `#000000` | Page background |
| `--window-color` | `#000000` | Content area background |
| `--readable-purple` | `#AA92E3` | Link color |
| `--readable-bluish` | `#6D9DD5` | h1/h2 heading color |
| body text | `#d1c7dd` | Paragraph text |
| nav link | `#ffffff` (hover `#6385AC`) |

Background image: `/img/transparent-p.png` (a tiled PNG pattern, attached fixed).

The nav sidebar has a second background image: `/img/sidebar.png` (repeated on Y, 20% size, positioned top-right).

### What this means for authenticity

**The black background is period-accurate but the muted text is not.** Many 90s sites used black backgrounds with bright text. However, the typical 90s palette was much higher contrast and more saturated — think `#00FF00` green on black, `#FFFF00` yellow on black, `#FF00FF` magenta on black. The yesterweb palette is deliberately readable and accessible, which is a modern sensibility.

**The purple-based nav is authentic.** Deep purple was a common 90s web color, often paired with black. The tiled nav background image is also period-correct.

**Missing the classic 90s elements:** No `bgcolor="#000000"` attribute on the body tag (uses CSS instead). No `text`, `link`, `vlink`, `alink` attributes on `<body>`. These were standard in the 90s and would read as more authentic.

**The `alink`/`vlink` gap is significant.** A truly authentic 90s site would have distinct colors for visited links (`vlink`) and active links (`alink`), often a different shade or even a completely different color. Yesterweb only defines one link color (`--readable-purple`) with no visited/active distinction in the main CSS (though the no-to-web3 page uses a green link color via `--green`).

### What shuck.gg should do differently

- **Use `<body>` tag attributes** alongside CSS: `bgcolor`, `text`, `link`, `vlink`, `alink`. This is a strong signal of authenticity.
- **Define visited link color** differently from unvisited. Common pattern: links in bright color, visited links in a muted/darker version.
- **Consider a more saturated palette.** The muted lavender-gray body text on yesterweb is pleasant but not period-accurate. Brighter text (`#CCCCCC` or a specific color) reads more 90s.
- **Classic 90s palettes to consider:**
  - Black bg, bright green `#00FF00` text, yellow `#FFFF00` links, dark red `#800000` visited links
  - Navy `#000080` bg, white text, aqua `#00FFFF` links, purple `#800080` visited links
  - Dark grey `#333333` bg, light grey text, orange `#FF6600` links

---

## 4. 88x31 Button Culture

### What it actually does

The sidebar on the homepage contains a `.buttons` div that displays a collection of 88x31 badges:

1. A site badge: `<img src="https://yesterweb.org/img/button.png">` (standalone, no link — the "take me" button for others to link back)
2. A forum button linked to the forum
3. A zine button linked to the zine
4. A Mastodon button linked to their instance
5. A cafe button linked to the cafe
6. An animated GIF badge: `<img src="https://yesterweb.org/img/Yesterweb_88x31.gif">` (attributed to neonriser.neocities.org)
7. A "say no to web3" button (external, from auzziejay.com)
8. Stamp-style badges: "frames are an important tool" and "make your own website" buttons from lu.tiny-universes.net

The buttons are displayed as raw `<img>` tags, some wrapped in `<a>` links. They are not styled or containerized beyond the `.buttons` div with `max-width: 70%` and `margin-top: 40px`. No CSS grid or flex on the buttons themselves — they just flow inline.

On the homepage, the buttons are visible. The community page also embeds buttons inline within link cards (forum button shown as a link image).

### What this means for authenticity

**This is one of the most authentic elements.** The haphazard inline display of mismatched 88x31 buttons — some animated GIFs, some static PNGs, some linking externally, some linking internally — is exactly how they appeared on 90s personal sites. No attempt to align them, no grid, no fancy hover effects. They just sit there, varying sizes, varying formats.

**The animated GIF 88x31 is a key authentic element.** The `Yesterweb_88x31.gif` is a classic button: readable text on a patterned/colorful background, small enough to fit in a link collection.

**Missing element:** 90s button collections often included "made with" buttons (e.g., "Made with Notepad", "Best viewed in Netscape 4.0", "Get Firefox", "Powered by Perl", etc.). Yesterweb only has its own buttons and a few community stamps.

**The stamp badges** (the "frames are an important tool" and "make your own website" badges from external sites) are also authentic. Webrings and community badges were often reciprocity-based — you display my button, I display yours.

### What shuck.gg should do differently

- **Make 88x31 buttons a central visual feature.** Display them in an unordered, unaligned flow — do not grid them. Let them sit at different vertical offsets.
- **Include a mix of animated GIF and static PNG badges.**
- **Include your own "site button"** (the one others can use to link back) alongside community/affiliate badges.
- **Include at least one "made with" style badge** ("Made with Neovim", "Best viewed in Lynx", "Powered by Shuck", etc.) for authenticity.
- **Include a webring widget** if shuck participates in a webring. The classic widget has "Previous | Random | Next" links with the webring name. (Yesterweb had one but discontinued it — their webring page discusses this.)
- **Consider embedding the button collection in the sidebar or footer**, not hidden away. 90s sites often had a "buttons" page but also displayed a subset prominently on the homepage.

---

## 5. Navigation

### What it actually uses

A plain `<ul>` in the `<nav>` sidebar with seven text links:

```
Home | Community | Zine | Webring | Pubmats | Contact | Sitemap
```

Nav font is Technique at 22px, white, with `text-decoration: none` and `display: block` for full-width click area. Hover color shifts to `--bluish` (`#6385AC`).

Below the nav links, the `.buttons` div contains the 88x31 badge collection.

On mobile (< 981px), the nav collapses to a horizontal flex row across the full width of the page. The headbar with the logo is hidden.

### What this means for authenticity

**The simple text-based nav is authentic but the placement is not perfectly period.** In the 90s, navigation was often in the left sidebar (yes) but also frequently in a top banner/header row or as a table of contents on the index page. The left sidebar approach dates to roughly 1998-2001.

**What reads as modern:** The nav uses CSS `display: block` on `<a>` tags, which is fine, but 90s nav was more likely to use a table cell with a background color or a spacer GIF separating items.

**The mobile responsive collapse is definitively modern.** 90s sites did not have mobile layouts.

**Missing typical 90s nav elements:** No "Home" link with a house icon (common), no `target="_blank"` on external links (some used it, some didn't), no JavaScript rollover image buttons for nav items.

### What shuck.gg should do differently

- **Use a table-based nav layout** for the most authentic feel: `<table><tr><td><a href="...">Home</a></td></tr>...</table>` with background colors on cells.
- **Consider image-based nav buttons** with alt text, or text nav with a `<hr>` or `<br>` separator between items.
- **Do not make the nav responsive.** If you must, provide a separate mobile page (common 90s practice: "text-only version" or "mobile version" link).
- **Add a "Last updated" timestamp** on the page — a ubiquitous 90s footer element.
- **Include a mailto: link** in the nav or footer ("Email me" was standard).

---

## 6. Marquee or Animated Text

### What it actually uses

**None.** Yesterweb does not use `<marquee>`, `<blink>`, or any animated text elements.

### What this means for authenticity

**This is a significant missing element for full authenticity.** `<marquee>` was one of the most overused HTML elements of the late 90s, especially on personal Geocities/Angelfire pages. Nearly every 90s personal site had at least one scrolling marquee, often on the index page.

**Why they likely omitted it:** Aesthetics. Yesterweb targets a readable, accessible, modernized take on 90s web design. Marquee is garish and annoying. But its absence is noticeable when evaluating authenticity.

### What shuck.gg could do

- **Use a single `<marquee>` element on the homepage** for the most authentic feel. Something like a news ticker or a welcome message.
- **Use `<blink>`** for even stronger period authenticity, though it never worked in all browsers and is now removed from HTML entirely. CSS `text-decoration: blink` is an alternative (itself deprecated).
- **If you want the visual effect without the stigma:** Use a CSS animation that scrolls text horizontally, mimicking marquee behavior but with modern code.
- **Consider where to place it:** A scrolling news section in the sidebar or a welcome banner at the top of the content area.

---

## 7. Horizontal Rules, Borders, Dividers

### What it actually uses

- **`<hr>` style:** `border-top: 3px double var(--bluish); border-bottom: none` — a thin double-line separator in blue-grey.
- **Borders:** The "no-to-web3" page (which has its own CSS) uses `border: 1px solid white` on GIF images. Otherwise, very little use of borders on the main site.
- **Dividers:** The nav sidebar uses the sidebar background image (`/img/sidebar.png`) as a visual divider on the right edge. The content area has no left border or visual separation from the nav — the color difference between the purple nav and black content area provides the boundary.
- **Padding as divider:** The 80px padding on `.content` creates interior spacing. The headbar has 30px left padding.

### What this means for authenticity

**The `<hr>` style is close but not fully period.** A 3px double-line is a period-accurate `<hr>` style, but the color (`--bluish: #6385AC`) is subdued. 90s sites often used more garish `<hr>` colors or the `<hr noshade>` attribute for a plain 3D groove effect.

**The padding-based spacing is modern.** 90s sites used `<br>`, `<p>`, `<table cellpadding>`, and transparent spacer GIFs for layout spacing — not CSS `padding`.

**Missing the classic 90s divider elements:**
- **Spacer GIFs:** A 1x1 transparent GIF scaled to desired dimensions was the standard way to create whitespace.
- **Thematic rule images:** Colored bars, dotted lines, star-separators, or tiled rule images were common.
- **3D borders via table attributes:** `border="1" bordercolor="..."` on tables gave them a raised or inset look.

### What shuck.gg should do differently

- **Use `<hr>` with period-appropriate attributes:** `noshade`, `size`, `color`, `width`. Even just `<hr size="3" noshade>` reads more 90s than a CSS-styled double line.
- **Include a decorative divider image** between sections — a small GIF of a line, a row of asterisks, or a custom rule image.
- **Use table cellpadding and cellspacing for spacing** if using table-based layout. This is more authentic than CSS padding on divs.
- **Consider using `<br>` and non-breaking spaces `&nbsp;`** for spacing in some places rather than relying entirely on CSS margin/padding.

---

## 8. What Reads as Authentic 90s vs. Modern Pretending

### Reads as authentically 90s-era

1. **Two-column sidebar layout** with left nav and right content. This is the most common 90s personal site layout.

2. **The 88x31 button collection** in the sidebar. The haphazard inline display, the mix of animated GIF and PNG, the external-linked badges — this is genuinely period-accurate.

3. **Black background with pale/bright text.** While yesterweb's palette is more muted than the actual 90s, the black-background aesthetic is period-correct.

4. **The nav font (Technique/Neuropol).** Using a techno/cyberpunk display font for navigation and headings evokes the late-90s cyberculture aesthetic.

5. **Pink accent color** on the window title. The use of `#C26AB7` (pink/magenta) is period-accurate — pink, purple, and teal were the defining web colors of the late 90s.

6. **The `<details>`/`<summary>` elements** used on the pubmats page for expandable galleries. While `<details>` is an HTML5 element, the behavior mimics the "click to expand" sections common on 90s sites with JavaScript.

7. **The "last updated" style note** on the no-to-web3 page: `<small>This page was edited and expanded on 12/12/21.</small>`. "Last updated" timestamps were ubiquitous on 90s pages.

8. **The webring concept** itself — even though yesterweb's webring is discontinued, the webring page documents the cultural practice, which is a key 90s web institution.

### Reads as modern pretending to be 90s

1. **CSS flexbox layout** instead of HTML tables or frames. This is the single biggest tell.

2. **Roboto font** for body text. Roboto was designed in 2011. A period-accurate site would use Verdana, Arial, or Georgia.

3. **No `<body>` tag attributes** (`bgcolor`, `text`, `link`, `vlink`, `alink`). These were universal in the 90s.

4. **Responsive design** with a mobile breakpoint at 981px. 90s sites did not have responsive layouts.

5. **No `<marquee>` or `<blink>` elements.** Their absence is a modern aesthetic choice.

6. **The use of SVG for the logo.** 90s logos were GIF or JPEG, often with visible compression artifacts. An SVG logo is modern.

7. **Readability-conscious color choices.** The muted body text (`#d1c7dd`), readable link colors (`#AA92E3`), and overall restraint with saturation are modern sensibilities. An actual 90s site would use more saturated, more contrasting colors.

8. **CSS variables** for the color palette. CSS custom properties were not available until 2015.

9. **GoatCounter analytics** (`//gc.zgo.at/count.js`) — tracking scripts existed in the 90s (counter GIFs were common) but modern privacy-focused analytics scripts are a contemporary choice.

10. **No visitor counter** at the bottom of the page. The classic "You are visitor number X" counter GIF was a staple of 90s personal sites.

11. **No "Best viewed in" badge** — the "Best viewed in Netscape 4.0" or "Best viewed in Internet Explorer 5.0" badges were ubiquitous.

12. **No `target="_blank"` on all external links.** Yesterweb uses it inconsistently. 90s sites often either used it on all external links or relied on the user knowing to right-click > Open in New Window.

---

## Concrete Design Patterns for shuck.gg

### Must-have for authentic 90s feel

1. **Table-based layout** with a fixed-width left sidebar and fluid content area. Use `<table width="100%" cellpadding="10" cellspacing="0" border="0">`. This is the single highest-ROI change for authenticity.

2. **System fonts only.** Body: `font-family: Verdana, Arial, Helvetica, sans-serif`. Headings: `font-family: "Times New Roman", Times, serif` or `Impact`. No custom webfonts.

3. **Define all body tag colors:** `<body bgcolor="#000000" text="#00FF00" link="#FFFF00" vlink="#008000" alink="#FF0000">`. Adjust colors to shuck's palette.

4. **Include a visitor counter GIF** at the bottom of the page. Several free/retro counter services exist, or use a static "fake counter" image.

5. **At least one `<marquee>`** on the homepage for a news ticker or welcome message.

6. **88x31 button collection** in the sidebar or on a dedicated page. Include your own site button, plus 3-5 affiliate/community buttons. Mix animated GIF and PNG.

7. **"Last updated" timestamp** in the footer: `Last updated: June 15, 2026`.

8. **A `<hr>` with period styling** — either `noshade` or a thin colored rule.

### Strongly consider

9. A **"Best viewed in" badge** (e.g., "Best viewed in Netscape Navigator 4.0 at 800x600").

10. **Animated GIF elements** — a flaming skull, a spinning email icon, a "NEW!" stamp. These were the visual signature of 90s personal sites.

11. **Image-based nav buttons** with hover effects, or text nav separated by `<br>` and `|` pipes.

12. **A guestbook** page or at least a footer link to one. Guestbooks were a core 90s social feature.

13. **A `.sig` or `/~username` style URL path.** 90s personal sites were almost always at a subpath of a free host.

14. **A webring widget** if shuck joins a webring. The standard format is: `[<- Previous] [Random] [Next ->]` with the webring name and a link to the ring master.

### Avoid (modern tells)

15. **CSS flexbox or grid for main layout.** Use tables. CSS is fine for finer styling, but the page skeleton should be a table.

16. **Roboto, Open Sans, Lato, or any post-2000 font.** Stick to classic system fonts.

17. **SVG logos.** Use a GIF or JPEG logo with visible dithering/compression.

18. **Responsive or mobile layouts.** If you must support mobile, add a separate "text-only" page.

19. **Smooth gradients, border-radius, box-shadow, or any CSS3 effects** that weren't available in the 90s. Sharp corners, solid colors, and 3D bevels (via table attributes) are correct.

20. **Modern analytics scripts** like Google Analytics or GoatCounter. If you need analytics, use a retro-style "hit counter" GIF instead.

---

## Sources

- https://yesterweb.org/ — homepage, full HTML and CSS
- https://yesterweb.org/style.css — full stylesheet
- https://yesterweb.org/community/ — community page
- https://yesterweb.org/webring/ — webring page (discontinued)
- https://yesterweb.org/zine/ — zine page
- https://yesterweb.org/graphics/pubmats.html — pubmats gallery
- https://yesterweb.org/no-to-web3/ — separate CSS, tiled star GIF background
- https://yesterweb.org/sitemap.html — sitemap

All retrieved 2026-06-15.
