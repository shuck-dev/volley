# 90s-Era Embed Services for shuck.gg

Research date: 2026-06-15
Branch: feature/952-shuck-world-discovery

Three categories of retro web embed that work in pure static HTML today.
All services listed are live and actively maintained as of June 2026.

---

## 1. Hit Counters

### 88x31.lol — recommended

https://88x31.lol/

Single `<img>` tag, no JavaScript, no cookies. Generates a retro 88x31 pixel badge
with the visitor count rendered directly into the graphic. Choose from 11 color
schemes (Light, Dark, White, Green, Blue, Amber, Purple, Pink, Cream, Red, Teal,
Sepia). The badge shows today's unique count and an all-time total.

Privacy: uses bloom filters for unique-visitor dedup (reset daily), no sessions,
no PII stored. Hosted by an indie web developer who built it because even Google
doesn't offer this anymore.

Embed: `<img src="https://88x31.lol/count/yourdomain.com" alt="Hit Counter">`

Risk: Single-developer project. Launched early 2026. Active development visible
on the site (leaderboard, style choices). No monetisation model visible. Could
vanish, but the embed is trivial to swap.

### FeedPulse Hit Counter

https://feed-pulse.com/free-hit-counter

Modern take on the classic Geocities 1996 visitor counter. 6 themes from
LED-pixel nostalgia to minimal-modern flat. Server-side bot filter, tamper-proof
MutationObserver. No signup, paste and go.

FeedPulse also offers a live traffic feed widget (Feedjit-style), a visitors
globe, and an online-now counter. The whole suite is free with a small attribution
badge.

Embed: the generator produces either an `<img>` or a `<script>` snippet depending
on the widget. The hit counter itself works as an image tag.

Risk: FeedPulse launched in 2026 but has a broader widget ecosystem (17 widgets)
and a blog with regular updates. More institutional feel. The attribution badge
requirement is stable (they rely on it for discovery).

### webcounter.theraphit.com — the period-accurate choice

https://webcounter.theraphit.com/freecounter-en.html

Runs the actual `wwwcount 2.2` CGI program from the 1990s, hosted by a French
personal homepage that has been online since 1997. The counter image is produced
by a genuine 90s CGI binary called remotely.

Embed: `<img src="https://webcounter.theraphit.com/cgi-bin/Count.cgi?df=your-unique-filename.dat">`

The `.dat` filename must be unique across all users. The counter auto-creates on
first request. You can set a starting value with `&st=1000`.

Risk: Single-person operation (TheRaphit), running since 1997. The site is
stable (same admin for 29 years) but the CGI infrastructure is ancient and the
admin's priorities may shift. The counter program is also available for download
if you want to self-host.

### hitscounter.dev

https://hitscounter.dev/

Badge-style counter (icon + label + today + total). Supports flat, square,
for-the-badge, social, and plastic styles. Created as a replacement for the
defunct hits.seeyoufarm.com. Tracks 15,000+ URLs and 37M hits.

Embed: `<img src="https://hitscounter.dev/api/count?url=YOUR_URL&style=...">`

Risk: Active project, open to issue reports. The stats page is transparent about
scale. Lower risk than the solo projects above.

---

## 2. Guestbooks

### Atabook — recommended

https://atabook.org/

Purpose-built guestbook service created in 2024 after 123guestbook shut down.
Free tier: one guestbook at `yourname.atabook.org`, full customization of
colors, fonts, backgrounds. Moderation queue, IP banning, smileys, UBB codes,
reply capability, email notification on new messages, VPN/proxy blocking.

Embed: `<iframe src="https://yourname.atabook.org" width="100%" height="700"></iframe>`

The iframe embed works reliably. Some users reported Firefox X-Frame-Options
issues in 2024, but these appear to be resolved.

Supporter plan ($): custom CSS, custom domain, up to 5 guestbooks, no
attribution, HTML sections for analytics/widgets.

