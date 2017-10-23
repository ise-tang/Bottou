require 'http'
require 'dotenv/load'
require 'natto'

class JokeAnswer
  SEARCH_URL_BASE="https://www.googleapis.com/customsearch/v1?key=#{ENV['GOOGLE_API_KEY']}&cx=#{ENV['ENGINE_ID']}&safe=high&q=%s"
  KEYWORD_URL = "https://labs.goo.ne.jp/api/keyword"

  def self.run(search_query)
    words = wordlize(search_query)
    snippet = get_snippet(search_query)
    res = keyword(snippet)
    keys = JSON.parse(res)['keywords'].map { |hash| hash.keys.first }
    keys.each do |key|
      unless words.include?(key)
        return key
      end
    end
  end

  def self.get_snippet(word)
    res = JSON.parse(HTTP.get(SEARCH_URL_BASE % URI.encode(word)).to_s)
    res['items'].sample['snippet']
  end

  def self.keyword(paragrah)
    params = {
      app_id: ENV['GOO_APP_ID'],
      title: 'keyword',
      body: paragrah,
    }
    HTTP.post(KEYWORD_URL, json: params)
  end

  def self.wordlize(text)
    words = []
    natto = Natto::MeCab.new
    natto.parse(text) do |n|
      words << n.surface
    end
    words
  end
end
