module Opml
  # Imports subscriptions from another reader's OPML export; folders become
  # groups (FR-11.1). New sources are fetched in the background.
  class Importer
    class Invalid < StandardError; end

    Result = Data.define(:added, :skipped, :failed)
    MAX_FEEDS = 1_000

    def initialize(user)
      @user = user
    end

    def call(xml)
      outlines = Nokogiri::XML(xml) { |config| config.strict.nonet }.xpath("//outline[@xmlUrl]")
      raise Invalid, "No feeds were found in this file." if outlines.empty?

      result = Result.new(added: [], skipped: [], failed: [])
      outlines.first(MAX_FEEDS).each { |outline| import(outline, result) }
      result
    rescue Nokogiri::XML::SyntaxError
      raise Invalid, "This file isn't valid OPML."
    end

    private
      def import(outline, result)
        title = outline["title"].presence || outline["text"].presence
        url = UrlNormalizer.call(outline["xmlUrl"])
        return result.failed << (title || outline["xmlUrl"]) unless url

        source = Source.visibility_shared.find_or_create_by!(url: url) do |new_source|
          new_source.kind = Source.kind_for_url(url)
          new_source.title = title
        end

        subscription = @user.subscriptions.find_or_initialize_by(source: source)
        return result.skipped << subscription.title if subscription.persisted?

        subscription.update!(group: group_for(outline))
        FetchSourceJob.perform_later(source) if source.last_fetched_at.nil?
        result.added << subscription.title
      end

      def group_for(outline)
        parent = outline.parent
        return unless parent.name == "outline"

        name = (parent["title"].presence || parent["text"].presence).to_s.squish.truncate(50)
        return if name.blank?

        @user.groups.find_by("LOWER(name) = ?", name.downcase) || @user.groups.create!(name: name)
      end
  end
end
