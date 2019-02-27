require "./spec_helper"

describe Search do
  # TODO: Write tests

  it "should parse query" do
    qp = Query::Parser.new

    parsed = qp.parse("pre_filter:(images OR books) AND title:postkaart OR subject:^postkaart")

    stringified = parsed.map{|m| m.to_s}
    stringified[0].should eq "pre_filter,contains,(images OR books),AND"
    stringified[1].should eq "title,contains,postkaart,OR"
    stringified[2].should eq "subject,begins_with,postkaart"
  end

  it "should parse query" do
    qp = Query::Parser.new

    parsed = qp.parse("title:'wandering earth'")
    #pp parsed

    stringified = parsed.map{|m| m.to_s}
    stringified[0].should eq "title,exact,'wandering earth'"
  end

  it "should build an url, default options" do
    ps = PrimoSearch.new
    url, inst, offset, limit = ps.build_url("title:'wandering earth'")

    url.should eq "https://api-eu.hosted.exlibrisgroup.com/primo/v1/search?q=title%2Cexact%2C%27wandering%20earth%27&offset=0&limit=10&inst=KUL&vid=KULeuven&tab=all_content_tab&scope=ALL_CONTENT&sort=rank&apikey=l7xxaa2ca915ae4d46e299c9ca4348f179a8"
    inst.should eq "KUL"
    offset.should eq "0"
    limit.should eq "10"
  end

  it "should build an url, with an offset of 10" do
    ps = PrimoSearch.new
    url, inst, offset, limit = ps.build_url("title:'wandering earth'", {"from" => "10", "step" => "1"})

    offset.should eq "10"
    limit.should eq "1"
  end

  it "should execute a query" do
    ps = PrimoSearch.new
    result = ps.query("title:'wandering earth'", {"step" => "1"})

    result["step"].should eq "1"
    result["from"].should eq "0"
    result["to"].should eq "1"
    result["data"].should_not be_nil
  end

end
