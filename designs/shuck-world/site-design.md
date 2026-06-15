# Shuck World: site design

## Architecture

Single page (`index.html`) in a separate repo (`/home/josh/gamedev/shuck-gg/`).
No build step, no framework. Pure HTML 4-era tags. The Godot HTML5 build runs in
an `<iframe>` midway down the page.

Cloudflare Pages hosts the site. R2 holds the Godot export and large assets.

## Technical

**`_headers` file (Cloudflare Pages root):**
```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

Required for Godot's SharedArrayBuffer threading. The entire site gets these
headers. Third-party embeds (hit counter, guestbook, webring) use `<img>`,
`<iframe>`, and `<a>` tags which do not require CORP exceptions.

**Asset pipeline (future spike):**
- CI builds Godot HTML5 export
- Export uploaded to R2 (`assets.shuck.gg/volley/`)
- `index.html` references R2 URLs for game assets

## Page layout (6 zones)

**Zone 1: Header**
- Tiled starfield background (`bgcolor` attribute fallback to `#000020`)
- Under-construction animated GIF barricade spanning full width
- Pixel-art shuck.gg logo with flame borders (GIF)
- `<marquee>` with `<blink>` nested: "WELCOME TO SHUCK DOT GEE GEE -- HOME OF VOLLEY THE BEST PONG GAME ON THE INTERNET"
- "BEST VIEWED IN NETSCAPE NAVIGATOR 4.0 AT 800x600" badge below

**Zone 2: Game**
- Godot HTML5 export in `<iframe>` centered on page
- `[DOWNLOAD 4 WINDOWS]` link (points to itch.io Volley page)
- `[PLAY ON ITCH]` link
- Fake testimonial in italics: "this game changed my life" ~ some guy probably

**Zone 3: Guestbook**
- Smilie-decorated header: `.:*:.GUESTBOOK.:*:.`
- Atabook `<iframe>` embed
- "Sign my guestbook or i will be sad :(" above the iframe
- `[View]` `[Sign]` fake nav links

**Zone 4: Links and webrings**
- "PALS OF SHUCK" header with rainbow divider
- 88x31 button grid: shuck's badge + community badges (Silly City, MelonLand,
  Neocities, Yesterweb, etc.)
- Two webring rows: Indie Game Dev ring (Prev/Random/Next) and Silly City
  (Prev/Random/Next)

**Zone 5: Footer**
- Multiple hit counters: 88x31.lol badge + FeedPulse traffic widget + optional
  period-accurate webcounter.theraphit.com CGI counter
- "this page was hand-coded in notepad"
- "hosted on someone else's computer for free, like a digital squatter"
- (c) 2026 shuck games <<< don't steal plz
- Badge row: Netscape Now, Made With Notepad, Any Browser, Say No To Web3,
  Frames Are Good Actually
- `mailto:` link with spinning envelope GIF
- "Last updated: whenever josh feels like it"

## Assets to source

GIFs and graphics needed, all free to use or self-made:

| Asset | Use | Source |
|-------|-----|--------|
| Under construction barrier | Header barricade | GifCities / Neocities pubmats |
| Starfield tile background | Header zone bg | GifCities / similar |
| Flame border GIF | Logo surround | Custom or sourced |
| Spinning envelope | Email link | GifCities |
| Rainbow divider bar | Section separators | GifCities |
| "NEW!" stamp GIF | Fresh content markers | Neocities pubmats |
| Smiley set (6-8) | Guestbook decoration, marquee | Sourced from 90s smilie archives |
| Netscape Now badge | Footer | Standard 88x31 |
| Made With Notepad badge | Footer | Standard 88x31 |
| Any Browser badge | Footer | Standard 88x31 |
| Say No To Web3 badge | Footer | Yesterweb pubmats |
| Frames Are Good badge | Footer | Yesterweb pubmats |
| shuck.gg 88x31 badge | Links zone + embed for others | Custom: shuck green, pixel font |

## Colors and typography

**Body tag:**
```html
<body bgcolor="#000000" text="#00FF00" link="#FFFF00" vlink="#008000" alink="#FF0000">
```

**Fonts by zone:**

| Zone | Body font | Heading font |
|------|-----------|--------------|
| Header | `Comic Sans MS` | `Impact` |
| Game | `Verdana` | `Times New Roman` |
| Guestbook | `Comic Sans MS` | `Impact` (smilie decorated) |
| Links | `Arial` | `Impact` |
| Footer | `Courier New` | `Times New Roman` |

Multiple font zones is period-accurate. Comic Sans in guestbook and header zones
is the power move.

## Content in next iteration

As the game matures, the page adds: Volley screenshots (GIF gallery), partner
character intros, a devlog section below the game, and eventually narrative
content for players who go deeper.

## Spike deliverables

From the discovery open questions, the spike that follows this design should:
1. Wire CI to build + upload Godot HTML5 export to R2
2. Set up Cloudflare Pages project connected to the shuck-gg repo
3. Configure `_headers` and verify game loads with SharedArrayBuffer
4. Create shuck.gg 88x31 badge (pixel art, one afternoon)
5. Source and place all GIF assets
6. Register with a webring (Silly City or MelonLand Surf Club)
