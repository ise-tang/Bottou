# coding: UTF-8

require 'rubygems'
require 'twitter'
require 'tweetstream'
require 'pp'
require 'yaml'
require 'natto'
require 'csv'
require 'cgi'
require 'http'
require 'json'

class Bottou
  GOOGLE_SEARCH_URL_BASE="http://www.google.co.jp/search?q="
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

      satoTweets = @client.user_timeline('itititk', option)
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

      if search?(status)
        search_word = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/[\[|［]検索[\]|］]/, '').gsub(/@\w+/, '').strip
        @client.update("@#{status.user.screen_name} #{search_word}の検索結果: #{GOOGLE_SEARCH_URL_BASE}#{URI.encode(search_word)}")
      end

      if weather?(status)
        puts "weather"
        points = {"稚内"=>"011000", "旭川"=>"012010", "留萌"=>"012020", "網走"=>"013010", "北見"=>"013020", "紋別"=>"013030",
                  "根室"=>"014010", "釧路"=>"014020", "帯広"=>"014030", "室蘭"=>"015010", "浦河"=>"015020", "札幌"=>"016010", 
                  "岩見沢"=>"016020", "倶知安"=>"016030", "函館"=>"017010", "江差"=>"017020", "青森"=>"020010",
                  "むつ"=>"020020", "八戸"=>"020030", "盛岡"=>"030010", "宮古"=>"030020", "大船渡"=>"030030",
                  "仙台"=>"040010", "白石"=>"040020", "秋田"=>"050010", "横手"=>"050020", "山形"=>"060010",
                  "米沢"=>"060020", "酒田"=>"060030", "新庄"=>"060040", "福島"=>"070010", "小名浜"=>"070020",
                  "若松"=>"070030", "水戸"=>"080010", "土浦"=>"080020", "宇都宮"=>"090010", "大田原"=>"090020",
                  "前橋"=>"100010", "みなかみ"=>"100020", "さいたま"=>"110010", "熊谷"=>"110020", "秩父"=>"110030",
                  "千葉"=>"120010", "銚子"=>"120020", "館山"=>"120030", "東京"=>"130010", "大島"=>"130020",
                  "八丈島"=>"130030", "父島"=>"130040", "横浜"=>"140010", "小田原"=>"140020", "新潟"=>"150010",
                  "長岡"=>"150020", "高田"=>"150030", "相川"=>"150040", "富山"=>"160010", "伏木"=>"160020",
                  "金沢"=>"170010", "輪島"=>"170020", "福井"=>"180010", "敦賀"=>"180020", "甲府"=>"190010",
                  "河口湖"=>"190020", "長野"=>"200010", "松本"=>"200020", "飯田"=>"200030", "岐阜"=>"210010",
                  "高山"=>"210020", "静岡"=>"220010", "網代"=>"220020", "三島"=>"220030", "浜松"=>"220040",
                  "名古屋"=>"230010", "豊橋"=>"230020", "津"=>"240010", "尾鷲"=>"240020", "大津"=>"250010",
                  "彦根"=>"250020", "京都"=>"260010", "舞鶴"=>"260020", "大阪"=>"270000", "神戸"=>"280010",
                  "豊岡"=>"280020", "奈良"=>"290010", "風屋"=>"290020", "和歌山"=>"300010", "潮岬"=>"300020",
                  "鳥取"=>"310010", "米子"=>"310020", "松江"=>"320010", "浜田"=>"320020", "西郷"=>"320030",
                  "岡山"=>"330010", "津山"=>"330020", "広島"=>"340010", "庄原"=>"340020", "下関"=>"350010",
                  "山口"=>"350020", "柳井"=>"350030", "萩"=>"350040", "徳島"=>"360010", "日和佐"=>"360020",
                  "高松"=>"370000", "松山"=>"380010", "新居浜"=>"380020", "宇和島"=>"380030", "高知"=>"390010",
                  "室戸岬"=>"390020", "清水"=>"390030", "福岡"=>"400010", "八幡"=>"400020", "飯塚"=>"400030",
                  "久留米"=>"400040", "佐賀"=>"410010", "伊万里"=>"410020", "長崎"=>"420010", "佐世保"=>"420020",
                  "厳原"=>"420030", "福江"=>"420040", "熊本"=>"430010", "阿蘇乙姫"=>"430020", "牛深"=>"430030",
                  "人吉"=>"430040", "大分"=>"440010", "中津"=>"440020", "日田"=>"440030", "佐伯"=>"440040",
                  "宮崎"=>"450010", "延岡"=>"450020", "都城"=>"450030", "高千穂"=>"450040", "鹿児島"=>"460010",
                  "鹿屋"=>"460020", "種子島"=>"460030", "名瀬"=>"460040", "那覇"=>"471010", "名護"=>"471020",
                  "久米島"=>"471030", "南大東"=>"472000", "宮古島"=>"473000", "石垣島"=>"474010", "与那国島"=>"474020"} 
        begin
          base_url = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=%s'
          weather_point = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/[[:blank:]]/, '').gsub(/の?天気教えて/, '').strip
          
          weather_info =  if points.has_key?(weather_point)
                            HTTP.get(base_url % points[weather_point]).to_s
                          else
                            ''
                          end

          if weather_info.empty?
            @client.update("@#{status.user.screen_name} #{weather_point}はわからぬ。。。。。。。")
          else
            forecast = JSON.parse(weather_info)['forecasts'][1]

            @client.update("@#{status.user.screen_name} 明日の#{weather_point}の天気は#{forecast['telop']}, 最高気温は#{forecast['temperature']['max']['celsius']}℃, 最低気温は#{forecast['temperature']['min']['celsius']}℃らしいです。。",
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
