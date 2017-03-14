require 'natto'
require "xmlrpc/client"

class JokeAnswer
  def self.nouns(text)
    natto = Natto::MeCab.new

    nouns = []
    natto.parse(text) do |n|
      nouns << n.surface if n.feature.split(',')[0] == '名詞'
    end 

    return nouns
  end

  def self.associated_word(words)
    server = XMLRPC::Client.new("d.hatena.ne.jp", "/xmlrpc")
    result = server.call("hatena.getSimilarWord", {
        "wordlist" => words
    })

    result['wordlist'].map {|v| v['word'] }.sample
  end

  def self.match?(status)
    status.text.match(/^RT.*/) == nil && status.text.match(/.*教えて$/) != nil
  end

end
