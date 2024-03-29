require "./spec_helper"

describe Search do
  # TODO: Write tests

  it "should parse query" do
    ps = PrimoSearch.new(config_file: "./spec/config.json")
    qp = Query::Parser.new(ps.index_map)

    parsed = qp.parse("pre_filter:(images OR books) AND title:postkaart OR subject:^postkaart")

    stringified = parsed.map{|m| m.to_s}
    stringified[0].should eq "pre_filter,contains,( images OR books ),AND"
    stringified[1].should eq "title,contains,postkaart,OR"
    stringified[2].should eq "subject,begins_with,postkaart,AND"
  end

  it "should parse query 'wandering earth'" do
    ps = PrimoSearch.new(config_file: "./spec/config.json")
    qp = Query::Parser.new(ps.index_map)

    parsed = qp.parse("title:'wandering earth'")
    #pp parsed

    stringified = parsed.map{|m| m.to_s}
    stringified[0].should eq "title,exact,' wandering earth ',AND"
  end


  it "should parse query 'user/year'" do
    ps = PrimoSearch.new(config_file: "./spec/config.json")
    qp = Query::Parser.new(ps.index_map)

    parsed = qp.parse("user:U0011315 year:[2010 TO 2022]")
    
    stringified = parsed.map{|m| m.to_s}
    stringified[0].should eq "user,contains,U0011315,AND"
    stringified[1].should eq "year,contains,[ 2010 TO 2022 ],AND"
  end

  it "should build an url, default options" do
    
    ps = PrimoSearch.new(config_file: "./spec/config.json")
    url, inst, offset, limit = ps.build_url("title:'wandering earth'")

    url.should eq "https://#{ps.alma["host"]}/primo/v1/search?q=title%2Cexact%2C%27%20wandering%20earth%20%27%2CAND&offset=0&limit=10&vid=32KUL_KUL:KULeuven&tab=default_tab&scope=default_scope&sort=rank&pcAvailability=true&apikey=#{ps.alma["apikey"]}"
    #url.should eq "https://#{ps.alma["host"]}/primo/v1/search?q=title%2Cexact%2C%27wandering%20earth%27%2CAND&offset=0&limit=10&vid=32KUL_KUL:KULeuven&tab=default_tab&scope=default_scope&sort=rank&pcAvailability=true&apikey=#{ps.alma["apikey"]}"
    inst.should eq "KUL"
    offset.should eq "0"
    limit.should eq "10"
  end

  it "should build an url, with an offset of 10" do    
    ps = PrimoSearch.new(config_file: "./spec/config.json")

    url, inst, offset, limit = ps.build_url("title:'wandering earth'", {"from" => "10", "step" => "1"})

    offset.should eq "10"
    limit.should eq "1"
  end

  it "should execute a query" do
    
    ps = PrimoSearch.new(config_file: "./spec/config.json")

    result = ps.query("title:'wandering earth'", {"step" => "10"})
    
    #invalid key
    # result.to_h["code"].should eq "400"
     result["from"].should eq "0"
     result["to"].should eq result["count"]
     result["data"].should_not be_nil

    #pp result["data"]
  end

  it "should search for isbn" do
    ps = PrimoSearch.new(config_file: "./spec/config.json")

    result = ps.query("isbn:1-56881-177-2", {"step" => "10", "institution" => "lirias"})

    result[:data].should_not be_nil 
    result[:data].should_not be_empty 
  end

  it "should parse a query with an implicit operator" do
    ps = PrimoSearch.new(config_file: "./spec/config.json")
    qp = Query::Parser.new(ps.index_map)

    query = "title:water subject:(oil OR vinegar)"

    parsed = qp.parse(query)    

    result = ps.query(query, {"step" => "10", "institution" => "lirias"})

    stringified = parsed.map{|m| m.to_s}
    
    stringified[0].should eq "title,contains,water,AND"
    stringified[1].should eq "subject,contains,( oil OR vinegar ),AND"

  end

end
