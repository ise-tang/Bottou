# coding: UTF-8

require 'rubygems'
require 'tweetstream'
require 'pp'
require 'yaml'
require 'natto'
require 'csv'
require 'cgi'
require 'http'
require 'json'
require './weather_forecast.rb'
require './joke_answer.rb'
require './image_search.rb'

class Bottou
  attr_reader :client, :userstream_client

  GOOGLE_SEARCH_URL_BASE="http://www.google.co.jp/search?q="

  def initialize(twitter_rest_client, twitter_userstrem_client = nil)
    @client = twitter_rest_client
    @userstream_client = twitter_userstrem_client
  end

# さとうさんのツイート取得
  def paku_twi()
    satoTweets = client.user_timeline('itititk',
                                        { :count => rand(60),
                                          :exclude_replies => true
                                        })
                                        
    unless /[@|＠]/ =~ satoTweets.last.text then
      satoTweet = "#{satoTweets.last.text} http://twitter.com/#!/itititk/status/#{satoTweets.last.id}"
    #satoTweet = "#{satoTweets.last.text} ( tweeted at #{satoTweets.last.created_at} )"
      client.update(satoTweet);
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
      mentions = client.mentions_timeline({ :count => 1 })
    else
      mentions = client.mentions_timeline({ :since_id => last_reply_id })
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
      next if kara_reply?(mention) || towatowa?(mention) || search?(mention) || image_search?(mention)
      if targetUser.index(mention.user.screen_name) != nil then
        self.satoRT(mention)
      end
    end

  end

  def satoRT(mention)
    doc_file = "#{File.dirname(File.expand_path(__FILE__))}/doc/reply_doc.txt"
    phrases = File.readlines(doc_file, encoding: 'UTF-8').each { |line| line.chomp! }
    phrase = phrases[rand(phrases.size)]
    client.update("#{phrase} RT @#{mention.user.screen_name} #{CGI.unescapeHTML(mention.text)}",
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
    client.update(CGI.unescapeHTML(twit))
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
      option = { count: 200,
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

      satoTweets = client.user_timeline('itititk', option)
      maruko = []
      satoTweets.each do |tweet|
        next if tweet.text.include?('RT') || tweet.text.include?('"')
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

  def userstream
    userstream_client.userstream do |status|
      puts status.text
      puts status.user.screen_name
      puts kara_rip_to = "@#{status.user.screen_name} " + status.text.sub('@itititititk', '') + ' '
      if kara_reply?(status)
        puts "kara rip"
        client.update(kara_rip_to,
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
      end

      if towatowa?(status)
        puts "kara rip"
        client.update("@#{status.user.screen_name} ( ‘д‘⊂彡☆))Д´) ﾊﾟｰﾝ",
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
      end

      if image_search?(status)
        puts 'image_search'
        begin
          search_word = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/画像.*[\[|［]検索[\]|］]/, '').gsub(/@\w+/, '').strip
          response = ImageSearch.run(search_word)
          if response['items'] == nil
            client.update("@#{status.user.screen_name} #{search_word}の画像はなかったです.. ")
          else
            img = Tempfile.open(['image', '.jpg'])
            img.binmode
            img.write(HTTP.get(response['items'].sample['link']).to_s)
            img.rewind
            p img.class
            client.update_with_media("@#{status.user.screen_name} #{search_word}の画像 ", img,
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
            img.close
          end
        rescue => e
          puts e.message
          puts e.backtrace
        end
      elsif search?(status)
        search_word = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/[\[|［]検索[\]|］]/, '').gsub(/@\w+/, '').strip
        client.update("@#{status.user.screen_name} #{search_word}の検索結果: #{GOOGLE_SEARCH_URL_BASE}#{URI.encode(search_word)}",
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
      end

      if weather?(status)
        puts "weather"
        begin
          weather_point = WeatherForecast.point(status)
          weather_info = WeatherForecast.fetch_result(weather_point)

          if weather_info.empty?
            client.update("@#{status.user.screen_name} #{weather_point}はわからぬ。。。。。。。",
                      {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
          else
            forecast = JSON.parse(weather_info)['forecasts'][1]

            client.update("@#{status.user.screen_name} 明日の#{weather_point}の天気は#{forecast['telop']}, 最高気温は#{forecast['temperature']['max']['celsius']}℃, 最低気温は#{forecast['temperature']['min']['celsius']}℃らしいです。。",
             {:in_reply_to_status => status,
                       :in_reply_to_status_id => status.id})
          end
        rescue => e
          puts e.message
          puts e.backtrace
        end
      elsif JokeAnswer.match?(status)
        begin
          search_phrase = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/[[:blank:]]/, '').gsub(/教えて/, '').strip
          joke_answer = JokeAnswer.run(search_phrase)

          if joke_answer.nil?
            client.update("@#{status.user.screen_name} #{search_phrase}は知らない子ですね",
                 {:in_reply_to_status => status,
                           :in_reply_to_status_id => status.id})
          else
            client.update("@#{status.user.screen_name} #{search_phrase}は#{joke_answer}じゃないですかね",
                 {:in_reply_to_status => status,
                           :in_reply_to_status_id => status.id})
          end
        rescue => e
          puts e.message
          puts e.backtrace
        end
      end
    end
  end
end

def weather?(status)
  status.text.match(/^RT.*/) == nil && status.text.match(/.*天気.*教えて$/) != nil
end

def search?(status)
  status.text.match(/^RT.*/) == nil && status.text.match(/.*[\[|［]検索[\]|］]$/) != nil
end

def image_search?(status)
  status.text.match(/^RT.*/) == nil && status.text.match(/.*画像.*[\[|［]検索[\]|］]$/) != nil
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
