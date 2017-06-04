require './image_search.rb'
require 'http'

# base tweet pattern class
class TweetPattern
  attr_reader :tweet, :image

  def initialize(status)
    @tweet = build_tweet(status)
    @image = build_image(status)
  end

  # maybe overwritten by a class inherits this class.
  def self.match?(_status)
    true
  end

  def build_tweet(status)
    status.text
  end

  def build_image(_status)
    nil
  end

  private

  def self.include_account?(text)
    text.include?('@itititititk')
  end

  def self.tweet_by_self?(user)
    user.screen_name == 'itititititk'
  end

  def self.not_RT(text)
    text.match(/^RT.*/) == nil 
  end
end

class Towatowa < TweetPattern
  def self.match?(status)
    include_account?(status.text) && status.text.include?('とゎとゎ') && !tweet_by_self?(status.user)
  end

  def build_tweet(status)
    "@#{status.user.screen_name} ( ‘д‘⊂彡☆))Д´) ﾊﾟｰﾝ"
  end
end

class Karareply < TweetPattern
  def self.match?(status)
    include_account?(status.text) && !tweet_by_self?(status.user) && status.text.gsub(/@\w+/, '').gsub(' ', '').gsub('　', '').empty?
  end

  def build_tweet(status)
    "@#{status.user.screen_name} " + status.text.sub('@itititititk', '') + ' '
  end
end

class ImageSearchReply < TweetPattern
  attr_reader :response, :search_word

  def self.match?(status)
    not_RT(status.text) && status.text.match(/.*画像.*[\[|［]検索[\]|］]$/) != nil
  end

  def initialize(status)
    @search_word = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/画像.*[\[|［]検索[\]|］]/, '').gsub(/@\w+/, '').strip
    @responses = ImageSearch.run(search_word)
    @post_image = random_image_pickup
    super
  end

  def random_image_pickup
    return nil if @responses['items'] == nil

    @responses['items'].sample
  end

  def build_tweet(status)
    if @post_image.nil?
      "@#{status.user.screen_name} #{search_word}の画像はなかったです.. "
    else
      "@#{status.user.screen_name} #{search_word}の画像 掲載元: #{@post_image['image']['contextLink']}"
    end
  end

  def build_image(status)
    begin
     img = Tempfile.open(['image', '.jpg'])
     img.binmode
     img.write(HTTP.get(@post_image['link']).to_s)
      img.rewind
      img
    rescue => e
      puts "build_image error"
      puts e.message
    end
  end
end

class SearchReply < TweetPattern
  GOOGLE_SEARCH_URL_BASE="http://www.google.co.jp/search?q="

  def self.match?(status)
    not_RT(status.text) && !status.text.match(/.*[\[|［]検索[\]|］]$/).nil?
  end

  def build_tweet(status)
    search_word = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/[\[|［]検索[\]|］]/, '').gsub(/@\w+/, '').strip
    "@#{status.user.screen_name} #{search_word}の検索結果: #{GOOGLE_SEARCH_URL_BASE}#{URI.encode(search_word)}"
  end
end

class WeatherReply < TweetPattern
  def self.match?(status)
    not_RT(status.text) && !status.text.match(/.*天気.*教えて$/).nil?
  end

  def build_tweet(status)
    weather_point = WeatherForecast.point(status)
    weather_info = WeatherForecast.fetch_result(weather_point)

    if weather_info.empty?
      "@#{status.user.screen_name} #{weather_point}はわからぬ。。。。。。。"
    else
      forecast = JSON.parse(weather_info)['forecasts'][1]

      "@#{status.user.screen_name} 明日の#{weather_point}の天気は#{forecast['telop']}, 最高気温は#{forecast['temperature']['max']['celsius']}℃, 最低気温は#{forecast['temperature']['min']['celsius']}℃らしいです。。"
    end
  end
end

class JokeAnswerReply < TweetPattern
  def self.match?(status)
    not_RT(status.text) && !status.text.match(/.*教えて$/).nil?
  end

  def build_tweet(status)
    search_phrase = status.text.gsub(/ﾎﾞｯﾄｩ/, '').gsub(/[[:blank:]]/, '').gsub(/教えて/, '').strip
    joke_answer = JokeAnswer.run(search_phrase)

    if joke_answer.nil?
      "@#{status.user.screen_name} #{search_phrase}は知らない子ですね"
    else
      "@#{status.user.screen_name} #{search_phrase}は#{joke_answer}じゃないですかね"
    end
  end
end
