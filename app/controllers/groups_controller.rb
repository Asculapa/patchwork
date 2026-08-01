class GroupsController < ApplicationController
  before_action :set_group, only: %i[edit update destroy]

  def index
    load_groups
    @group = Current.user.groups.new
  end

  def create
    @group = Current.user.groups.new(group_params)

    if @group.save
      redirect_to groups_path, notice: "Created #{@group.name}."
    else
      load_groups
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to groups_path, notice: "Renamed to #{@group.name}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: "Deleted #{@group.name}. Its sources are now ungrouped.", status: :see_other
  end

  private
    def set_group
      @group = Current.user.groups.find(params[:id])
    end

    def group_params
      params.expect(group: [ :name ])
    end

    def load_groups
      @groups = Current.user.groups.alphabetical
      @source_counts = Current.user.subscriptions.group(:group_id).count
    end
end
