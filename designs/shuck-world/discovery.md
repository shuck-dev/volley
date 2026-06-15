# Shuck World: site discovery

## Purpose and audience

Shuck World is the studio website for Shuck Games. It presents the studio
identity and anchors Volley's public presence. The game lives on players'
desktops; the site is where they first meet it.

**Primary audiences, in priority order:**

1. **Players.** Someone who heard about Volley. They land on the site and within
   10 seconds know what the game is, what it feels like, and how to get it.
2. **Press.** A press kit page scanable in 30 seconds: key art, short
   description, studio bio, contact.
3. **Community.** Players checking the devlog, finding the itch.io page, or
   signing the guestbook. The site is a hub; the game is the destination.

**What the site is not:**

- Not a marketing funnel. No mailing-list capture, no pre-order. The call to
  action is "download and play," not "give us your email."
- Not a corporate portfolio. The about page names real people but does not
  read like a LinkedIn summary. The voice is kind, earnest, personal.

## Full 90s-era authenticity

The site must read as if it was built in 1998. Not a parody, not a modern site
with retro styling. If someone loads shuck.gg and does not wonder whether they
stepped into a time machine, we are not trying hard enough.

This direction is anchored in two research docs:

- `research/references.md` loops through 90s game studio site patterns (id
  Software, Blizzard, Looking Glass, Bullfrog, 3D Realms)
- `research/yesterweb-reference.md` analyzes a Neocities-era revival site with
  a tiered checklist of what to copy and what to avoid

**Must-have elements for authentic 90s feel:**

1. **Table-based layout.** A `<table width="100%">` with a fixed-width left
   sidebar and fluid content area. The single highest-ROI choice.
2. **System fonts only.** Body: `Verdana, Arial, Helvetica`. Headings: `Times
   New Roman` or `Impact`. No custom webfonts, no Roboto, no Open Sans.
3. **All body tag color attributes.** `<body bgcolor="#000000" text="#00FF00"
   link="#FFFF00" vlink="#008000" alink="#FF0000">`. Adjust to shuck's palette.
4. **A visitor counter GIF** at the bottom of pages. `88x31.lol` provides a retro
   badge via a single `<img>` tag (see embeds research).
5. **At least one `<marquee>`** on the homepage for a news ticker or welcome.
6. **88x31 button collection** in the sidebar or on a dedicated Links page.
   Include shuck's own button plus community and affiliate badges.
7. **"Last updated" timestamp** in the footer.
8. **`<hr>` dividers with period styling** (`noshade`, beveled).

**Strongly consider:**

9. A "Best viewed in" badge (e.g., "Best viewed in Netscape Navigator 4.0 at
   800x600").
10. Animated GIF elements: a spinning email icon, a "NEW!" stamp.
11. Image-based nav buttons or text nav separated by `|` pipes.
12. A guestbook page (see embeds research: Atabook via `<iframe>`).
13. A webring widget if shuck joins a webring (webri.ng recommended).

**Modern tells to avoid:**

14. CSS flexbox or grid for main layout (use tables).
15. Any post-2000 font (Roboto, Open Sans, Lato).
16. SVG logos (use a GIF or JPEG with visible compression).
17. Responsive or mobile layouts (90s sites assumed 800x600 minimum).
18. CSS3 effects: `border-radius`, `box-shadow`, smooth gradients, CSS variables.
19. Google Analytics or modern scripts (use the hit counter instead).

Full pattern list with analysis: `research/yesterweb-reference.md`.

## Content pages

The site has six pages. The home page is one screen tall and puts the download
button front and center.

| Page | Content | Who it is for |
|------|---------|---------------|
| **Home** | Game name, one-liner, screenshot, download button, marquee news ticker | First-time visitors |
| **About** | Studio bio, team names, why we make Volley | Press, curious players |
| **Devlog** | Reverse-chronological posts, one paragraph each, irregular cadence | Community |
| **Press** | Key art, fact sheet, studio contact, downloadable screenshots | Journalists |
| **Guestbook** | Embedded Atabook guestbook via `<iframe>` | Community |
| **Links** | 88x31 button collection, webring nav (Prev, Next, Random) | Community |

The guestbook and links pages add network effects: visitors navigate between
88x31 badges, leave a message, join the webring.

## Embedded services

Live 90s-era elements served by third-party embeds. No backend code required.
Full research: `research/embeds.md`.

| Feature | Service | Embed method |
|---------|---------|-------------|
| Hit counter | 88x31.lol | `<img>` tag, no JS |
| Guestbook | Atabook | `<iframe>`, no JS |
| Webring | webri.ng | `<a>` tags, no JS |

All three embed in pure static HTML. No JavaScript requirement, no custom
backend, no build step. The embed URLs can be swapped if any service goes down.

## Build and host

Full deploy plan: `research/infra.md`.

**Static HTML, no build step.** The site is hand-written HTML, CSS, and images.
No framework, no SSG, no node_modules.

**Host: Cloudflare Pages.** Connects to the GitHub repo. Auto-deploys on `git
push` to main. Custom domain `shuck.gg` with automatic SSL. No Workers, no KV.

**Assets: Cloudflare R2.** Images, GIFs, screenshots stored outside the repo.
Served via `assets.shuck.gg` (R2 custom domain, public bucket). Sync at deploy
time via `wrangler r2 object put`.

**Cost: $0/month.** Both Pages and R2 free tiers cover the site's needs:
unlimited bandwidth, 500 builds/month, 10 GB storage, 10M reads/month.

## Open questions for the spike

1. **Devlog or skip?** A blog means date-based URLs, an RSS feed, and a content
   cadence. If posts will be irregular, skip it initially. Minimum pages ship
   faster.

2. **Download target?** Itch.io (discovery, ratings, existing audience) or
   direct R2 binary download (on-brand, fast). Pick one as primary.

3. **Press kit freshness.** Game screenshots change every two weeks. Options:
   freeze at launch and update at milestones, or automate from CI.

4. **Repo location?** In the Volley monorepo (shared CI) or its own repo
   (independent deploy cadence). A 6-page HTML site weighs nothing either way.

5. **Accessibility.** The 90s aesthetic must not compromise keyboard navigation
   or screen reader access. Pick a standard (WCAG 2.1 AA) and verify the
   prototype. Note: table-based layouts and body tag colors do not inherently
   violate accessibility; they require testing.
