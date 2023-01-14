require 'net/http'
require 'uri'
require 'json'

def filter
  bearer_token = ENV['BEARER']
  p bearer_token
  stream_url = "https://api.twitter.com/2/tweets/search/stream"

  url = URI.parse(stream_url)
  request = Net::HTTP::Get.new(url.path)
  request['User-Agent'] = 'v2FilteredStreamRuby'
  request['Authorization'] = "Bearer #{bearer_token}"

  http =  Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  res = http.start do |http|
    http.request(request) do |response|
      raise 'Response is not chuncked' unless response.chunked?
      response.read_body do |chunk|
        p chunk
      end
    end
  end
end


def get_rules
# rules_url = "https://api.twitter.com/2/tweets/search/stream/rules"
# url = URI.parse(rules_url)
# 
# p url.host
# p url.port  
# p url.path

#request = Net::HTTP::Get.new(url.path)
#request
#request['User-Agent'] = 'v2FilteredStreamRuby'
#request['Authorization'] = "Bearer #{bearer_token}"
#
#http =  Net::HTTP.new(url.host, url.port)
#http.use_ssl = true
#
#res = http.start do |h|
#  h.request(request)
#end
#
#puts res.body
end

def post_rules
  bearer_token = ENV['BEARER']
  #params = {
  #  "expansions": "attachments.poll_ids,attachments.media_keys,author_id,entities.mentions.username,geo.place_id,in_reply_to_user_id,referenced_tweets.id,referenced_tweets.id.author_id",
  #  "tweet.fields": "attachments,author_id,conversation_id,created_at,entities,geo,id,in_reply_to_user_id,lang",
  #  # "user.fields": "description",
  #  # "media.fields": "url", 
  #  # "place.fields": "country_code",
  #  # "poll.fields": "options"
  #}
  rules_url = "https://api.twitter.com/2/tweets/search/stream/rules"
  url = URI.parse(rules_url)

  rules = { 'value': 'apple' }
  payload = { add: [rules]}

  request = Net::HTTP::Post.new(url.path)
  request['User-Agent'] = 'v2FilteredStreamRuby'
  request['Authorization'] = "Bearer #{bearer_token}"
  request['Content-type'] = "application/json"
  p payload.to_json
  request.body = payload.to_json
  
  http =  Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  
  res = http.start do |h|
    h.request(request)
  end
  
  puts res.body
end

# post_rules
filter