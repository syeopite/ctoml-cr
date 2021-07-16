@[Link(ldflags: "#{__DIR__}/ext/libtoml.a")]
# Generated with https://github.com/crystal-lang/crystal_lib
lib LibToml
  struct TomlTableT
    key : LibC::Char*
    implicit : Bool
    readonly : Bool
    nkval : LibC::Int
    kval : TomlKeyvalT**
    narr : LibC::Int
    arr : TomlArrayT**
    ntab : LibC::Int
    tab : TomlTableT**
  end

  struct TomlKeyvalT
    key : LibC::Char*
    val : LibC::Char*
  end

  struct TomlArrayT
    key : LibC::Char*
    kind : LibC::Int
    type : LibC::Int
    nitem : LibC::Int
    item : TomlArritemT*
  end

  struct TomlArritemT
    valtype : LibC::Int
    val : LibC::Char*
    arr : TomlArrayT*
    tab : TomlTableT*
  end

  fun toml_parse(conf : LibC::Char*, errbuf : LibC::Char*, errbufsz : LibC::Int) : TomlTableT*
  fun toml_free(tab : TomlTableT*)
  fun toml_table_in(tab : TomlTableT*, key : LibC::Char*) : TomlTableT*
  fun toml_array_in(tab : TomlTableT*, key : LibC::Char*) : TomlArrayT*

  # Data container
  struct TomlDatumT
    ok : LibC::Int
    u : TomlDatumTU
  end

  # Possible data
  union TomlDatumTU
    ts : TomlTimestampT* # Timestamp
    s : LibC::Char* # String value
    b : LibC::Int# Bool value
    i : UInt64 # Interger value
    d : LibC::Double # Double value
  end

  # Timestamp
  struct TomlTimestampT
    __buffer : TomlTimestampTBuffer
    year : LibC::Int*
    month : LibC::Int*
    day : LibC::Int*
    hour : LibC::Int*
    minute : LibC::Int*
    second : LibC::Int*
    millisec : LibC::Int*
    z : LibC::Char*
  end

  struct TomlTimestampTBuffer
    year : LibC::Int
    month : LibC::Int
    day : LibC::Int
    hour : LibC::Int
    minute : LibC::Int
    second : LibC::Int
    millisec : LibC::Int
    z : LibC::Char[10]
  end

  fun toml_string_in(arr : TomlTableT*, key : LibC::Char*) : TomlDatumT
  fun toml_bool_in(arr : TomlTableT*, key : LibC::Char*) : TomlDatumT
  fun toml_int_in(arr : TomlTableT*, key : LibC::Char*) : TomlDatumT
  fun toml_double_in(arr : TomlTableT*, key : LibC::Char*) : TomlDatumT
  fun toml_timestamp_in(arr : TomlTableT*, key : LibC::Char*) : TomlDatumT
end
