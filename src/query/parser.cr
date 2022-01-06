def underscore(camel_cased_word)
  word = camel_cased_word

  while (i = (/[A-Z]/ =~ word))
    b = word[0...i.to_i]
    s = i > 0 ? "_" : ""
    m = word[i].downcase
    e = word[i + 1..word.size]
    word = "#{b}#{s}#{m}#{e}"
  end
  word
end

module Query
  class Parser
    enum MatchType
      Contains
      BeginsWith
      Exact
    end

    enum TermType
      Term
      Operator
    end

    struct Bracket
      property open : String
      property close : String

      def initialize(@open = "", @close = "")
      end
    end

    struct Term
      property type : TermType
      property value : String
      property brackets : Bracket

      def initialize(@type : TermType, @value : String, @brackets : Bracket)
      end

      def to_s
        "#{@brackets.open}#{@value}#{@brackets.close}"
      end
    end

    struct Query
      property index : String
      property match : MatchType
      property terms : Array(Term)

      def initialize(@index : String, @match : MatchType, @terms : Array(Term))
      end

      def to_s
        terms_s = ""
        @terms.each do |term|
          if @terms.last == term && term.type == TermType::Operator
            terms_s += "," if terms_s.size > 0
          else
            terms_s += " " if terms_s.size > 0
          end

          terms_s += term.to_s
        end

        "#{@index},#{underscore(@match.to_s)},#{terms_s.rchop(" ")}"
      end
    end

    def initialize(@index_map = {} of String => Hash(String, String) | String)
      @open_bracket = 0
      @close_bracket = 0
    end

    def parse(query)
      tokens = tokenize(query)

      queries = [] of Query

      query = Query.new(index: "any", match: MatchType::Contains, terms: [] of Term)
      tokens.each do |token|
        next if token.blank?
        
        if is_index?(token)
          if @open_bracket == @close_bracket
            query.terms = cleanup_query_term(query.terms)
            queries << query unless query.terms.empty?
          else
            raise "query error: brackets do not match"
          end
          query = Query.new(index: "any", match: MatchType::Contains, terms: [] of Term)
          query.index = @index_map.includes?(token.rchop) ? token.rchop : "any"
        elsif is_operator?(token)
          query.terms << Term.new(TermType::Operator, token, Bracket.new("", ""))
        elsif is_term?(token)
          if token[0] == '^'
            query.match = MatchType::BeginsWith
            token = token[1..-1]
          end

          brackets, token = extract_brackets_from_token(token)
          query.terms << Term.new(TermType::Term, token, brackets)
        else
          puts "unknown #{token}"
        end
      end

      if @open_bracket == @close_bracket
        query.terms = cleanup_query_term(query.terms)
        queries << query unless query.terms.empty?
      else
        raise "query error: brackets do not match"
      end

      collapse_if_exact_match(queries)
    end

    private def extract_brackets_from_token(token)      
      brackets = Bracket.new((token.match(/(^\(*)/) || ["", ""])[1], (token.match(/(\)*$)/) || ["", ""])[1])
      #brackets = Bracket.new((token.match(/(^\(*)/) || ["", ""])[1], (token.match(/(\)*$)/) || ["", ""])[1])
      token = token.gsub(/(^\(*)/, "").gsub(/(\)*$)/, "")
      return brackets, token
    end

    private def collapse_if_exact_match(queries : Array(Query))
      new_queries = [] of Query
      queries.each do |query|
        if query.terms.first.value =~ /^["|']/ && query.terms.last.value =~ /["|']$/
          new_queries << Query.new(index: query.index,
            match: MatchType::Exact,
            terms: [Term.new(TermType::Term,
                      query.terms.map { |m| m.value }.join(" "),
                      Bracket.new("", ""))]
          )
        else
          new_queries << query
        end
      end

      new_queries
    end

    private def cleanup_query_term(terms = [] of Term)
      i = 0
      new_terms = [] of Term

      terms.each do |t|
        if t.type == TermType::Term
          term = t.value
          # remove dangling boolean operator
          unless (term.strip =~ /(AND|OR|NOT)$/).nil?
            term = term.strip.gsub(/(AND|OR|NOT)$/, "").strip
          end

          # remove needles quotes
          #                term = term.gsub(/(^"|')|("|'$)/, "")
          term.strip

          t.value = term

          new_terms << t
        else
          new_terms << t
        end

        i += 1
      end

      new_terms
    end

    private def tokenize(query : String)
      # query = query.encode("UTF-8", invalid: :replace)
      query = query.gsub(/\b *?: *?/, ": ") # remove
      query = query.gsub(/ {1,}/, " ")
      query.split(" ")
    end

    private def is_index?(possible_index)
      if possible_index[-1] == ':'
        return @index_map.includes?(possible_index.rchop)
      end
      return false
    rescue e
      return false
    end

    private def is_term?(possible_term)
      return false if possible_term.nil?
      return false if is_operator?(possible_term)

      @open_bracket += possible_term.scan(/\(|\[|\"|\"/).size || 0
      @close_bracket += possible_term.scan(/\)|\]|\"|\"/).size || 0
      return true
    rescue e
      return false      
    end

    private def is_operator?(possible_operator)
      operators = %w(AND OR NOT)
      operators.includes?(possible_operator)
    rescue e
      return false      
    end
  end
end
