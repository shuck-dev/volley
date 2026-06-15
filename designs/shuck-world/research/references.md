# 90s-Era Game Studio Website References

Research date: 2026-06-15

## Common elements across 90s game studio sites

Game studio websites of the late 1990s shared a recognizable visual language. This
section catalogs the universal patterns rather than individual site screenshots.

### Layout

- **Left sidebar navigation, right content area.** Near-universal. The sidebar
  listed game sections (News, Downloads, Screenshots, FAQ, About) as text links
  or image buttons. Some sites used top nav with image-based buttons.
- **Fixed-width content**, typically 640-800px. No responsive design; the page was
  built for 800x600 or 1024x768.
- **Framesets** were common but not universal. A three-frame layout (header, nav,
  content) or two-frame (nav, content) appeared on roughly half of studio sites.
- **Table-based layouts** for everything else: `<table border="0" cellpadding="5">`
  for image galleries, feature grids, download links, and text formatting.

### Color and typography

- **Dark backgrounds with bright text** dominated. Black (`#000000`), dark gray
  (`#333333`), or a dark tiled background texture. Text was white, yellow, or
  a neon accent.
- **High-saturation accent colors**: lime green, electric blue, magenta, orange.
  These appeared on links, headers, dividers, and the "new" indicators.
- **System fonts only**: body text in Arial or Verdana, headings in Times New
  Roman or a pixelated display font rendered as a GIF image. No webfonts.
- **`<body>` tag color attributes** were standard: `bgcolor`, `text`, `link`,
  `vlink`, `alink` defined in the opening tag.

### Navigation and structure

- **Image-based buttons** for primary navigation, often with a hover-state swap
  (JavaScript `onmouseover`/`onmouseout` preloading two images).
- **"NEW!" GIFs** next to recently added content. Animated, attention-grabbing,
  usually a small yellow or red stamp.
- **Horizontal rules** (`<hr>`) separated sections, often styled with `noshade`,
  `size`, and `color` attributes to create a beveled 3D effect.
- **"Last updated" dates** at the bottom of pages. Hand-edited timestamps that
  showed the site was actively maintained.

### Content patterns

- **Screenshots in JPEG format** with visible compression artifacts. Often
  presented in a `<table>` grid with captions below each image.
- **Download pages** with plain text links to `.exe` files, often listing
  multiple mirrors. File sizes listed in KB or MB with download estimates for
  modem speeds.
- **"Under construction" pages** for sections that hadn't been built yet. Often
  featured an animated construction GIF and a promise of future content.
- **Press kit / "About Us" pages** with studio photos (scan of a printed
  photograph, low resolution), team bios, and contact emails.
- **FAQ pages** with the full text on one long page, questions as bold headers,
  answers in plain text below.

### Interactive features

- **Guestbooks** were standard social features. A separate page where visitors
  left their name, location, and a message. Often hosted by a third-party
  service (Bravenet, Lycos, Geocities guestbook widget).
- **Visitor counters** at the bottom of pages. Usually a CGI-generated GIF with
  LED-style digits showing the total visitor count.
- **Webrings** linked groups of related sites. Studio sites often participated in
  "game developer" or "independent games" webrings.
- **Email links** with `mailto:` and a spinning envelope GIF next to them.
- **Forum links** to external message boards or hosted forums (ezboard).

### Notable studio sites and their signatures

#### id Software (circa 1997-1998)
Original: http://www.idsoftware.com/ (Wayback Machine: Dec 1998)

- Black background. Plan file links (`.plan` files were developer diaries by
  Carmack, Romero, et al. -- a precursor to devlogs).
- Download section with shareware and retail versions.
- The "id" logo as a pixel-art GIF at top left.
- Dark, minimal, game-first. No fanfare.

#### Blizzard Entertainment (circa 1998)
Original: http://www.blizzard.com/ (Wayback Machine: Dec 1998)

- Dark blue/black background with gold/white text.
- News feed on the front page with dated entries.
- Game sections (StarCraft, Diablo, Warcraft) as top navigation tabs.
- Battle.net section with server status and ladder rankings.
- More polished than id, but still table-based and image-heavy.
- "What's New" section with the latest patches, tournaments, and news.

#### Looking Glass Studios (circa 1998-1999)
Original: http://www.lglass.com/ (Wayback Machine: Oct 1999)

- Burgundy/dark red background with tan text.
- System Shock 2 and Thief: The Dark Project as primary features.
- Press page with "Looking Glass Fact Sheet" (PDF).
- Job openings listed on the site (a common 90s studio site feature).
- Clean, professional, but unmistakably late-90s in HTML construction.

#### Bullfrog Productions (circa 1997-1998)
Original: http://www.bullfrog.co.uk/ (Wayback Machine: Dec 1997)

- Black background with bright green text.
- Top nav bar with game logos as image buttons.
- "Coming Soon" section with early screenshots of Dungeon Keeper.
- The Bullfrog logo as a distinct pixel-art badge.
- Darker, more personality-driven than id. The studio's humor showed.

#### 3D Realms (circa 1997-1999)
Original: http://www.3drealms.com/ (Wayback Machine: Oct 1999)

- Black background with red/amber text.
- Duke Nukem as the primary brand. Screenshots front and center.
- "The Apogee Legacy" section with company history.
- Download page with shareware links.
- One of the most-trafficked game studio sites of the era.

## Design patterns for shuck.gg

### What to copy from 90s studio sites

- Dark background with bright text
- Left sidebar nav (text or image-based)
- Table-based image galleries for screenshots and art
- `mailto:` contact with an animated email GIF
- "Last Updated" date in the footer
- Fixed-width layout (750-950px)
- A press kit / about page with team info and fact sheet
- A "News" or devlog section with dated entries

### What game studio sites did NOT do

- Flash intros or splash pages (these came later, late 1999+)
- Parallax scrolling, hero sections, or video backgrounds
- Cookie consent banners, newsletter popups, or GDPR notices
- Mobile-responsive layouts
- Social media links (Facebook, Twitter, Discord -- none existed yet in this form)

### What to adapt from 90s personal sites (Neocities/Yesterweb community)

Game studio sites were more restrained than personal homepages -- less
attention-grabbing animated GIFs, fewer marquees, more professional restraint.
But some elements from the personal web translate well:

- 88x31 buttons for community membership
- A guestbook for visitors to sign
- A webring for discovery
- A visitor counter for the authentic 90s feel
- A "Best viewed in" badge (playful but on-brand)

## Sources

- Wayback Machine (web.archive.org): id Software (Dec 1998), Blizzard (Dec 1998),
  Looking Glass Studios (Oct 1999), Bullfrog Productions (Dec 1997)
- Yesterweb.org site analysis (separate document: yesterweb-reference.md)
- Neocities community sites and webring culture (melonland.net, nightfall.city)
- Personal recollection and community archives of 1990s game studio web presence
