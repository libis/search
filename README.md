# search

Abstracting search for Primo

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  search:
    github: libis/search
```

## Usage

```crystal
require "search"
require "kemal"

  get "/" do |ctx|
    ctx.response.content_type = "application/json"
    begin
      halt ctx, 404, "No query found! add 'query=' to url".to_json unless ctx.params.query.has_key?("query")

      search = Search::Search.new
      result = search.query(ctx)

      data_result = [] of Hash(String, Array(Hash(String, String) | String) | Hash(String, Array(Hash(String, String) | String) | String) | String)
      
      if result.has_key?(:data)
        result_data = result[:data]

        if result_data.is_a?(Array)
          result_data.each do |data|
            #raw = {} of String => Array(Hash(String, String) | String) | String | Hash(String, Array(String) | String)
            raw = {} of String => Array(Hash(String, String) | String) | String | Hash(String, Array(Hash(String, String) | String) | String)

            raw["id"] = data["id"].to_s
            display_data = data["display"]?
            if display_data.is_a?(Hash)
              display_data.keys.each do |k|
                raw[k] = display_data[k]
              end
            end

            links_data = data["resolved_links"]?
            raw_links = {} of String => Array(Hash(String, String) | String) | String
            if links_data.is_a?(Hash)
              links_data.keys.each do |k|
                  raw_links[k] = links_data[k].select{|s| s unless s =~ /no_cover/ || s =~ /books\.google\.com/ || s =~ /syndetics/ || s.size == 0}
              end
            end

            raw["links"] = raw_links

            data_result << raw
          end

        end
        {
          "count" => result[:count],
          "from" => result[:from],
          "to" => result[:to],
          "step" => result[:step],
          "data" => data_result
        }.to_json
      else
        {
          "count" => "0",
          "from" => "0",
          "to" => "0",
          "step" => "0",
          "data" => [] of String
        }.to_json
      end
    rescue exception
      puts exception.backtrace.join("\n")
      halt ctx, 500, exception.message.to_json
    end      
  end
  
Kemal.run  
```



__config.json__ file
```json
{
    "engines": {
        "primo": {
            "index": {
                "acq_date": "acq_date",
                "acq_local": "acq_local",
                "acq_tag": "acq_tag",
                "acq_method": "acq_method",
                "acq_source": "acq_source",
                "any": "any",
                "lang": "facet_lang",
                "author": "creator",
                "available_in": "lsr02",
                "callnumber": "callnumber",
                "category_type": "lsr01",
                "collection": "lsr04",
                "isbn": "isbn",
                "issn": "issn",
                "library": "facet_library",
                "resource_type": "facet_rtype",
                "pre_filter": "facet_pfilter",
                "scope": "scope",
                "source": "facet_domain",
                "subject": "sub",
                "sys": "rid",
                "tag": "usertag",
                "title": "title",
                "topic": "facet_topic",
                "toplevel": "facet_tlevel",
                "year": "facet_creationdate",
                "vcollection": "facet_local14",
                "atoz": "facet_atoz",
                "user": "lsr09",
                "sresource_type": "facet_local16",
                "genre": "facet_genre",
                "status": "facet_local12"
            },
            "institution": {
                "lirias": {
                    "vid": "Lirias",
                    "tab": "default_tab",
                    "scope": "Lirias"
                },
                "kul": {
                    "vid": "KULeuven",
                    "tab": "all_content_tab",
                    "scope": "ALL_CONTENT"
                },
                "doks": {
                    "vid": "DOKS",
                    "tab": "doks_tab",
                    "scope": "DOKS"
                }
            },
            "alma": {
                "host":"api-eu.hosted.exlibrisgroup.com",
                "apikey": "my_secret_key"
            }
        }
    }
}
```


## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/libis/search/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [libis](https://github.com/libis) Mehmet Celik - creator, maintainer
