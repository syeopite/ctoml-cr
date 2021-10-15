# ctoml-cr

Crystal bindings to the [tomlc99](https://github.com/cktan/tomlc99) library. Compliant to TOML v1.0.0.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ctoml-cr:
       github: syeopite/ctoml-cr
   ```

2. Run `shards install`

## Usage

```crystal
require "ctoml-cr"

data = File.read("example.toml")
toml = TOML.parse(data) 

# API is the same as JSON::Any
typeof(toml) # => TOML::Any

example_table = toml["example-table"].as_h
typeof(example_table) # => Hash(String, TOML::Any)
example_table["key"] # => "value"

```

## Contributing

1. Fork it (<https://github.com/syeopite/ctoml-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Credits

Special thanks to [@cktan](https://github.com/cktan) for creating tomlc99!