Risk: The service explicitly positions itself as the replacement for the
now-defunct 123guestbook. Single-developer but actively maintained. Has a
revenue path (supporter plan) which improves longevity. The free tier shows ads
(none visible currently per the features page) and attribution.

### HTML Comment Box

https://www.htmlcommentbox.com/

Comment/guestbook widget used widely across Neocities and indie web. Uses a
`<script>` tag (not pure img/iframe, but minimal JavaScript -- no framework, no
dependencies). Google account required for moderation. Anonymous posting
allowed. Threaded replies, like/flag, RSS feed.

Can be relabelled as a guestbook via the `hcb_user` L10N config (change
"Comments" to "Guestbook", "Comment" to "Sign").

Embed: copy-paste a `<script>` snippet from the site. Works on static HTML,
Jekyll, Hugo, Astro, SvelteKit, etc.

Risk: Operated since at least 2011. Free tier exists alongside paid tiers. The
company behind it (same as the other HTML widgets on the site) appears stable.
The free tier includes a small attribution.

### guestbooks.meadow.cafe

https://guestbooks.meadow.cafe/

Open-source guestbook service by Meadow (Codeberg: meadowingc/guestbooks).
Written in Go, can be self-hosted. The hosted instance provides embeddable
guestbooks via iframe.

Embed: `<iframe src="https://guestbooks.meadow.cafe/guestbook/YOUR_ID" width="100%" height="700"></iframe>`

Risk: The service suffered a data loss in early 2026 (backup from Sept 2025 was
restored, accounts created after that date were lost). The admin is transparent
about this and calls the service a WIP. Self-hosting is the reliable path --
Docker and binary builds are documented.

### guestbooks.kamiscorner.xyz

https://guestbooks.kamiscorner.xyz/

Another indie guestbook service (by Kami). Invite-only (email the admin). iframe
embeds with no JavaScript required. Custom CSS, manual approval, data export
(JSON, CSV, HTML), IP banning, 2FA, audio/image captchas, markdown descriptions.

Embed: iframe (invite required to get the URL).

Risk: Brand new (Feb 2026), invite-gated. Very small scale. The admin is
responsive and publishes updates. Too early to rely on as a primary service.

---

## 3. Webrings

### How webrings work

A webring is a circular chain of related websites. Each member site displays
navigation links: Previous, Next, and often Random. Clicking Next takes you to
the next site in the ring; clicking through repeatedly loops you back to your
starting point. Rings are curated by an admin who maintains the member list and
ordering.

In the 90s, this was usually a CGI script on the admin's server that redirected
based on the current site's position in a ring file. Modern alternatives use
static redirect pages, Cloudflare Workers, or web components that fetch ring
data from JSON.

### webri.ng — recommended for hosting your own ring

https://webri.ng/

Hosted platform for creating and managing webrings. No infrastructure to run.
You create a ring, add member sites through a control panel, and get short URLs
for Previous, Next, Random, and Index navigation. Members embed these as plain
anchor tags -- no JavaScript required.

The service has been running for 4+ years (birthday April 2026). Free forever.
Source code is available (TypeScript, PostgreSQL).

Embed for members:
```html
<a href="https://webri.ng/prev?via=https://shuck.gg">Previous</a>
<a href="https://webri.ng/random?via=https://shuck.gg">Random</a>
<a href="https://webri.ng/next?via=https://shuck.gg">Next</a>
```

You can also design your own navigation using 88x31 badges linking to these
URLs, which is the period-appropriate approach.

Risk: Stable service (4+ years), open source, single developer but responsive.
Random link avoids the issue of a missing neighbour breaking the chain.

### OpenRing (Cloudflare Workers)

https://github.com/Thereallo1026/openring

Self-hosted webring API on Cloudflare Workers (free tier). Stores member sites
in Cloudflare KV. Provides REST endpoints for next/prev/random/list. Members
embed plain anchor tags:

