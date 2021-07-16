require "./libtoml"
require "./helpers"
require "./any"


module TOML
  def self.load(file)
    raw_string = File.read(file)
    contents = LibToml.toml_parse(raw_string, out error, 200)
    if !contents
      raise CTomlCrExceptions::TomlParseError.new("Error in file: '#{file}' that prevents parsing.")
    end

    return TOML::Any.new(self.fetch_table(contents))
  end

  private def self.fetch_table(contents)
    table = {} of String => TOML::Any

    contents.value.nkval.times do |i|
      item =  contents.value.kval[i]
      key = String.new(item.value.key)

      table[key] = TOML::Any.new(fetch_value(item))
    end

    contents.value.narr.times do |i|
      array_to_parse = contents.value.arr[i]
      key = String.new(array_to_parse.value.key)

      arr = TOML::Any.new(fetch_array(array_to_parse))
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
        LibC.free(item.arr)
      elsif item.tab
        items << TOML::Any.new(fetch_table(item.tab))
        LibC.free(item.tab)
      else
        items << TOML::Any.new(parse_underlying(item.val))
        LibC.free(item.val)
      end
    end

    LibC.free(array_to_parse)
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
