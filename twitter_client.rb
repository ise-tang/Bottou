require 'twitter'
require 'tweetstream'
require 'yaml'

class TwitterClient
  TOKEN = YAML.load_file("#{File.dirname(File.expand_path(__FILE__))}/Token.yml")[0]

  def self.rest_client
    Twitter::REST::Client.new do |config|
      config.consumer_key        = TOKEN["consumer_key"]
      config.consumer_secret     = TOKEN["consumer_secret"]
      config.access_token        = TOKEN["access_token"]
      config.access_token_secret = TOKEN["access_token_secret"]
    end
  end

  def self.userstream_client
    TweetStream.configure do |config|
      config.consumer_key       = TOKEN["consumer_key"]
      config.consumer_secret    = TOKEN["consumer_secret"]
      config.oauth_token        = TOKEN["access_token"]
      config.oauth_token_secret = TOKEN["access_token_secret"]
      config.auth_method = :oauth
    end

    #TweetStream::Daemon.new('bottou_stream')
    TweetStream::Client.new
  end
end
