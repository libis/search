require "./generic_search"
require "uri"

class PrimoSearch < GenericSearch    

  def initialize(@logger : Logger = Logger.new(STDOUT), @config_file : String ="config.json")
  end
  
  def config
    JSON.parse(File.read(@config_file))["engines"]["primo"].as_h
  rescue e
    raise "Unable to load or parse config.json"
  end

  def lds_mapping
    config["local_display"].as_h
  end

  def index_map
    config["index"].as_h
  rescue e
    raise "Unable to get index_map from config.json"
  end

  def avail_inst
    config["institution"].as_h
  end

  def alma
    config["alma"].as_h
  end


  def build_url(q, options = {} of String => String)
    query = ""
    facet = ""
    query_parser = Query::Parser.new
    parsed_query = query_parser.parse(q)
    
    parsed_query.each do |pq|
      pq.index = index_map[pq.index].as_s
      if pq.index =~ /^facet/
        facet += "," if facet.size > 0
        facet += "#{pq.index},exact,#{pq.terms.map { |m| m.to_s }.join(" ")}"
      else
        query += ";" if query.size > 0
        query += "#{pq.to_s}"
      end
    rescue e
      raise e
    end

    host = alma["host"]
    offset = options.has_key?("from") ? options["from"] : "0"
    limit = options.has_key?("step") ? options["step"] : "10"
    inst = options.has_key?("institution") ? options["institution"] : "KUL"
    sort = options.has_key?("sort") ? options["sort"] : "rank"
    apikey = options.has_key?("apikey") ? options["apikey"] : alma["apikey"]

    a_inst = avail_inst.fetch(inst.downcase, avail_inst["kul"])

    vid = a_inst["vid"]
    tab = a_inst["tab"]
    scope = a_inst["scope"]

    facets = facet.size > 0 ? "&qInclude=#{URI.encode_path(facet)}" : ""
    
    url = "https://#{host}/primo/v1/search?q=#{URI.encode_path(query)}#{facets}&offset=#{offset}&limit=#{limit}&inst=#{inst}&vid=#{vid}&tab=#{tab}&scope=#{scope}&sort=#{sort}&apikey=#{apikey}"
    @logger.info(url)
    [url, inst, offset, limit]
  rescue e
    raise e
  end

  def query(q, options = {} of String => String)
    url, inst, offset, limit = build_url(q, options)

      response = HTTP::Client.get(url)
      if response.status_code == 200
        data = JSON.parse(response.body)
        count = data["info"]["total"].as_i?

        docs = data["docs"].as_a.map do |m|
          result = {} of String => Hash(String, Array(String | Hash(String, String))) | String
          result["id"] = m["pnx"]["control"]["recordid"][0].as_s

          m["pnx"].as_h.keys.each do |section|
            section_result = {} of String => Array(String | Hash(String, String))

            result[section] = extract_pnx(m["pnx"], section, inst)
          end

          result["resolved_links"] = extract_links(m["delivery"])
          result.to_h
        end

        return {count: count.to_s,
                from: offset.to_s,
                to: (offset.to_i + limit.to_i).to_s,
                step: limit.to_s,
                data: docs}
        # return data
      else
        r = {} of String => String
        r["code"] = response.status_code.to_s
        r["message"] = response.body
        return r
      end
  end

  private def do_lds_mapping(k, inst)
    if lds_mapping.has_key?(k)
      lk = lds_mapping[k]
      #if lk.is_a?(Hash)
      if lk.is_a?(JSON::Any)
        if lk.raw.is_a?(Hash)
          k = lk.as_h.fetch(inst.downcase, "source_id")
          k = k.as_s if k.is_a?(JSON::Any)
        else
          k = lk.as_s
        end
      elsif lk.is_a?(Hash)
        k = lk.fetch(inst.downcase, "source_id")
      else
        k = lk
      end
    end

    k
  end

  private def extract_pnx(raw : JSON::Any, section : String, inst : String)
    pnx = raw.as_h
    # section_result = [] of String | Hash(String, String)
    section_result = {} of String => Array(String | Hash(String, String))    

    pnx[section].as_h.each do |k, v|
      if section == "display"
        k = do_lds_mapping(k, inst)
      end

      section_result[k] = [] of String | Hash(String, String) unless section_result.has_key?(k)      

      v = v.as_a
      v.each do |vdata|
        if vdata.as_i?
          sdata = vdata.as_i.to_s
        else
          sdata = vdata.as_s
        end

        if sdata =~ /^\$\$([[:upper:]])/
          case $1
          when "U" # url
            matched_data = sdata.match(/\$\$U(.*?)\$\$D.*/)
            if (matched_data && matched_data.size > 0)
              section_result[k] << matched_data[1]
            end
          when "C" # identifier
            idata = {} of String => String
            begin
              raw = sdata.split(";").map { |t| t.split(/\$\$[[:upper:]]/).map { |m| m = m.strip.gsub(/^<\S+ ?\/?>/, "").gsub(":", "").strip; m unless m.empty? }.compact }.to_h

              raw.each_key do |rk|
                idata[rk.gsub(":", "")] = raw[rk]
              end
            rescue exception
              idata["error"] = ""
            end
            section_result[k] << idata
          end
        else
          if sdata =~ /(.*?)\$\$Q/
            section_result[k] << $1
          else
            section_result[k] << sdata
          end
        end
      end
    end

    section_result
  rescue e
    puts e.message
    puts e.backtrace.join("\n")
    section_result = {} of String => Array(String | Hash(String, String))
  end

  private def extract_links(raw : JSON::Any)
    delivery = raw.as_h
    section_result = {} of String => Array(String | Hash(String, String))

    if delivery.has_key?("link")
      links = delivery["link"].as_a

      links.each do |link|
        link_label = link["displayLabel"].as_s
        link_url = link["linkURL"].as_s

        section_result[link_label] = [] of String | Hash(String, String) unless section_result.has_key?(link_label)
        section_result[link_label] << link_url
        section_result[link_label].uniq!
      end
    end
    section_result
  rescue e
    puts e.message
    puts e.backtrace.join("\n")
    section_result = {} of String => Array(String | Hash(String, String))
  end
end