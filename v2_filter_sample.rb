require 'http'
require 'uri'
require 'json'
require 'securerandom'
require 'openssl'
require 'simple_oauth'
require 'simple_twitter'
require './tweet_pattern_factory.rb'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'
require 'oauth'

def oauth_params
  {
    consumer_key: ENV['API_KEY'],
    consumer_secret: ENV['API_KEY_SECRET'],
    token: ENV['ACCESS_TOKEN'],
    token_secret: ENV['ACCESS_TOKEN_SECRET'],
    #version: '2.0'
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

Struct.new("User", :screen_name)
Struct.new("Status", :text, :user)

def filter
  bearer_token = ENV['BEARER']

  stream_url = "https://api.twitter.com/2/tweets/search/stream"
  body = HTTP.auth("Bearer #{bearer_token}")
             .headers('user-agent': 'v2FilteredStreamRuby')
             .get(stream_url, params: {"user.fields": 'id,username', 'expansions': 'author_id'})

  loop do
    begin
      str = body.readpartial
      unless str == "\r\n"
        p str
        json = JSON.parse(str)

        user = Struct::User.new(json['includes']['users'][0]['username'])
        status = Struct::Status.new(json['data']['text'], user)

        p TweetPatternFactory.build(status)
      end
    rescue => e
      puts "ERROR: #{e.message}"
    end
  end
end

def me
  me_url = "https://api.twitter.com/2/users/me"
end

def friends
  url = 'https://api.twitter.com/1.1/friends/list.json'

  #oauth_client.get(url, params: {user_id: '487348823'})
  oauth_client.get(url, skip_status: true, count: 100)
end

def friend_ids
  url = 'https://api.twitter.com/2/users/487348823/followers?'

  oauth_client.get(url)[:data].map{|u| u[:id]}
end

def friend_usernames
  friends[:users].map{|u| u[:screen_name]}
end


def get_rules
  rules_url = "https://api.twitter.com/2/tweets/search/stream/rules"

  p bearer_client.get(rules_url)
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
  
  bearer_token = ENV['BEARER']
  p bearer_token

  #bodies = follower_rules.map { |rule| { value: rule, tag: 'followers'} }
  payload = { add: [{ value: 'ウマ娘', tag: 'uma'}]}
  #payload = { add: [{ value: 'from:gizmodojapan', tag: 'giz'}]}
  #payload = { add: [{ value: 'from:issei126', tag: 'me'}]}
  #payload = { add: bodies}

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
  friend_usernames.map {|usernames| "from:#{usernames}"}.each_slice(5).to_a.map {|ids| ids.join(' OR ') }
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

def post1
  pp oauth_client.post("https://api.twitter.com/1.1/statuses/update.json",
    status: "Test.")
end

def post(tweet)
  url = 'https://api.twitter.com/2/tweets'

  params = {json: { :tweet => "test2"}}


  res = HTTP.auth(auth_header('post', url, params))
             .headers('user-agent': 'v2CreateTweetRuby')
             .post(url, json: params)

  pp res
end

def auth_header(method, url, params)
  
  SimpleOAuth::Header.new(method, url, params, oauth_params).to_s
end

def post 
  consumer = OAuth::Consumer.new(oauth_params[:consumer_key], oauth_params[:consumer_secret])
  access_token = OAuth::AccessToken.new(consumer, oauth_params[:token], oauth_params[:token_secret])
  oauth_params = {:consumer => consumer, :token => access_token}
  @json_payload = {text: 'test3'}
  url = 'https://api.twitter.com/2/tweets'
  options = {
    :method => :post,
    headers: {
       "User-Agent": "v2CreateTweetRuby",
      "content-type": "application/json"
    },
    body: JSON.dump(@json_payload)
  }
  request = Typhoeus::Request.new(url, options)
  oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(:request_uri => url))
  request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
  response = request.run

  puts response.code, JSON.pretty_generate(JSON.parse(response.body))
end
#post_rules
#filter
#post(nil)
#post1
post

