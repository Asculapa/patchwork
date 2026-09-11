# Development-only demo account with a few sources, so there's something to
# read right away. The scheduler fetches them within a minute of `bin/dev`.
if Rails.env.development?
  user = User.find_or_create_by!(email_address: "demo@patchwork.test") do |new_user|
    new_user.password = "password123"
  end

  tech = user.groups.find_or_create_by!(name: "Tech")
  videos = user.groups.find_or_create_by!(name: "Videos")

  {
    "https://rubyonrails.org/feed.xml" => tech,
    "https://world.hey.com/dhh/feed.atom" => tech,
    "https://medium.com/feed/airbnb-engineering" => tech,
    "https://www.youtube.com/feeds/videos.xml?channel_id=UC_x5XG1OV2P6uZZ5FSM9Ttw" => videos
  }.each do |url, group|
    source = Source.find_or_create_by!(url: url) { |new_source| new_source.kind = Source.kind_for_url(url) }
    user.subscriptions.find_or_create_by!(source: source) { |subscription| subscription.group = group }
  end

  puts "Demo account: demo@patchwork.test / password123"
end
