require 'http'
require 'uri'
require 'dotenv/load'

class ImageSearch
  SEARCH_URL_BASE="https://www.googleapis.com/customsearch/v1?key=#{ENV['GOOGLE_API_KEY']}&cx=#{ENV['ENGINE_ID']}&searchType=image&safe=high&q=%s"

  def self.run(query)
    JSON.parse(HTTP.get(SEARCH_URL_BASE % URI.encode(query)).to_s)
  end
end

#res = ImageSearch.run('りんご')
#puts res['items'][0]
