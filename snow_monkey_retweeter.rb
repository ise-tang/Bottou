require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client_v2.rb")

class SnowMonkeyRetweeter
  THE_TWEET_ID = "246252965302775809"

  def self.run
    tw_rest_client = TwitterClient.new
    tw_rest_client.unretweet(THE_TWEET_ID)
    tw_rest_client.retweet(THE_TWEET_ID)
  end

end
