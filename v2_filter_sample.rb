require 'http'
require 'uri'
require 'json'
require 'securerandom'
require 'openssl'
require 'simple_oauth'
require 'simple_twitter'

def oauth_params
  {
    api_key: ENV['API_KEY'],
    api_secret_key: ENV['API_KEY_SECRET'],
    access_token: ENV['ACCESS_TOKEN'],
    access_token_secret: ENV['ACCESS_TOKEN_SECRET']
  }
end

def oauth_client
  @oauth_client ||= SimpleTwitter::Client.new(
    {
      api_key: ENV['API_KEY'],
      api_secret_key: ENV['API_KEY_SECRET'],
      access_token: ENV['ACCESS_TOKEN'],
      access_token_secret: ENV['ACCESS_TOKEN_SECRET']
    }
  )
end

def bearer_client
  @bearer_client ||= SimpleTwitter::Client.new(
    bearer_token: ENV['BEARER']
  )
end


# def filter
#   bearer_token = ENV['BEARER']
#   p bearer_token
#   stream_url = "https://api.twitter.com/2/tweets/search/stream"
# 
#   url = URI.parse(stream_url)
#   request = Net::HTTP::Get.new(url.path)
#   request['User-Agent'] = 'v2FilteredStreamRuby'
#   request['Authorization'] = "Bearer #{bearer_token}"
# 
#   http =  Net::HTTP.new(url.host, url.port)
#   http.use_ssl = true
#   res = http.start do |http|
#     http.request(request) do |response|
#       raise 'Response is not chuncked' unless response.chunked?
#       response.read_body do |chunk|
#         p JSON.parse(chunk)
#       end
#     end
#   end
# end

def filter
  bearer_token = ENV['BEARER']
  p bearer_token

  stream_url = "https://api.twitter.com/2/tweets/search/stream"
  body = HTTP.auth("Bearer #{bearer_token}")
             .headers('user-agent': 'v2FilteredStreamRuby')
             .get(stream_url, params: {"start_time": '2023-01-14T14:00:00Z'})
             #.get(stream_url)

  p body
  loop do
    p JSON.parse(body.readpartial)
  end
end

def me
  me_url = "https://api.twitter.com/2/users/me"

  
end

def friend_ids
  url = 'https://api.twitter.com/2/users/487348823/followers?'

  oauth_client.get(url)[:data].map{|u| u[:id]}
end


def get_rules
  rules_url = "https://api.twitter.com/2/tweets/search/stream/rules"

  p bearer_client.get(rules_url)
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
  
  
  #rules = follower_rules.map {|rule| {value: rule}}
 
  #payload = { add: [{ value: 'ウマ娘', tag: 'uma'}]}
  
  #request = Net::HTTP::Post.new(url.path)
  #request['User-Agent'] = 'v2FilteredStreamRuby'
  #request['Authorization'] = "Bearer #{bearer_token}"
  #request['Content-type'] = "application/json"
  #request.body = payload.to_json
  
  #http =  Net::HTTP.new(url.host, url.port)
  #http.use_ssl = true
  
  #res = http.start do |h|
  #  h.request(request)
  #end
  bearer_token = ENV['BEARER']
  p bearer_token

  payload = { add: [{ value: 'ウマ娘', tag: 'uma'}]}

  res = HTTP.auth("Bearer #{bearer_token}")
             .headers('user-agent': 'v2FilteredStreamRuby')
             .post(rules_url, json: payload)


  
  puts res.body
  p res

end

def delete_rules(ids)
  rules_url = "https://api.twitter.com/2/tweets/search/stream/rules"
  bearer_token = ENV['BEARER']
  p bearer_token

  payload = { delete: {ids: ids} }

  res = HTTP.auth("Bearer #{bearer_token}")
             .headers('user-agent': 'v2FilteredStreamRuby')
             .post(rules_url, json: payload)


  
  puts res.body
  p res
end

def follower_rules
  #p friend_ids.map {|id| "from:#{id}"}.each_slice(20).to_a.map {|ids| ids.join(' OR ') }
  friend_ids.map {|id| "from:#{id}"}.each_slice(5).to_a.map {|ids| ids.join(' OR ') }
end

def get_rules
  bearer_client.get('https://api.twitter.com/2/tweets/search/stream/rules')
end

def get_user(name)
  url = 'https://api.twitter.com/2/users/by'

  bearer_client.get(url, usernames: name)
end

def recent_search
  url = 'https://api.twitter.com/2/tweets/search/recent'


  bearer_client.get(url, query: 'from:issei126')
end
#post_rules
#filter

#puts oauth_signature('get', 'https://api.twitter.com/2/users/me', {}, {b: 1, a: 'ほげ'})


#me

#post_rules
#friend_ids

#p get_rules[:data].map{|d| d[:id]}
#delete_rules(['1614549354584629248'])
p get_rules

#p get_user('simotakaido')

#delete_rules(get_rules[:data].map{|d| d[:id]})


#p (recent_search)