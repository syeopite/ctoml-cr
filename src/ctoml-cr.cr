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
# value[0] + 1       # Error, because value[0] is TOML::Any
# value[0].as_i + 10 # => 11
# ```
#
# Documentation is an edited version of the JSON module from Crystal
module TOML
  # Parse a TOML document as a `TOML::Any`.
  def self.parse(data : String)
    contents = LibToml.toml_parse(data, out error, sizeof(LibC::Char))

    if !contents
      raise CTomlCrExceptions::TomlParseError.new
    end

    return TOML::Any.new(self.fetch_table(contents))
  end

  private def self.fetch_table(contents)
    table = {} of String => TOML::Any

    contents.value.nkval.times do |i|
      item = contents.value.kval[i]
      key = String.new(item.value.key)

      table[key] = TOML::Any.new(fetch_value(item))
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

  private def self.fetch_value(item)
    # Parse key-values, if any
    value = parse_underlying(item.value.val)

    LibC.free(item.value.key)
    LibC.free(item.value.val)
    LibC.free(item)

    return value
  end

  private def self.fetch_array(array_to_parse)
    items = [] of TOML::Any
    array_to_parse.value.nitem.times do |array_index|
      item : LibToml::TomlArritemT = array_to_parse.value.item[array_index]

      # Each TomlArritemT can only store one of the following:
      if item.arr
        items << TOML::Any.new(fetch_array(item.arr))
      elsif item.tab
        items << TOML::Any.new(fetch_table(item.tab))
      else
        items << TOML::Any.new(parse_underlying(item.val))
        LibC.free(item.val)
      end
    end

    return items
  end

  private def self.parse_underlying(raw)
    raw = String.new(raw)
    if raw.starts_with? '"'
      value = raw.strip('"')
    else
      begin
        value = Time::Format::RFC_3339.parse(raw)
      rescue ex : Time::Format::Error
        value = raw.includes?(".") ? raw.to_f64 : raw.to_i64
      end
    end

    return value
  end
end

{% if flag?(:stdin_decode_mode) %}
  require "json"
  contents = STDIN.gets_to_end.strip
  begin
    STDOUT.puts TOML.parse(contents).as_h.to_json
  rescue
    exit(1)
  end
{% end %}
