class LegalController < ApplicationController
  allow_unauthenticated_access
  layout "legal"

  def privacy
  end

  def terms
  end
end
