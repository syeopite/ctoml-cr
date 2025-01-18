require "./libtoml"
require "./helpers"
require "./any"

# The TOML module allows parsing TOML documents through the usage of the tomlc99 C library
#
# ### Parsing with `TOML.parse`
#
# `TOML.parse` will return an `Any`, which is a convenient wrapper around all possible TOML types,
# making it easy to traverse a complex TOML structure but requires some casts from time to time,
# mostly via some method invocations.
#
# ```
# require "ctoml-cr"
#
# value = TOML.parse("x=[1, 2, 3]") # : TOML::Any
#
# value[0]              # => 1
# typeof(value[0])      # => TOML::Any
# value[0].as_i         # => 1
# typeof(value[0].as_i) # => Int32
#
# value[0] + 1      # Error, because value[0] is TOML::Any
# value[0].as_i + 1 # => 2
# ```
#
# Documentation is an edited version of the JSON module from Crystal
module TOML
  # When a timezone isn't explicitly specified this placeholder location is used
  PlaceholderLocation = Time::Location.new("None", zones: [PlaceholderZone])
  PlaceholderZone     = Time::Location::Zone.new("None", 0, false)

  # Parse a TOML document as a `TOML::Any`.
  def self.parse(data : String)
    contents = LibToml.toml_parse(data, out error, sizeof(LibC::Char))

    if !contents
      raise CTomlCrExceptions::TomlParseError.new("Unable to parse the given TOML file")
    end

    return TOML::Any.new(self.fetch_table(contents))
  end

  private def self.fetch_table(contents)
    table = {} of String => TOML::Any

    contents.value.nkval.times do |i|
      item = contents.value.kval[i]
      key = String.new(item.value.key)
      table[key] = TOML::Any.new(fetch_key_value(contents, key))
    end

    contents.value.narr.times do |i|
      array_to_parse = contents.value.arr[i]
      key = String.new(array_to_parse.value.key)

      table[key] = TOML::Any.new(fetch_array(array_to_parse))
    end

    contents.value.ntab.times do |i|
      table_to_parse = contents.value.tab[i]
      key = String.new(table_to_parse.value.key)

      table[key] = TOML::Any.new(fetch_table(table_to_parse))
    end

    LibC.free(contents)

    return table
  end

  private def self.fetch_array(array_to_parse) : Array(TOML::Any)
    items = [] of TOML::Any

    array_to_parse.value.nitem.times do |array_index|
      raw_item : LibToml::TomlArritemT = array_to_parse.value.item[array_index]

      case raw_item
      when .arr then item = self.fetch_array(array_to_parse.value.item[array_index].arr)
      when .tab then item = self.fetch_table(array_to_parse.value.item[array_index].tab)
      else           item = self.fetch_value_array(array_to_parse, array_index)
      end

      items << TOML::Any.new(item)
    end

    return items
  end

  private macro define_fetch(name, suffix, container_name, arg_name)
    private def self.{{name.id}}({{container_name.id}}, {{arg_name.id}})
      define_fetch_string_and_timestamp {{suffix}}, {{container_name}}, {{arg_name}}

      fetch_value_type "LibToml.toml_bool_{{suffix.id}}", "b", {{container_name}}, {{arg_name}}
      fetch_value_type "LibToml.toml_int_{{suffix.id}}", "i",  {{container_name}}, {{arg_name}}
      fetch_value_type "LibToml.toml_double_{{suffix.id}}", "d", {{container_name}}, {{arg_name}}

      raise CTomlCrExceptions::TomlParseError.new("Invalid type")
    end
  end

  private macro fetch_value_type(function, location, container_name, arg_name)
    status = {{function.id}}({{container_name.id}}, {{arg_name.id}})
    if status.ok == 1
      raw_value = status.u.{{ location.id }}
      if raw_value.is_a? Int32  # Bool
        value = raw_value == 1 ? true : false
      else
        value = raw_value
      end

      return value
    end
  end

  # String and timestamp values requires freeing up memory
  private macro define_fetch_string_and_timestamp(function_suffix, container_name, arg_name)
    status = LibToml.toml_string_{{function_suffix.id}}({{container_name.id}}, {{arg_name.id}})
    if status.ok == 1
      str = String.new(status.u.s)
      LibC.free(status.u.s)

      return str
    end

    status = LibToml.toml_timestamp_{{function_suffix.id}}({{container_name.id}}, {{arg_name.id}})
    if status.ok == 1
      timestamp = self.fetch_timestamp(status.u.ts.value)
      LibC.free(status.u.ts)

      return timestamp
    end
  end

  define_fetch("fetch_key_value", "in", "table", "key")
  define_fetch("fetch_value_array", "at", "array", "index")

  private def self.fetch_timestamp(timestamp : LibToml::TomlTimestampT)
    year = self.get_time_unit(timestamp.year)
    month = self.get_time_unit(timestamp.month)
    day = self.get_time_unit(timestamp.day)
    hour = self.get_time_unit(timestamp.hour)
    minute = self.get_time_unit(timestamp.minute)
    second = self.get_time_unit(timestamp.second)
    milliseconds = self.get_time_unit(timestamp.millisec)
    z = timestamp.z.null? ? nil : String.new(timestamp.z)

    numerical_ms = milliseconds

    if milliseconds == 0
      milliseconds = ""
    else
      milliseconds = ".#{milliseconds}"
    end

    if z
      timestamp = sprintf("%04d-%02d-%02dT%02d:%02d:%02d%s%s", {year, month, day, hour, minute, second, milliseconds, z})
      return Time::Format::RFC_3339.parse(timestamp)
    else
      # Local time
      if year == month == day == 0
        # Time::Span cannot be initialized with milliseconds so we have to convert it to microseconds
        numerical_ns = numerical_ms.milliseconds.total_nanoseconds

        timestamp = Time::Span.new(days: day, hours: hour, minutes: minute, seconds: second, nanoseconds: numerical_ns.to_i)
      else
        timestamp = sprintf("%04d-%02d-%02dT%02d:%02d:%02d%s", {year, month, day, hour, minute, second, milliseconds})
        if milliseconds.empty?
          timestamp = Time.parse(timestamp, "%Y-%m-%dT%H:%M:%S", location = PlaceholderLocation)
        else
          timestamp = Time.parse(timestamp, "%Y-%m-%dT%H:%M:%S.%3N", location = PlaceholderLocation)
        end
      end

      return timestamp
    end
  end

  private def self.get_time_unit(pointer)
    return pointer.null? ? 0 : pointer.value
  end
end

{% if flag?(:stdin_decode_mode) %}
  require "./toml-test-json.cr"
  contents = STDIN.gets_to_end.strip
  begin
    STDOUT.puts TOML.build_test_json(TOML.parse(contents).as_h)
  rescue ex
    raise ex
    exit(1)
  end
{% end %}
