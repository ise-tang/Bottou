# coding: UTF-8

require 'rubygems'
require 'twitter'
require 'tweetstream'
require 'pp'
require 'yaml'
require 'natto'
require 'csv'
require 'cgi'

class Bottou
  # ログイン
  def initialize 
   @token = YAML.load_file("#{File.dirname(File.expand_path(__FILE__))}/Token.yml")[0]
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = @token["consumer_key"]
      config.consumer_secret = @token["consumer_secret"]
      config.access_token = @token["access_token"]
      config.access_token_secret = @token["access_token_secret"]
    end 
  end

# さとうさんのツイート取得
  def paku_twi()
    satoTweets = @client.user_timeline('itititk',
                                        { :count => rand(60),
                                          :exclude_replies => true
                                        })
                                        
    unless /[@|＠]/ =~ satoTweets.last.text then
      satoTweet = "#{satoTweets.last.text} http://twitter.com/#!/itititk/status/#{satoTweets.last.id}"
    #satoTweet = "#{satoTweets.last.text} ( tweeted at #{satoTweets.last.created_at} )"
      @client.update(satoTweet);
    else
      self.paku_twi()
    end
  end

  def reply()
    begin
      last_reply_id = File.open('last_reply_id.txt') do |file|
        file.read
      end
    rescue => e
      puts e.message
      last_reply_id = nil
    end

    if last_reply_id.nil?
      mentions = @client.mentions_timeline({ :count => 1 })
    else
      mentions = @client.mentions_timeline({ :since_id => last_reply_id })
    end
    targetUser = %w[issei126 itititk __KRS__ ititititk aki_fc3s SnowMonkeyYu1 Sukonjp heizel_2525 yanma_sh mayucpo asasasa2525 masaloop_S2S goaa99 hito224 gen_233 mi3pu]
    mentions.each {|m| puts m.text }
    #if lastMention.user.screen_name == 'issei126' then
    unless mentions.first.nil?
      File.open('last_reply_id.txt', 'w') do |file|
        file.puts(mentions.first.id)
      end
    end

    mentions.each do |mention|
      puts mention.text
      next if kara_reply?(mention) || towatowa?(mention)
      if targetUser.index(mention.user.screen_name) != nil then
        self.satoRT(mention)
      end
    end

  end

  def satoRT(mention)
    doc_file = "#{File.dirname(File.expand_path(__FILE__))}/doc/reply_doc.txt"
    phrases = File.readlines(doc_file, encoding: 'UTF-8').each { |line| line.chomp! }
    phrase = phrases[rand(phrases.size)]
    @client.update("#{phrase} RT @#{mention.user.screen_name} #{CGI.unescapeHTML(mention.text)}",
                  {:in_reply_to_status => mention,
                   :in_reply_to_status_id => mention.id})
  end

  def marukof_tweet
    natto = Natto::MeCab.new

    maruko = []

    CSV.foreach("./doc/maruko_dic.txt") do |csv|
      maruko << csv
    end

    twi = []
    start = maruko.select {|m| m[0] == '_B_'}.sample
    result = select_maruko(maruko, start, twi)

    twit =  result.map {|m| m[0]}.join

    puts "twi: #{twit}"
    @client.update(CGI.unescapeHTML(twit))
  end

  def make_maruko_dic
      natto = Natto::MeCab.new
      begin
        last_sato_tweet_id = File.open('last_sato_tweet_id.txt') do |file|
          file.read
        end
      rescue => e
        puts e.message
        last_sato_tweet_id = nil
      end
      option = { count: 100,
                 :exclude_replies => true,
               }
      if (!last_sato_tweet_id.nil? && !last_sato_tweet_id.empty?)
        option[:since_id] = last_sato_tweet_id
      end

      dic = {}
      File.open("./doc/maruko_dic.txt", "r") do |file|
        while line = file.gets
          dic[line.chomp!] = ''
         end
      end

      satoTweets = @client.user_timeline('itititk', option)
      maruko = []
      satoTweets.each do |tweet|
        next if tweet.text.include?('RT')
        #p tweet.text
        keitai = []
        natto.parse(tweet.text.gsub(/http.+/, '').gsub(/[@＠].+?/, '')) do |n|
          keitai << n.surface
        end
        keitai.unshift('_B_')
        keitai << '_E_'
        keitai.size.times do |i|
          maruko << [keitai[i], keitai[i+1]] unless dic.has_key?([keitai[i], keitai[i+1]].join(','))

          break if keitai[i+1] == '_E_'
        end
      end

      File.open("./doc/maruko_dic.txt", "a") do |file|
        maruko.each do |m|
          file.puts(m.join(','))
        end
      end

      unless satoTweets.last.nil?
        File.open('last_sato_tweet_id.txt', 'w') do |file|
          file.puts(satoTweets.first.id)
        end
      end

  end

  def test_user_stream
    TweetStream.configure do |config|
      config.consumer_key = @token["consumer_key"]
      config.consumer_secret = @token["consumer_secret"]
      config.oauth_token = @token["access_token"]
      config.oauth_token_secret = @token["access_token_secret"]
      config.auth_method = :oauth
    end 
    client = TweetStream::Daemon.new('kara_reply')
    #client = TweetStream::Client.new

    client.userstream do |status|
      puts status.text
      puts status.user.screen_name 
      puts kara_rip_to = "@#{status.user.screen_name} " + status.text.sub('@itititititk', '') + ' '
      if kara_reply?(status)
        puts "kara rip"
        @client.update(kara_rip_to,
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
      end

      if towatowa?(status)
        puts "kara rip"
        @client.update("@#{status.user.screen_name} ( ‘д‘⊂彡☆))Д´) ﾊﾟｰﾝ",
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
      end
    end
  end
end

def kara_reply?(status)
  status.text.include?('@itititititk') && status.text.gsub(/@\w+/, '').gsub(' ', '').gsub('　', '').empty? && status.user.screen_name != 'itititititk'
end

def towatowa?(status)
  status.text.include?('@itititititk') && status.text.include?('とゎとゎ') && status.user.screen_name != 'itititititk'
end

def select_maruko(maruko, so, twi)
  return twi if !so.nil? && so.last == '_E_'
  m = maruko.select { |ma| ma[0] == so[1] }.sample
  twi << m
  select_maruko(maruko, m, twi)
end
