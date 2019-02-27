require "./search/engines/primo_search"

module Search
  VERSION = "0.2.0"

  class Search
    def initialize(options = {} of String => String)
      @search_engine = PrimoSearch.new
    end

    def query(q : String, options = {} of String => String)
      @search_engine.query(q, options).to_json
    end
  end
end
