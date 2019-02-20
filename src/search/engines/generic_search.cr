require "../..//query/parser"
require "http/client"
require "json"

class GenericSearch
    include Enumerable(String)
    
    def query(q, options = {} of String => String)
      puts "to be implemented"      
    end
    
    def each
      puts "to be implemented"    
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
    
    def [](i,j)
      puts "to be implemented"    
    end    
end