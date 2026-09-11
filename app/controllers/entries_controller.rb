class EntriesController < ApplicationController
  OLDER_THAN = { "day" => 1.day, "week" => 1.week }.freeze

  def index
    @filter = EntryFilter.new(Current.user, params)

    if @filter.today?
      @sections = @filter.today_sections
    else
      @user_entries, @next_cursor = @filter.page(before: params[:before])
      render :page if turbo_frame_request?
    end
  end

  def show
    @user_entry = Current.user.user_entries.includes(entry: :source, subscription: :source).find_by!(entry_id: params[:id])
    @user_entry.mark_read!
  end

  def mark_all_read
    filter = EntryFilter.new(Current.user, params)
    scope = filter.scope.unread
    scope = scope.where(published_at: ...OLDER_THAN.fetch(params[:older_than]).ago) if OLDER_THAN.key?(params[:older_than])

    count = UserEntry.where(id: scope.select(:id)).update_all(read_at: Time.current, updated_at: Time.current)
    redirect_to entries_path(filter.to_params), notice: "Marked #{helpers.pluralize(count, "entry")} as read."
  end
end
