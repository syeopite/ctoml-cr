# TOML::Any is a convenient wrapper around all possible TOML types (TOML::Any::Type) and can be used for traversing dynamic or unknown TOML structures.
#
# Aka it's the same as what `JSON::Any`, and `YAML::Any` does but for TOML.
struct TOML::Any
  # All possible TOML types
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

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index.
  # Raises if the underlying value is not an `Array`.
  def [](index : Int) : TOML::Any
    case object = @raw
    when Array
      object[index]
    else
      raise "Expected Array for #[](index : Int), not #{object.class}"
    end
  end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index, or `nil` if out of bounds.
  # Raises if the underlying value is not an `Array`.
  def []?(index : Int) : TOML::Any?
    case object = @raw
    when Array
      object[index]?
    else
      raise "Expected Array for #[]?(index : Int), not #{object.class}"
    end
  end

  # Assumes the underlying value is a `Hash` and returns the element
  # with the given key.
  # Raises if the underlying value is not a `Hash`.
  def [](key : String) : TOML::Any
    case object = @raw
    when Hash
      object[key]
    else
      raise "Expected Hash for #[](key : String), not #{object.class}"
    end
  end

  # Assumes the underlying value is a `Hash` and returns the element
  # with the given key, or `nil` if the key is not present.
  # Raises if the underlying value is not a `Hash`.
  def []?(key : String) : TOML::Any?
    case object = @raw
    when Hash
      object[key]?
    else
      raise "Expected Hash for #[]?(key : String), not #{object.class}"
    end
  end

  # Traverses the depth of a structure and returns the value.
  # Returns `nil` if not found.
  def dig?(index_or_key : String | Int, *subkeys) : TOML::Any?
    self[index_or_key]?.try &.dig?(*subkeys)
  end

  # :nodoc:
  def dig?(index_or_key : String | Int) : TOML::Any?
    case @raw
    when Hash, Array
      self[index_or_key]?
    else
      nil
    end
  end

  # Traverses the depth of a structure and returns the value, otherwise raises.
  def dig(index_or_key : String | Int, *subkeys) : TOML::Any
    self[index_or_key].dig(*subkeys)
  end

  # :nodoc:
  def dig(index_or_key : String | Int) : TOML::Any
    self[index_or_key]
  end

  # Checks that the underlying value is `Nil`, and returns `nil`.
  # Raises otherwise.
  def as_nil : Nil
    @raw.as(Nil)
  end

  # Checks that the underlying value is `Bool`, and returns its value.
  # Raises otherwise.
  def as_bool : Bool
    @raw.as(Bool)
  end

  # Checks that the underlying value is `Bool`, and returns its value.
  # Returns `nil` otherwise.
  def as_bool? : Bool?
    as_bool if @raw.is_a?(Bool)
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
  # Raises otherwise.
  def as_i : Int32
    @raw.as(Int).to_i
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
  # Returns `nil` otherwise.
  def as_i? : Int32?
    as_i if @raw.is_a?(Int)
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
  # Raises otherwise.
  def as_i64 : Int64
    @raw.as(Int).to_i64
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
  # Returns `nil` otherwise.
  def as_i64? : Int64?
    as_i64 if @raw.is_a?(Int64)
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float64`.
  # Raises otherwise.
  def as_f : Float64
    @raw.as(Float64)
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float64`.
  # Returns `nil` otherwise.
  def as_f? : Float64?
    @raw.as?(Float64)
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float32`.
  # Raises otherwise.
  def as_f32 : Float32
    @raw.as(Float).to_f32
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float32`.
  # Returns `nil` otherwise.
  def as_f32? : Float32?
    as_f32 if @raw.is_a?(Float)
  end

  # Checks that the underlying value is `String`, and returns its value.
  # Raises otherwise.
  def as_s : String
    @raw.as(String)
  end

  # Checks that the underlying value is `String`, and returns its value.
  # Returns `nil` otherwise.
  def as_s? : String?
    as_s if @raw.is_a?(String)
  end

  # Checks that the underlying value is `Array`, and returns its value.
  # Raises otherwise.
  def as_a : Array(Any)
    @raw.as(Array)
  end

  # Checks that the underlying value is `Array`, and returns its value.
  # Returns `nil` otherwise.
  def as_a? : Array(Any)?
    as_a if @raw.is_a?(Array)
  end

  # Checks that the underlying value is `Hash`, and returns its value.
  # Raises otherwise.
  def as_h : Hash(String, Any)
    @raw.as(Hash)
  end

  # Checks that the underlying value is `Hash`, and returns its value.
  # Returns `nil` otherwise.
  def as_h? : Hash(String, Any)?
    as_h if @raw.is_a?(Hash)
  end

  # :nodoc:
  def inspect(io : IO) : Nil
    @raw.inspect(io)
  end

  # :nodoc:
  def to_s(io : IO) : Nil
    @raw.to_s(io)
  end

  # :nodoc:
  def pretty_print(pp)
    @raw.pretty_print(pp)
  end

  # Returns `true` if both `self` and *other*'s raw object are equal.
  def ==(other : TOML::Any)
    raw == other.raw
  end

  # Returns `true` if the raw object is equal to *other*.
  def ==(other)
    raw == other
  end

  # See `Object#hash(hasher)`
  def_hash raw

  # :nodoc:
  def to_json(json : JSON::Builder)
    raw.to_json(json)
  end

  def to_yaml(yaml : YAML::Nodes::Builder)
    raw.to_yaml(yaml)
  end

  # Returns a new TOML::Any instance with the `raw` value `dup`ed.
  def dup
    Any.new(raw.dup)
  end

  # Returns a new TOML::Any instance with the `raw` value `clone`ed.
  def clone
    Any.new(raw.clone)
  end
end

# :nodoc:
class Object
  def ===(other : TOML::Any)
    self === other.raw
  end
end

# :nodoc:
struct Value
  def ==(other : TOML::Any)
    self == other.raw
  end
end

# :nodoc:
class Reference
  def ==(other : TOML::Any)
    self == other.raw
  end
end

# :nodoc:
class Array
  def ==(other : TOML::Any)
    self == other.raw
  end
end

# :nodoc:
class Hash
  def ==(other : TOML::Any)
    self == other.raw
  end
end
