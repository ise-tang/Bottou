require "./markov.rb"
require "./twitter_client.rb"

client = TwitterClient.rest_client
m = Markov.new(client)

m.make_markov_dic
