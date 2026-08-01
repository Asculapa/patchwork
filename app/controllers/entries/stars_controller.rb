module Entries
  class StarsController < ApplicationController
    include UserEntryScoped

    def create
      @user_entry.star!
      render_entry_update
    end

    def destroy
      @user_entry.unstar!
      render_entry_update
    end
  end
end
