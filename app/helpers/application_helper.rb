module ApplicationHelper
  AVATAR_COLORS = 8
  # Tags and attributes allowed when rendering stored feed content. Content is
  # sanitised at ingest; this is a second pass at render time.
  CONTENT_ATTRIBUTES = ContentSanitizer::ATTRIBUTES + %w[rel target loading decoding referrerpolicy]

  def sidebar
    @sidebar ||= Sidebar.new(Current.user)
  end

  # `title` defaults to the source's own title, but callers rendering a
  # subscription should pass `subscription.title` so a custom title's letter
  # matches its label instead of staying stuck on the feed's original name.
  def source_avatar(source, title: source.display_title, css_class: "avatar")
    if source.icon_url.present?
      image_tag source.icon_url, alt: "", class: css_class, loading: "lazy", referrerpolicy: "no-referrer"
    else
      tag.span title.first.to_s.upcase, class: [ css_class, "avatar--letter", "avatar--c#{source.id.to_i % AVATAR_COLORS}" ],
        aria: { hidden: true }
    end
  end

  def nav_link(label, path, count: nil, css_class: nil)
    link_to path, class: [ "nav-link", css_class ] do
      safe_join([ tag.span(label, class: "nav-link__label"), (tag.span(count, class: "count") if count.to_i.positive?) ].compact)
    end
  end

  def time_ago(time)
    tag.time "#{time_ago_in_words(time)} ago", datetime: time.iso8601, title: l(time, format: :long)
  end

  # Rails' friendly zone names with IANA identifiers as values, plus the
  # user's current zone if it isn't one of them (e.g. detected by the browser).
  def time_zone_options(current)
    options = ActiveSupport::TimeZone.all.map { |zone| [ zone.to_s, zone.tzinfo.identifier ] }.uniq(&:last)
    return options if current.blank? || options.any? { |_, value| value == current }

    zone = ActiveSupport::TimeZone[current]
    options.unshift([ zone && zone.name != current ? "#{zone.name} (#{current})" : current, current ])
  end

  def entry_content(entry)
    sanitize entry.content_html, tags: ContentSanitizer::TAGS, attributes: CONTENT_ATTRIBUTES
  end

  def source_status(source)
    if source.paused?
      "Paused: #{source.last_error}"
    elsif source.error?
      "Stopped after repeated errors: #{source.last_error}"
    elsif source.failing?
      "Retrying: #{source.last_error}"
    elsif source.last_fetched_at.nil?
      "Waiting for the first fetch"
    else
      "Updated #{time_ago_in_words(source.last_fetched_at)} ago"
    end
  end
end
