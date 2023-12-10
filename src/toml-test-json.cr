require "json"

module TOML
  extend self

  def build_test_json(toml_dict : Hash(String, TOML::Any))
    JSON.build(indent = "  ") do | json |
      handle_table(json, toml_dict)
    end
  end

  private def handle_table(json : JSON::Builder, toml_dict : Hash(String, TOML::Any))
    json.object do
      toml_dict.each do |k, v|
          json.field k do
            handle_item(json, v)
          end
      end
    end
  end

  private def handle_array(json : JSON::Builder, array : Array(TOML::Any))
    json.array do
      array.each do | item |
        handle_item(json, item)
      end
    end
  end

  private def type_field(json : JSON::Builder, toml_type : String, value)
    json.object do
      json.field "type", toml_type
      json.field "value", value
    end
  end

  private def handle_item(json : JSON::Builder, value)
    case value.raw
    when Hash(String, TOML::Any) then return {handle_table(json, value.as_h)}
    when String then return {type_field(json, "string", value.as_s)}
    when Int64 then return {type_field(json, "integer", value.to_json)}
    when Float64 then return {type_field(json, "float", value.to_json)}
    when Bool then return {type_field(json, "bool", value.to_json)}
    when Array(TOML::Any) then return {handle_array(json, value.as_a)}
    when Time
      value = value.as_time
      # Taken from https://github.com/cktan/tomlc99/blob/5221b3d3d66c25a1dc6f0372b4f824f1202fe398/toml_json.c#L93-L104
      if value.year != 0 && value.hour != 0
        if value.zone.offset == 0
          return {type_field(json, "datetime", value.to_json)}
        else
          return {type_field(json, "datetime-local", value.to_json)}
        end
      elsif value.year != 0
        return {type_field(json, "date-local", value.to_json)}
      elsif value.hour != 0
        return {type_field(json, "time-local", value.to_json)}
      end
    else
      raise Exception.new("Invalid type")
      exit(1)
    end
  end
end
