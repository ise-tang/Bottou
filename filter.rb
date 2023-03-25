require "./Bottou.rb"

require("#{File.dirname(File.expand_path(__FILE__))}/Bottou.rb")
require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client_v2.rb")

tw_rest_client = TwitterClient.new
b = Bottou.new(tw_rest_client)

b.filter
