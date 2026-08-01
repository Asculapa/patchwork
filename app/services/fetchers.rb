# Fetch strategies (§6.2). Each fetcher turns a source into a Fetchers::Result.
module Fetchers
  class Error < StandardError; end
  class Gone < Error; end

  Result = Data.define(
    :entries, :etag, :last_modified, :not_modified, :title, :site_url, :icon_url, :description,
    :permanent_url, :min_interval, :http_status
  ) do
    def initialize(entries: [], etag: nil, last_modified: nil, not_modified: false, title: nil, site_url: nil,
      icon_url: nil, description: nil, permanent_url: nil, min_interval: nil, http_status: nil)
      super
    end
  end
end
