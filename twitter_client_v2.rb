require 'json'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'
require 'oauth'
require 'dotenv/load'

Struct.new("User", :screen_name)
Struct.new("Status", :text, :user)

class TwitterClient
  def oauth_params
    {
      consumer_key: ENV['API_KEY'],
      consumer_secret: ENV['API_KEY_SECRET'],
      token: ENV['ACCESS_TOKEN'],
      token_secret: ENV['ACCESS_TOKEN_SECRET'],
      #version: '2.0'
    }
  end

  def filtr_use
    filter do |json|
      begin
        user = Struct::User.new(json['includes']['users'][0]['username'])
        status = Struct::Status.new(json['data']['text'], user)

        p TweetPatternFactory.build(status)
      rescue => e
        puts "ERROR: #{e.message}"
      end
    end
  end

  def filter
    bearer_token = ENV['BEARER']

    url = "https://api.twitter.com/2/tweets/search/stream"
    params = {"user.fields": 'id,username', 'expansions': 'author_id'}

    consumer = OAuth::Consumer.new(oauth_params[:consumer_key], oauth_params[:consumer_secret])
    access_token = OAuth::AccessToken.new(consumer, oauth_params[:token], oauth_params[:token_secret])
    oauth_params = {:consumer => consumer, :token => access_token}

    header_hash = {
      "User-Agent": 'v2FilteredStreamRuby',
      "Authorization": "Bearer #{bearer_token}",
      "Content-type": "application/json"

    }

    options = {
      timeout: 20,
      method: :get,
      headers: header_hash
    }

    options[:body] = JSON.dump(params) if params

    request = Typhoeus::Request.new(url, options)

    request.on_body do |chunk|
      yield(JSON.parse(chunk)
    end

    response = request.run
  end

  def me
    me_url = "https://api.twitter.com/2/users/me"
    query_params = {
      # "expansions": "pinned_tweet_id",
      # "tweet.fields": "attachments,author_id,conversation_id,created_at,entities,geo,id,in_reply_to_user_id,lang",
      "user.fields": "created_at,description"
    }
    method = 'get'
    header = "v2UserLookupRuby"
    content = 'application/json'

    twitter_request(me_url, query_params, method, header, content)
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
    rules_url = "https://api.twitter.com/2/tweets/search/stream/rules"
    
    #bodies = follower_rules.map { |rule| { value: rule, tag: 'followers'} }
    payload = { add: [{ value: 'ウマ娘', tag: 'uma'}]}
    #payload = { add: [{ value: 'from:gizmodojapan', tag: 'giz'}]}
    #payload = { add: [{ value: 'from:issei126', tag: 'me'}]}
    #payload = { add: bodies}

    options = {
      headers: {
        "User-Agent": "v2FilteredStreamRuby",
        "Authorization": "Bearer #{bearer_token}",
        "Content-type": "application/json"
      },
      body: JSON.dump(payload)
    }

    @response = Typhoeus.post(rules_url, options)
    raise "An error occurred while adding rules: #{@response.status_message}" unless @response.success?
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

  def post(text)
    twitter_request(
      'https://api.twitter.com/2/tweets',
      { text: text},
      'post',
      'v2CreateTweetRuby',
      'application/json'
    )
  end

  def twitter_request(url, params, method, header, content_type)
    consumer = OAuth::Consumer.new(oauth_params[:consumer_key], oauth_params[:consumer_secret])
    access_token = OAuth::AccessToken.new(consumer, oauth_params[:token], oauth_params[:token_secret])
    oauth_params = {:consumer => consumer, :token => access_token}

    header_hash = {
      "User-Agent": header 
    }
    header_hash["content-type"] = content_type if content_type

    options = {
      :method => method,
      headers: header_hash
    }

    options[:body] = JSON.dump(params) if params

    request = Typhoeus::Request.new(url, options)
    oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(:request_uri => url))
    request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
    response = request.run

    puts response.code, JSON.pretty_generate(JSON.parse(response.body))
  end
end

