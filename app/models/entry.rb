# One news item, stored once per source and shared by all its subscribers.
class Entry < ApplicationRecord
  belongs_to :source
  has_many :user_entries, dependent: :delete_all

  def youtube_video_id
    media["video_id"].presence
  end

  def thumbnail_url
    image_url.presence || (youtube_video_id && "https://i.ytimg.com/vi/#{youtube_video_id}/hqdefault.jpg")
  end
end
