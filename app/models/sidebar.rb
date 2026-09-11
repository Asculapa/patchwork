# Navigation data for the reading sidebar: groups, sources and unread counts.
class Sidebar
  def initialize(user)
    @user = user
  end

  # [[group, subscriptions], …] with named groups first and ungrouped sources last.
  def sections
    @sections ||= begin
      by_group = @user.subscriptions.includes(:source, :group).alphabetical.group_by(&:group)
      @user.groups.alphabetical.map { |group| [ group, by_group.fetch(group, []) ] } + [ [ nil, by_group.fetch(nil, []) ] ]
    end
  end

  def empty?
    sections.all? { |_, subscriptions| subscriptions.empty? }
  end

  def unread_count_for(subscription)
    unread_counts[subscription.id].to_i
  end

  def unread_count_for_group(subscriptions)
    subscriptions.reject(&:muted?).sum { |subscription| unread_count_for(subscription) }
  end

  def today_count
    @today_count ||= @user.user_entries.unread.unmuted.today.count
  end

  def unread_count
    @unread_count ||= @user.user_entries.unread.unmuted.count
  end

  def starred_count
    @starred_count ||= @user.user_entries.starred.count
  end

  private
    def unread_counts
      @unread_counts ||= @user.user_entries.unread.group(:subscription_id).count
    end
end
