Session summary — project: trail-maps (Next.js 15 App Router, Mapbox GL)

Built offline caching of map tiles so hikers can view a downloaded region without signal.
Registered a service worker; discovered that the App Router does not register one for you
— it has to be done from a client component with `navigator.serviceWorker.register` after
mount, or it never installs in production builds. First implementation cached every tile
request; on an iPhone the cache stopped growing at roughly 50 MB because Safari caps Cache
Storage per origin, so I added LRU eviction keyed by last access. Also noticed Mapbox tile
URLs carry the `access_token` query parameter, which meant the token was being persisted in
Cache Storage on the device; I strip the query string from the cache key and re-append the
token on fetch. Six files changed, 14 new tests, `pnpm test` green, deployed to preview.
The user wants to look at region-size estimates next week.

<!-- MUST-INCLUDE:
- Safari's ~50 MB Cache Storage cap forcing eviction
- Mapbox tile URLs carry the access token, so naive caching persists the token
-->
<!-- MUST-EXCLUDE:
- "six files changed", "14 tests", file names
- next week's task as a learning
-->
