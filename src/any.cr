# CtomlCr::Any is a convenient wrapper around all possible TOML types (CtomlCr::Any::Type) and can be used for traversing dynamic or unknown CtomlCr structures.
#
# Aka it's the same as what `JSON::Any`, and `YAML::Any` does but for TOML.
struct CtomlCr::Any
  alias Type = String | Int64 | Float64 | Bool | Time | Hash(String, Any) | Array(Any)

  # Returns the raw underlying value.
  getter raw : Type

  def initialize(raw : Type)
    @raw = raw
  end

  # Assume the underlying toml value is an Array or a Hash and returns its size
  # raises when the underlying value is not an `Array` or `Hash`
  def size : Int32
  end
end
