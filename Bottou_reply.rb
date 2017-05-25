require("#{File.dirname(File.expand_path(__FILE__))}/Bottou.rb")
require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client.rb")

tw_rest_client = TwitterClient.rest_client
b = Bottou.new(tw_rest_client)

b.reply
