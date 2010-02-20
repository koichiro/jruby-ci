require 'sinatra'
require 'dm-core'
require 'haml'
require 'json'
require 'appengine-apis/logger'
require 'appengine-apis/urlfetch'

import com.sun.syndication.feed.synd.SyndFeed
import com.sun.syndication.io.XmlReader
import com.sun.syndication.io.SyndFeedInput

DataMapper.setup(:default, "appengine://auto")
JRUBY_REPOSITORY_FEED_URL = java.net.URL.new("http://github.com/feeds/jruby/commits/jruby/master")
TWITTER_ID_TABLE = {
  "Thomas E. Enebo" => "@tom_enebo",
  "Charles Oliver Nutter" => "@headius",
  "Nick Siger" => "@nicksiger",
  "Yoko Harada" => "@yokolet",
  "NAKAMURA" => "@nahi",
  "Vladimir Sizikov" => "@vsizikov",
  "Hiro Asari" => "@hiro_asari",
  "Wayne Meissner" => "@wmeissner",
  "Ola Bini" => "@olabini"
}
$logger = AppEngine::Logger.new

class CommitLog
  include DataMapper::Resource
  property :id, Serial
  property :uri, String
  property :author, String
  property :title, Text
  property :content, Text
  property :link, String
  property :short_link, String
  property :posted, Boolean
  property :date, DateTime
  property :created_at, DateTime

  before :save do
    self.created_at = Time.now
  end
end

get '/' do
  @logs = CommitLog.all(:order => [:date.desc], :limit => 10)
  haml :index
end

def post_tweet(status)
  url = "https://twitter.com/statuses/update.json"
  request = Net::HTTP::Post.new('/')
  request.basic_auth(
    java.lang.System.get_property('jrubyci.twitter.username'), 
    java.lang.System.get_property('jrubyci.twitter.password'))
  request.set_form_data({"status" => status, "source" => "jrubyci"})
  options = {
    :method => request.method,
    :payload => request.body,
    :headers => { 'Authorization' => request['Authorization'] }
  }
  begin 
    r = AppEngine::URLFetch.fetch(url, options)
  rescue
    $logger.error("Time out")
    retry
  end
  unless r.code.to_i == 200
    $logger.error("twitter post error.")
    halt 500, "twitter error"
  end
end

def strip_content(str)
  s = str.gsub(/<.*>/, '')
  s.gsub(/\s/, ' ')
  if s.length <= 90
    return s
  else
    s[0..86] + "..."
  end
end

def git_rev(uri)
  if uri =~ /Commit\/([0-9a-zA-Z]*)/
    $1[0..6]
  else
    ""
  end
end

def twitter_id(author)
  TWITTER_ID_TABLE[author] ? TWITTER_ID_TABLE[author] : author
end

def format_log(log)
  "#{twitter_id(log.author)} * #{git_rev(log.uri)} : #{strip_content(log.title)} #{log.short_link}"
end

def post_logs(logs)
  logs.each do |log|
    post_tweet(format_log(log))
    log.posted = true
    log.save
  end
end

def url_shorten(link)
  api_key = java.lang.System.get_property('jrubyci.bitly.apikey')
  request = Net::HTTP::Post.new('/')
  request.set_form_data({"longUrl" => link,
      "version" => "2.0.1",
      "login" => "jrubyci", "apiKey" => api_key})
  options = {
    :method => request.method,
    :payload => request.body,
  }
  r = AppEngine::URLFetch.fetch("http://api.bit.ly/shorten", options)
  if r.code.to_i == 200
    json = JSON.parse(r.body)
    return json["results"][link]["shortUrl"]
  else
    $logger.error("bitly error.")
    return nil
  end
end

def update(feeds)
  newlogs = []
  feeds.entries.each do |f|
    unless CommitLog.first(:uri => f.uri)
      log = CommitLog.new(
        :uri => f.uri,
        :author => f.authors[0].name,
        :title => f.titleEx.value,
        :content => f.contents[0].value,
        :link => f.link,
        :short_link => url_shorten(f.link),
        :date => DateTime.parse(f.updatedDate.to_gmtstring),
        :posted => false
        )
      log.save
      newlogs << log
    end
  end
  newlogs
end

get '/tweet' do
  @logs = CommitLog.all(:posted => false, :order => [:date.asc])
  post_logs(@logs)
  redirect '/'
end

get '/fetch' do
  feed = (SyndFeedInput.new).build(XmlReader.new(JRUBY_REPOSITORY_FEED_URL))
  newlogs = update(feed)
  redirect '/'
end

__END__

@@ index
!!! XML
!!! Strict

%html
  %head
    %title JRuby Commitlog monitor
    %link{:href => "/stylesheets/main.css", :rel => "stylesheet", :type => "text/css", :media => "screen"}
  %body
    %h2 JRuby Commit History
    %p
      Twitter : 
      %a{ :href => 'http://twitter.com/jrubyci'}
        @jrubyci
    %table
      - @logs.each do |log|
        %tr
          %td= log.author
          %td= log.title
          %td
            %a{ :href => log.short_link}
              #{log.short_link}
          %td= log.date
    #footer
      %ul
        %li
          Application deployed on 
          %a{ :href => 'http://code.google.com/appengine'}
            Google App Engine
        %li
          Developed with 
          %a{ :href => 'http://jruby-appengine.blogspot.com/'}
            appengine-jruby
        %li
          Code hosted on 
          %a{ :href => 'http://github.com/koichiro/jruby-ci/tree'}
            GitHub
      %img{ :src => "http://code.google.com/appengine/images/appengine-noborder-120x30.gif", :alt => "Powered by Google App Engine"}

