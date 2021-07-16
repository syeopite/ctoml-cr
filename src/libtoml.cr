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
end
