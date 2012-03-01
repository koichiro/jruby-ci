class CommitLog < ActiveRecord::Base
  FEED_URL = 'https://github.com/feeds/jruby/commits/jruby/master'
  TWITTER_ID = {
    "Thomas E. Enebo" => "tom_enebo",
    "Charles Oliver Nutter" => "headius",
    "Nick Sieger" => "nicksieger",
    "Yoko Harada" => "yokolet",
    "NAKAMURA" => "nahi",
    "Vladimir Sizikov" => "vsizikov",
    "Hiro Asari" => "hiro_asari",
    "Wayne Meissner" => "wmeissner",
    "Ola Bini" => "olabini",
    "Marcin Mielzynski" => "lopex",
    "Subramanya Sastry" => "subbuss",
  }

  def self.fetch
    atom = RSS::Parser.parse(open(FEED_URL))
    atom.items.each do |item|
      next unless CommitLog.where(:uri => item.id.content).empty?
      updated = item.updated.content.to_s
      CommitLog.create(
        :uri => item.id.content,
        :author => item.author.name.content,
        :title => item.title.content,
        :content => item.content.content,
        :link => item.link.href,
        :short_link => url_shorten(item.link.href.to_s),
        :posted => false,
        :created_at => updated,
        :updated_at => updated
      )
    end
  end

  def self.tweet
    commits = CommitLog.where(:posted => false).order("created_at asc")
    commits.each do |log|
      Twitter.update(format_log(log))
      log.posted = true
      log.save
      sleep 10
    end
  end

  def self.twitter_id(author)
    TWITTER_ID[author] ? TWITTER_ID[author] : author
  end

  def self.format_log(log)
    "#{twitter_id(log.author)} * #{git_rev(log.uri)} : #{strip_content(log.title)} #{log.short_link}"
  end

  def self.git_rev(uri)
    if uri =~ /Commit\/([0-9a-zA-Z]*)/
      $1[0..6]
    else
      ""
    end
  end

  def self.strip_content(str)
    s = str.gsub(/<.*>/, '')
    s.gsub(/\s/, ' ')
    if s.length <= 90
      return s
    else
      s[0..86] + "..."
    end
  end

  def self.url_shorten(link)
    url_enc = URI.escape(link, /[^a-zA-Z0-9.:]/)
    r = Net::HTTP.get("api.bit.ly", "/v3/shorten?login=jrubyci&apiKey=R_374f446617f2a74ecad57584e66b17a9&longUrl=#{url_enc}&format=txt")
    if /(^http.*)/ =~ r
      r = $1
    else
      r = link
    end
    r
  end
end
