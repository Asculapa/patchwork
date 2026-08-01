# Patchwork

A personal news reader. Follow blogs, YouTube channels, Medium authors, Substacks and subreddits, and read them all in one place, grouped the way you like.

See [TECHNICAL_REQUIREMENTS.md](TECHNICAL_REQUIREMENTS.md) for the design and the phase plan. **Phase 1, the core feed reader, is implemented.** Email ingestion is Phase 2.

## Requirements

- Ruby 3.2 (see `.ruby-version`) and Bundler
- SQLite 3
- Internet access (feeds are fetched live)

## Run locally

```sh
bin/setup --skip-server   # install gems, create and seed the databases
bin/dev                   # start the app on http://localhost:3000
```

`bin/dev` runs Puma with the Solid Queue supervisor inside it, so one process does everything. A recurring job checks every minute for sources that are due and fetches them in the background.

In development the seed creates a demo account, **demo@patchwork.test / password123**, with four sources (Rails blog, DHH, Airbnb Engineering on Medium, and the Google for Developers YouTube channel). You can also create your own account at `/registration/new`.

To start over with a fresh development database: `bin/rails db:reset`.

## Things to try

- **Add source**: paste `rubyonrails.org`, `@GoogleDevelopers`, a YouTube video link, `medium.com/@someone`, `name.substack.com` or `reddit.com/r/ruby`. Patchwork finds the feed and previews the latest items before you subscribe.
- **Today** shows unread entries from the last 24 hours, grouped by group and then by source.
- Use the ☆ and ● buttons to star an entry or toggle it read/unread without leaving the list. Opening an entry marks it as read.
- **Import / export** moves subscriptions to and from other readers as OPML.
- **Sources** shows each source's health. **Refresh** fetches a source right away.

## Tests and checks

```sh
bin/rails test     # unit and integration tests (no network: HTTP is stubbed with WebMock)
bin/rubocop        # style
bin/brakeman       # security scan
bin/ci             # all of the above, as CI runs them
```

## Where things live

| Path | What |
|---|---|
| `app/services/source_resolver.rb` (+ `source_resolver/`) | URL → feed discovery (YouTube, Medium, Substack, Reddit, autodiscovery, common paths) |
| `app/services/http/safe_client.rb` | The only outbound HTTP client: SSRF protection, redirects, size and time limits |
| `app/services/feed_document.rb`, `fetchers/` | Parse RSS/Atom/JSON Feed into normalised entries |
| `app/services/ingest/entries.rb` | Store entries once per source and fan them out to subscribers |
| `app/services/source_refresher.rb`, `app/jobs/` | Scheduling: adaptive intervals, conditional GET, error backoff |
| `app/services/content_sanitizer.rb` | Allowlist sanitiser for feed HTML |
