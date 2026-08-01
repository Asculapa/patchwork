class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: %i[edit update destroy refresh]
  rate_limit to: 20, within: 1.minute, only: %i[new refresh],
    with: -> { redirect_to subscriptions_path, alert: "Slow down a little and try again in a minute." }

  def index
    @subscriptions = Current.user.subscriptions.includes(:source, :group).alphabetical
  end

  def new
    @query = params[:url].to_s.strip
    return if @query.blank?

    @candidates = SourceResolver.call(@query)
    @existing = Current.user.subscriptions.includes(:source)
      .joins(:source).where(sources: { url: @candidates.map(&:url) })
      .index_by { |subscription| subscription.source.url }
  rescue SourceResolver::Error => error
    @error = error.message
  end

  def create
    url = UrlNormalizer.call(params[:feed_url])
    return redirect_to(new_subscription_path, alert: "That feed address isn't valid.") unless url

    source = Source.visibility_shared.create_with(kind: Source.kind_for_url(url), title: params[:title].presence)
      .find_or_create_by!(url: url)
    @subscription = Current.user.subscriptions.new(subscription_params.merge(source: source, group: group_from_params))

    if @subscription.save
      SourceRefresher.call(source) if source.last_fetched_at.nil?
      redirect_to entries_path(subscription_id: @subscription.id), notice: "Subscribed to #{@subscription.title}."
    else
      redirect_to new_subscription_path(url: params[:feed_url]), alert: @subscription.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @subscription.update(subscription_params.merge(group: group_from_params))
      redirect_to subscriptions_path, notice: "Saved #{@subscription.title}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @subscription.destroy
    redirect_to subscriptions_path, notice: "Unsubscribed from #{@subscription.title}.", status: :see_other
  end

  def refresh
    count = SourceRefresher.call(@subscription.source)
    source = @subscription.source.reload

    if source.failing?
      redirect_back_or_to subscriptions_path, alert: "Couldn't refresh #{@subscription.title}: #{source.last_error}"
    else
      redirect_back_or_to subscriptions_path, notice: "#{@subscription.title}: #{helpers.pluralize(count, "new entry", plural: "new entries")}."
    end
  end

  private
    def set_subscription
      @subscription = Current.user.subscriptions.find(params[:id])
    end

    def subscription_params
      params.fetch(:subscription, {}).permit(:custom_title, :muted)
    end

    # An existing group from the select, or a new one typed into "New group".
    def group_from_params
      name = params[:new_group_name].to_s.squish.truncate(50)
      if name.present?
        Current.user.groups.find_by("LOWER(name) = ?", name.downcase) || Current.user.groups.create!(name: name)
      else
        Current.user.groups.find_by(id: params.dig(:subscription, :group_id))
      end
    end
end
