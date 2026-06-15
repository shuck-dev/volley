# Shuck World: site discovery

## Purpose and audience

Shuck World is the studio website for Shuck Games. It presents the studio identity
and anchors Volley's public presence. The game lives on players' desktops; the site
is where they first meet it.

**Primary audiences, in priority order:**

1. **Players.** Someone who heard about Volley. They land on the site and within 10
   seconds know what the game is, what it feels like, and how to get it. The site
   must feel like the game: warm, personal, slightly theatrical.
2. **Press and potential collaborators.** A press kit page that a journalist can scan
   in 30 seconds: key art, short description, studio bio, contact. Not hidden behind
   a blog or buried in marketing copy.
3. **The existing community.** Players who want to check the devlog, see what is new,
   or find the itch.io page again. The site is a hub, not a destination; the game is
   the destination.

**What the site is not:**

- Not a marketing funnel. No mailing-list capture, no pre-order, no "wishlist now."
  The game is free and always will be. The call to action is "download and play,"
  not "give us your email."
- Not a corporate portfolio. The about page names real people but does not read like
  a LinkedIn summary. The voice matches the game: kind, earnest, personal.

## 90s-theatrical direction

Volley's fiction lives in a 90s-desktop-computer frame: the game window, the cursor
overlay, the item art, the partner portraits. The website should feel like it belongs
to the same world, not like it was bolted on by a modern SaaS startup.

**The aesthetic is retro-computing, not retro-web-parody.** The difference:

- Retro-computing: chunky system fonts, bordered containers, a single accent color,
  deliberate whitespace, a slight frame-within-a-frame nesting. It reads as "this was
  made by people who used Win95" not "this is a Geocities joke."
- Retro-web-parody: animated GIFs, Comic Sans, starfield backgrounds, hit counters,
  under-construction banners. These are funny for about five seconds and exhausting
  after that.

**References that anchor the direction:**

- Classic game studio sites of the late 90s (id Software, Blizzard circa 1998, Looking
  Glass Studios): utilitarian, game-first, no fluff. Screenshots and download links.
- The "brutalist web" movement: raw HTML, system fonts, no frameworks, content over
  chrome. See brutalistwebsites.com and the motherfuckingwebsite.com lineage.
- Personal sites of the early 2000s blogging era: warm, voice-driven, a single
  person talking to you. The site feels authored, not generated.

**Concrete elements:**

- System font stack. No webfonts. The same font the player's OS uses for file dialogs.
  This ties the site to the desktop metaphor the game already uses.
- One accent color (the Volley green, roughly `#4a8`). Everything else is monochrome
  plus that one green. Links are green. Buttons are green. The game window is green.
- Bordered containers. A 1px solid border around cards, sections, the page itself.
  Not skeuomorphic window chrome, just clear visual boundaries.
- No rounded corners. The game's windows have square corners. The site matches.
- Small interactions feel deliberate. A hover state that changes the border color.
  A clicked state that inverts. Nothing animates for attention; things respond to
  touch.

**Anti-patterns to avoid:**

- Parallax scrolling, gradient hero sections, animated counters, cookie banners,
  newsletter popups. The site loads fast and gets out of the way.
- "Made with Webflow / Squarespace / Framer" badges. The site is hand-built and
  feels like it.
- Dark mode toggle. The game has two brightness states. The site picks one.

## Content pages

The minimum site is four pages, each scannable in under 15 seconds:

| Page | Content | Who it is for |
|------|---------|---------------|
| **Home** | Game name, one-line description, screenshot, download button | First-time visitors |
| **About** | Studio bio (2-3 sentences), team names, why we make this | Press, curious players |
| **Devlog** | Reverse-chronological posts, one paragraph each, irregular cadence | Community, returning visitors |
| **Press** | Key art, short description, studio contact, fact sheet | Journalists, creators |

Additional pages that can follow after the minimum ships: a dedicated Volley page
with deeper description and gameplay detail, a partners page introducing the
characters, and a gallery.

The home page is one screen tall. No scroll required to reach the download button.
The download button is the largest element on the page and is always visible.

## Build and host approach

**Static site, no framework.** The site is HTML, CSS, and a handful of images. No
JavaScript framework, no build step, no node_modules. A static-site generator
is acceptable if it produces static output with zero client-side JS (11ty and
Hugo are the leading candidates). The devlog is markdown files compiled at build
time; no CMS, no database.

**Host: Cloudflare Pages.** Free tier, auto-deploys from a git push to main.
Cloudflare R2 stores static assets (images, screenshots, trailers) outside the
repo to keep clone times low. R2 assets are fetched at build time via a script
or `wrangler r2 object get`.

**Deploy flow:**

```
push to main  →  GitHub Actions builds the site  →  deploys to Cloudflare Pages
                     (fetches R2 assets)              (instant, atomic swaps)
```

The GitHub Pages experiment (issue #826) is superseded by this approach:
Cloudflare Pages is faster, supports custom domains natively, and does not tie
the site to a GitHub organisation namespace.

**Domain:** shuck.world is registered and points to Cloudflare. DNS is already on
Cloudflare. Enabling Pages on the apex domain is a single toggle in the dashboard.

## Open questions for the spike

These are the things this discovery phase cannot answer. They become the spike's
agenda:

1. **Is the devlog worth the build complexity?** A blog means markdown processing,
   an RSS feed, date-based URLs. If the first six months of posts are irregular
   and short, skip the devlog until there is momentum. The home page + about +
   press kit ships faster and covers 90% of the audience needs.

2. **Where does the download point?** Direct binary download from R2, a link to
   the itch.io page, or both? Itch provides discovery, ratings, and an existing
   audience. Direct download is faster and stays on-brand. The spike should pick
   one as the primary call to action and use the other as a secondary link.

3. **How does the press kit handle game updates?** If the game changes every two
   weeks, the screenshots and trailer in the press kit go stale. Options: freeze
   the press kit to the initial release and update it at major milestones, or
   automate screenshot capture from the build pipeline. The spike picks one.

4. **Is the site part of the Volley repo or its own repo?** Keeping it in the
   Volley monorepo means shared CI, shared deploy, no new repo overhead. A
   separate repo means independent deploy cadence and cleaner ownership. The
   spike decides based on the build complexity (a 4-page HTML site weighs nothing
   either way).

5. **What is the actual R2 asset pipeline?** The sketch says "fetch at build time."
   Does that mean a shell script that runs `wrangler`, a CI step that downloads
   from a public R2 bucket, or embedding assets directly in the repo? The spike
   prototypes one path and names the tradeoffs.

6. **Accessibility baseline.** The site should be navigable by keyboard and
   readable by screen readers. The retro aesthetic must not compromise this.
   The spike should pick an accessibility standard (WCAG 2.1 AA) and verify the
   prototype against it.
