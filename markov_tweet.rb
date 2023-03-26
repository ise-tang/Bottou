require("#{File.dirname(File.expand_path(__FILE__))}/Bottou.rb")
require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client_v2.rb")


puts "### Start markov at #{Time.now} ###"

tw_rest_client = TwitterClient.new
markov = Markov.new(tw_rest_client)
b = Bottou.new(tw_rest_client)

b.markov_tweet(markov) if rand(100) < 30 # 30％の確率でつぶやくように。

puts "### End markov at #{Time.now} ###"