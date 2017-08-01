# select and build tweet pattern
require './tweet_pattern.rb'
class TweetPatternFactory
  def self.build(status)
    if Karareply.match?(status)
      puts "kara rip"
      return Karareply.new(status)
    end

    if Towatowa.match?(status)
      puts "towatowa rip"
      return Towatowa.new(status)
    end

    if CoinToss.match?(status)
      return CoinToss.new(status)
    end

    # ~ 検索のパターン
    if ImageSearchReply.match?(status)
      puts 'image_search'
      begin
        return ImageSearchReply.new(status)
      rescue => e
        puts e.message
        puts e.backtrace
      end
    elsif SearchReply.match?(status)
      return SearchReply.new(status)
    end

    # ~教えてのパターン
    if WeatherReply.match?(status)
      puts "weather"
      return WeatherReply.new(status)
    elsif JokeAnswerReply.match?(status)
      return JokeAnswerReply.new(status)
    end

    return nil
  end
end
