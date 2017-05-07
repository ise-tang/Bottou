require "./Bottou.rb"

require("#{File.dirname(File.expand_path(__FILE__))}/Bottou.rb")
require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client.rb")

tw_rest_client       = TwitterClient.rest_client
tw_userstream_client = TwitterClient.userstream_client
b = Bottou.new(tw_rest_client, tw_userstream_client)

b.userstream
