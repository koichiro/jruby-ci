namespace :jrubyci do

  desc "fetch"
  task :fetch => :environment do
    CommitLog.fetch
  end

  desc "tweet"
  task :tweet => :environment do
    CommitLog.tweet
  end
end
