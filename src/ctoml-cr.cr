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

      return CtomlCr::Any.new(self.parse_table(contents))
    end

    private def parse_table(contents)
      table = {} of String => CtomlCr::Any

      contents.value.nkval.times do |i|
        item =  contents.value.kval[i]
        key = String.new(item.value.key)

        table[key] = CtomlCr::Any.new(parse_value(item))
      end

      return table
    end

    private def parse_value(item)
      # Parse key-values, if any
      value = parse_underlying(item.value.val)

      LibC.free(item.value.key)
      LibC.free(item.value.val)
      LibC.free(item)

      return value
    end

    private def parse_underlying(raw)
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
