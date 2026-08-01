# What every fetch strategy produces, whatever the item's origin (§6.2).
NormalizedEntry = Data.define(
  :guid, :url, :title, :author, :summary, :content_html, :image_url, :published_at, :media, :fingerprint
)
