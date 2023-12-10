require "json"

module TOML
  extend self

  def build_test_json(toml_dict : Hash(String, TOML::Any))
    JSON.build(indent = "  ") do |json|
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
      array.each do |item|
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
    when String                  then return {type_field(json, "string", value.as_s)}
    when Int64                   then return {type_field(json, "integer", value.to_json(json))}
    when Float64                 then return {type_field(json, "float", value.to_json(json))}
    when Bool                    then return {type_field(json, "bool", value.to_json(json))}
    when Array(TOML::Any)        then return {handle_array(json, value.as_a)}
    when Time
      value = value.as_time

      if value.year != 0 && (value.hour != 0 || value.minute != 0 || value.second != 0)
        if value.location != TOML::PlaceholderLocation
          if value.zone.offset == 0
            return {type_field(json, "datetime", value.to_s("%Y-%m-%dT%H:%M:%S.%3NZ"))}
          else
            return {type_field(json, "datetime", value.to_s("%Y-%m-%dT%H:%M:%S.%3N%:z"))}
          end
        else
          return {type_field(json, "datetime-local", value.to_s("%Y-%m-%dT%H:%M:%S.%3N"))}
        end
      else
        return {type_field(json, "date-local", value.to_s("%Y-%m-%d"))}
      end
    when Time::Span
      value = value.as_time_span
      return {type_field(json, "time-local", "#{value.hours}:#{value.minutes}:#{value.seconds}#{value.milliseconds > 0 ? ".#{value.milliseconds}" : ""}")}
    else
      raise Exception.new("Invalid type")
      exit(1)
    end
  end
end
