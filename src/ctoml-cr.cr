require "./libtoml"
require "./helpers"
require "./any"

# TODO: Write documentation for `Ctoml::Cr`
module CtomlCr
  VERSION = "0.1.0"

  struct TOML
    def load(file)
      raw_string = File.read(file)
      contents = LibToml.toml_parse(raw_string, out error, 200)
      if !contents
        raise CTomlCrExceptions::TomlParseError.new("Error in file: '#{file}' that prevents parsing.")
      end

      return CtomlCr::Any.new(self.fetch_table(contents))
    end

    private def fetch_table(contents)
      table = {} of String => CtomlCr::Any

      contents.value.nkval.times do |i|
        item =  contents.value.kval[i]
        key = String.new(item.value.key)

        table[key] = CtomlCr::Any.new(fetch_value(item))
      end

      contents.value.narr.times do |i|
        array_to_parse = contents.value.arr[i]
        key = String.new(array_to_parse.value.key)

        arr = CtomlCr::Any.new(fetch_array(array_to_parse))
      end

      contents.value.ntab.times do |i|
        table_to_parse = contents.value.tab[i]
        key = String.new(table_to_parse.value.key)

        table[key] = CtomlCr::Any.new(fetch_table(table_to_parse))
      end

      LibC.free(contents)

      return table
    end

    private def fetch_value(item)
      # Parse key-values, if any
      value = fetch_underlying(item.value.val)

      LibC.free(item.value.key)
      LibC.free(item.value.val)
      LibC.free(item)

      return value
    end

    private def fetch_array(array_to_parse)
      items = [] of CtomlCr::Any
      array_to_parse.value.nitem.times do |array_index|
        item = array_to_parse.value.item[array_index]
        if item.arr
          items << CtomlCr::Any.new(fetch_array(item.arr))
        elsif item.tab
          items << CtomlCr::Any.new(fetch_table(item.tab))
        else
          items << CtomlCr::Any.new(fetch_underlying(item.val))
        end
      end

      return items
    end

    private def fetch_underlying(raw)
      raw = String.new(raw)
      if raw.starts_with? '"'
        value = raw.strip('"')
      else
        begin
          value = Time::Format::RFC_3339.parse(raw)
        rescue ex : Time::Format::Error
          value = raw.to_i64
        end
      end

      return value
    end
  end
end
