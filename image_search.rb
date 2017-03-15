require 'http'
require 'uri'

class ImageSearch
  SEARCH_URL_BASE='https://www.googleapis.com/customsearch/v1?key=AIzaSyC8n2MqQaPGRdoXOkcxwGTKop8hOJ4NC8s&cx=000455962536622940684:sbkxaubd878&searchType=image&q=%s'

  def self.run(query)
    JSON.parse(HTTP.get(SEARCH_URL_BASE % URI.encode(query)).to_s)
  end
end

#res = ImageSearch.run('りんご')
#puts res['items'][0]
