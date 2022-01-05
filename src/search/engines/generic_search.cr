require "../../query/parser"
require "http/client"
require "logger"
require "json"

class GenericSearch
  include Enumerable(String)

  def initialize(@logger : Logger = Logger.new(STDOUT))
  end

  def query(q, options = {} of String => String)
    puts "to be implemented"
  end

  def each
    yield "to be implemented"
  end

  def size
    puts "to be implemented"
  end

  def first
    puts "to be implemented"
  end

  def last
    puts "to be implemented"
  end

  def [](i, j)
    puts "to be implemented"
  end

  def query2options(env)
    options = {} of String => String
    params = env.params.query.to_h
    # halt env, 404, "No query found! add 'query=' to url" unless params.has_key?("query")

    options["from"] = params.fetch("from", "0")
    options["step"] = params.fetch("step", "10")
    options["host"] = params.fetch("host", "limo.libis.be")
    options["institution"] = params.fetch("institution", "KUL")
    options["sort"] = params.fetch("sort", "rank")
    options["database"] = params.fetch("database", "")
    options["timeout"] = params.fetch("timeout", "100")
    options["engine"] = (params.fetch("engine", "Primo")).downcase.capitalize
    options["query"] = params["query"]

    options
  rescue ex
    puts ex.message
    {} of String => String
  end
end
