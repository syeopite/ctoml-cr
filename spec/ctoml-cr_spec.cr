require "./spec_helper"

describe TOML do
  it "#parse" do
    data = File.read("spec/test.toml")
    toml = TOML.parse(data)

    toml["number"].should eq(123)
    toml["floats"].should eq(123.123)
    toml["array"].should eq([1, 2, 3, 4, 5, 6])

    toml["time1"].should eq(Time::Format::RFC_3339.parse("1987-07-05T17:45:56.123Z"))
    toml["time2"].should eq(Time.parse("1987-07-05T17:45:56.123", "%Y-%m-%dT%H:%M:%S.%3N", location: TOML::PlaceholderLocation))
    toml["time3"].should eq(Time::Format::RFC_3339.parse("1987-07-05T0:0:0.0Z"))
    toml["time4"].should eq(Time::Span.new(hours: 17, minutes: 45, seconds: 56))
    toml["time5"].should eq(Time::Span.new(hours: 17, minutes: 45, seconds: 56, nanoseconds: 123000000))

    typeof(toml["number"].as_i).should eq(Int32)
    typeof(toml["number"].as_i64).should eq(Int64)

    typeof(toml["floats"].as_f).should eq(Float64)
    typeof(toml["floats"].as_f32).should eq(Float32)

    typeof(toml["arrays"]).should eq(TOML::Any)
    typeof(toml["arrays"].as_a).should eq(Array(TOML::Any))

    toml["nested_arraies"].should eq([[1, 2, 3, 4, 5, 6, [7, 8, 9, 10, 11]], "Hello", "testing"])
    toml["table-1"].should eq({"key" => "something", "key2" => "Another key", "inline-table" => {"first" => "Tom", "last" => "Preston-Werner"}})
    toml["products"].should eq([{"name" => "Hammer", "sku" => 738594937}, Hash(String, TOML::Any).new, {"name" => "Nail", "sku" => 284758393, "color" => "gray"}])
  end
end
