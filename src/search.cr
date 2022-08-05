require "./search/engines/primo_search"
require "logger"

module Search
  VERSION = "0.11.0"

  class Search
    def initialize(@logger : Logger = Logger.new(STDOUT))
      @search_engine = PrimoSearch.new(@logger)
    end

    def query(q : String, options = {} of String => String)
      @search_engine.query(q, options).to_json
    rescue e
      raise e
    end

  def query(ctx : HTTP::Server::Context)
      options = @search_engine.query2options(ctx)
      raise "query parameter is missing" unless options.has_key?("query")
      @search_engine.query(options["query"], options)
    rescue e
      raise e
    end
end
end