```html
<a href="https://your-worker.workers.dev/prev?url=https://shuck.gg&redirect=true">Previous</a>
<a href="https://your-worker.workers.dev/next?url=https://shuck.gg&redirect=true">Next</a>
<a href="https://your-worker.workers.dev/random">Random</a>
```

Zero JavaScript required for members. Admin API for adding/removing sites.

Risk: You deploy and maintain it yourself. Cloudflare Workers free tier is
generous. The project is MIT-licensed and actively maintained (Jan 2026).

### Webring Starter Kit (maxboeck/webring)

https://github.com/maxboeck/webring

Eleventy + Netlify boilerplate for hosting a webring. Members are defined in
JSON. Generates a central directory, /prev /next /random redirect pages, and an
embed code with a web component. Has a SVG ring map. Good for a community-run
ring with a curated directory page.

Embed uses a web component with plain-HTML fallback:
```html
<webring-banner>
  <p>Member of <a href="https://your-ring.com">Ring Name</a></p>
  <a href="https://your-ring.com/prev">Previous</a>
  <a href="https://your-ring.com/random">Random</a>
  <a href="https://your-ring.com/next">Next</a>
</webring-banner>
<script async src="https://your-ring.com/embed.js" charset="utf-8"></script>
```

Risk: You host it. Netlify free tier covers it. The project is mature (forked
and maintained, blog post explains the approach).

### Existing indie web communities to connect to

shuck.gg could join existing game-dev or indie-web rings rather than starting
one. Some relevant communities:

- **MelonLand Surf Club** (melonland.net) -- community for indie web /
  Neocities-adjacent creators. Has guilds with built-in webring functionality.
- **Neo-neighborhoods** -- themed communities within Neocities.
- **nightfall.city** -- a "city of websites" community.
- **Bucket Webring** -- for makers and creators.
- **Silly City** -- active webring community, visible in Atabook guestbook
  messages as people navigate between members.

The full list of active webrings is maintained at:
https://tuffgong.nekoweb.org/webring-list.html

---

## Summary table

| Service | Type | Embed method | No JS? | Risk | Recommended for |
|---------|------|-------------|--------|------|-----------------|
| 88x31.lol | Hit counter | `<img>` | Yes | Low-Med | Primary counter |
| FeedPulse | Hit counter | `<img>` or `<script>` | Yes (img) | Low | Live traffic widget |
| webcounter.theraphit.com | Hit counter | `<img>` (CGI) | Yes | Low (29yr site) | Period accuracy |
| hitscounter.dev | Hit counter | `<img>` | Yes | Low | Modern badge style |
| Atabook | Guestbook | `<iframe>` | Yes | Low-Med | Primary guestbook |
| HTML Comment Box | Guestbook | `<script>` | No (minimal JS) | Low | Lightweight comments |
| meadow.cafe Guestbooks | Guestbook | `<iframe>` | Yes | Med (data loss history) | Self-hosted path |
| webri.ng | Webring | `<a>` tags | Yes | Low | Hosting your own ring |
| OpenRing | Webring | `<a>` tags | Yes | Low (self-host) | DIY ring on CF Workers |
| Webring Starter Kit | Webring | `<a>` + web component | Yes (fallback) | Low (self-host) | Full directory + ring |

## Recommendation for shuck.gg

**Hit counter:** 88x31.lol for the main retro badge. Consider adding the
FeedPulse live traffic widget for the "behind the scenes" or about page.

**Guestbook:** Atabook for a reliable, embeddable guestbook that looks the part.
If self-hosting is preferred, fork meadow.cafe's open-source Go binary.

**Webring:** Join an existing indie-web ring (Silly City, MelonLand Surf Club)
rather than starting a new one, at least initially. Use webri.ng if you want to
create a shuck.gg-specific game dev ring later.

All three embeds can sit on a plain static HTML page with no build step, no
database, and no JavaScript requirement for core functionality.
