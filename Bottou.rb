# coding: UTF-8

require 'rubygems'
require 'pp'
require 'yaml'
require 'cgi'
require 'http'
require 'json'
require './weather_forecast.rb'
# TODO: mecabが必要なのでコメントアウト
#require './joke_answer.rb'
require './image_search.rb'
require './markov.rb'
require './tweet_pattern_factory.rb'

class Bottou
  attr_reader :client, :userstream_client

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
      mentions = [client.mentions_timeline({ :max_results => 5 }).first]
    else
      mentions = client.mentions_timeline({ :since_id => last_reply_id })
    end
    targetUser = %w[issei126 itititk __KRS__ ititititk aki_fc3s SnowMonkeyYu1 Sukonjp heizel_2525 yanma_sh mayucpo asasasa2525 masaloop_S2S goaa99 hito224 gen_233 mi3pu pu_kingdom]

    mentions.each {|m| puts m.text }
    #if lastMention.user.screen_name == 'issei126' then
    unless mentions.first.nil?
      File.open('last_reply_id.txt', 'w') do |file|
        file.puts(mentions.first.id)
      end
    end

    mentions.each do |mention|
      puts mention.text
      next if Karareply.match?(mention) || Towatowa.match?(mention) || SearchReply.match?(mention) || ImageSearchReply.match?(mention)
      if targetUser.index(mention.user.screen_name) != nil then
        self.satoRT(mention)
      end
    end

  end

  def satoRT(mention)
    doc_file = "#{File.dirname(File.expand_path(__FILE__))}/doc/reply_doc.txt"
    phrases = File.readlines(doc_file, encoding: 'UTF-8').each { |line| line.chomp! }
    phrase = phrases[rand(phrases.size)]
    client.post("#{phrase} RT @#{mention.user.screen_name} #{CGI.unescapeHTML(mention.text)}",
                  {
                     reply: {
                       :in_reply_to_tweet_id => mention.id
                     }
                  }
               )
  end

  def markov_tweet(markov)
    tweet_text = markov.build_tweet
    puts "twi: #{tweet_text}"
    client.post(CGI.unescapeHTML(tweet_text))
  end

  def filter
    client.filter do |status|
      begin
        tweet_pattern = TweetPatternFactory.build(status)
        p tweet_pattern
        post_tweet(status, tweet_pattern) unless tweet_pattern.nil?
      rescue => e
        puts "ERROR: #{e.message}"
      end
    end
  end

  private

  def post_tweet(status, tweet_pattern)
    unless tweet_pattern.image.nil?
      client.update_with_media(
        tweet_pattern.tweet,
        tweet_pattern.image,
        in_reply_to_status: status,
        in_reply_to_status_id: status.id
      )
      tweet_pattern.image.close
      return
    end

    client.post(
      tweet_pattern.tweet,
      {
        reply: {
          in_reply_to_tweet_id: status.id
        }
      }
    )
  end
end
