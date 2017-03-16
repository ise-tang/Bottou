require 'http'
require 'dotenv/load'

class JokeAnswer
  SEARCH_URL_BASE="https://www.googleapis.com/customsearch/v1?key=#{ENV['GOOGLE_API_KEY']}&cx=#{ENV['ENGINE_ID']}&safe=high&q=%s"
  KEYWORD_URL = "https://labs.goo.ne.jp/api/keyword"

  def self.run(word)
    snippet = self.get_snippet(word)
    res = self.keyword(snippet)
    JSON.parse(res)['keywords'].first.keys.first
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

  def self.match?(status)
    status.text.match(/^RT.*/) == nil && status.text.match(/.*教えて$/) != nil
  end

end
