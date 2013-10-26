class FetchController < ApplicationController
  def update
    #raise NotFoundError.new unless request.remote_ip == "127.0.0.1"

    CommitLog.fetch

    render :text => "ok", :status => 200
  end

end
