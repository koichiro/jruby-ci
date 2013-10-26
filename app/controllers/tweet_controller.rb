class TweetController < ApplicationController
  def post
    #raise NotFoundError.new unless request.remote_ip == "127.0.0.1"

    CommitLog.tweet

    render :text => "ok", :status => 200
  end
end
