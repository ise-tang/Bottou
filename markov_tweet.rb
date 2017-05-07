require("#{File.dirname(File.expand_path(__FILE__))}/Bottou.rb")
require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client.rb")

tw_rest_client = TwitterClient.rest_client
markov = Markov.new
b = Bottou.new(tw_rest_client)

b.markov_tweet(markov) if rand(100) < 30
