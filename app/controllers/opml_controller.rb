class OpmlController < ApplicationController
  MAX_FILE_SIZE = 1.megabyte

  def show
    send_data Opml::Exporter.new(Current.user).call,
      filename: "patchwork-#{Date.current.iso8601}.opml", type: "text/x-opml"
  end

  def new
  end

  def create
    file = params[:file]
    return redirect_to(new_opml_path, alert: "Choose an OPML file to import.") unless file.respond_to?(:read)
    return redirect_to(new_opml_path, alert: "That file is too big (1 MB max).") if file.size > MAX_FILE_SIZE

    @result = Opml::Importer.new(Current.user).call(file.read)
    render :result
  rescue Opml::Importer::Invalid => error
    redirect_to new_opml_path, alert: error.message
  end
end
