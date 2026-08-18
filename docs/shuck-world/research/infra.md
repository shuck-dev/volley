# Cloudflare Pages + R2 Deploy Plan for shuck.gg

Research date: 2026-06-15

## Site profile

- shuck.gg: pure static HTML/CSS, no build step, no framework, no Workers
- Embedded third-party widgets for dynamic features (hit counter, guestbook, webring)
- Custom domain with Cloudflare DNS already configured
- Deploy on `git push` to main

## 1. Deploying static site to Cloudflare Pages

### Git integration (recommended)

Cloudflare Pages connects directly to a GitHub repo. For a no-build-step site:

1. In Cloudflare Dashboard: Workers & Pages > Pages > Connect to Git
2. Select the GitHub repo and branch (main)
3. Build configuration: leave build command empty, set output directory to `.` (root)
4. Cloudflare auto-deploys on every push to main

No `wrangler.toml` or `_headers` file required for a basic site.

### Custom domain

1. In Pages project: Custom domains tab > Set up a custom domain
2. Add `shuck.gg` (apex), Cloudflare auto-provisions the CNAME record and SSL certificate
3. Add `www.shuck.gg` as a redirect to `shuck.gg` if desired
4. Both domains get automatic SSL via Cloudflare's Universal SSL

The Pages custom domain setup is a single click in the dashboard when the domain
is already on Cloudflare DNS. No manual DNS record creation needed.

## 2. R2 for static assets

Cloudflare R2 stores images, GIFs, screenshots, and other static assets outside the
git repo. This keeps clone times low and separates binary assets from text content.

1. In Cloudflare Dashboard: R2 > Create bucket (name: `shuck-assets`)
2. Settings > Public Access > Enable `r2.dev` subdomain (for development)
3. For production: Settings > Custom Domains > Connect `assets.shuck.gg`
4. Upload assets via Cloudflare Dashboard drag-and-drop, Wrangler CLI, or the S3-compatible API

### Access patterns

- Development: `https://pub-<hash>.r2.dev/filename.gif`
- Production: `https://assets.shuck.gg/filename.gif`

### CORS

For embedded assets loaded from a different origin:
```
[
  {
    "AllowedOrigins": ["https://shuck.gg"],
    "AllowedMethods": ["GET"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3600
  }
]
```

Set this in R2 bucket Settings > CORS if assets need crossorigin access.

## 3. GitHub Actions deploy

Cloudflare's native Git integration handles auto-deploy without a workflow file.
The optional `wrangler-action` provides more control if needed:

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write
    steps:
      - uses: actions/checkout@v4

      # No build step required for pure static HTML

      - name: Publish to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: shuck-gg
          directory: .
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

### R2 asset sync (optional)

If R2 assets are managed in-repo or via a separate directory:

```yaml
      - name: Sync assets to R2
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: r2 object put shuck-assets/assets/ --file assets/*
```

## 4. DNS record summary for shuck.gg

| Record | Type | Value | Purpose |
|--------|------|-------|---------|
| `shuck.gg` | CNAME | `shuck-gg.pages.dev` | Apex domain (Cloudflare flattens) |
| `www.shuck.gg` | CNAME | `shuck-gg.pages.dev` | www redirect |
| `assets.shuck.gg` | CNAME | `pub-<hash>.r2.dev` | R2 public bucket |

All three get automatic SSL via Cloudflare. The apex CNAME is flattened by Cloudflare's
CNAME flattening (RFC-compliant, no naked-domain issues).

## 5. Cost estimate

### Cloudflare Pages free tier
- Unlimited bandwidth
- 500 builds per month
- 1 build at a time (concurrent)
- 100 custom domains per project
- **Cost: $0**

### Cloudflare R2 free tier
- 10 GB storage per month
- 10 million Class A operations (reads) per month
- 1 million Class B operations (writes) per month
- **Cost: $0**

### Total hobby-scale cost
- **$0 per month** for both Pages and R2
- No Workers, no KV, no additional services needed
- The free tiers are generous enough for a game studio site with modest traffic

### Breakeven for paid tiers
- R2: $0.015/GB/month storage beyond 10 GB, $0.36/million reads beyond 10M
- Pages: $0.05 per additional build beyond 500/month
- At current scale, free tiers will not be exceeded

## 6. Migration notes

Cloudflare announced (April 2025) that Pages is being deprecated in favor of Workers.
For a pure static site with no Workers, this has no practical impact:
- Existing Pages projects continue to serve static content
- The Git integration still auto-deploys
- Workers migration is only required for projects that want dynamic routing or Workers features
- If Cloudflare eventually sunsets Pages entirely, migrating to Workers Static Assets
  (a single Worker that serves a directory of static files) is a one-line config change
