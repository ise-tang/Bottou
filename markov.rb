# TODO: マルコフ辞書を生成するにはmecabをインストールしてコメントアウト
# require 'natto'
require 'csv'

class Markov
  attr_reader :client

  def initialize(twitter_rest_client)
    @client = twitter_rest_client
  end

  def build_tweet
    maruko = []

    CSV.foreach("./doc/maruko_dic.txt") do |csv|
      maruko << csv
    end

    twi = []
    start = maruko.select { |m| m[0] == '_B_' }.sample
    result = select_maruko(maruko, start, twi)

    result.map { |m| m[0] }.join
  end

  def select_maruko(maruko, so, twi)
    return twi if !so.nil? && so.last == '_E_'
    m = maruko.select { |ma| ma[0] == so[1] }.sample
    twi << m
    select_maruko(maruko, m, twi)
  end

  def make_markov_dic
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
end
