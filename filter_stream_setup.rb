require 'dotenv/load'
require './tweet_pattern_factory.rb'

require("#{File.dirname(File.expand_path(__FILE__))}/twitter_client_v2.rb")

tw_rest_client = TwitterClient.new

tw_rest_client.get_rules

#tw_rest_client.delete_rules([])
#tw_rest_client.post_rules
