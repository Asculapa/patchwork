module Opml
  # OPML 2.0 export of all subscriptions, with groups as folders (FR-11.2).
  class Exporter
    def initialize(user)
      @user = user
    end

    def call
      by_group = @user.subscriptions.includes(:source, :group).alphabetical.group_by(&:group)
      groups = by_group.keys.compact.sort_by { |group| group.name.downcase }

      Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.opml(version: "2.0") do
          xml.head do
            xml.title "Patchwork subscriptions"
            xml.dateCreated Time.current.rfc2822
          end
          xml.body do
            groups.each do |group|
              xml.outline(text: group.name, title: group.name) do
                by_group[group].each { |subscription| outline(xml, subscription) }
              end
            end
            Array(by_group[nil]).each { |subscription| outline(xml, subscription) }
          end
        end
      end.to_xml
    end

    private
      def outline(xml, subscription)
        xml.outline({
          type: "rss", text: subscription.title, title: subscription.title,
          xmlUrl: subscription.source.url, htmlUrl: subscription.source.site_url
        }.compact)
      end
  end
end
