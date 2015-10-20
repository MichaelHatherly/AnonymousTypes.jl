__precompile__()

"""
    AnonymousTypes

Create anonymous mutable and immutable type instances using `@type` and `@immutable` macros.
"""
module AnonymousTypes

using Base.Meta, Compat


# Dispatch macros.

export @Anon, @Type, @Immutable

abstract GeneratedType{mutable, fields, types}

"""
    @Anon(...)

Create signature for anonymous (either mutable or immutable) types. Can be used in function
definitions as follows:

```julia
f(a :: @Anon(x, y), b :: @Anon(:: Integer, y :: Vector)) = ...
```

**Syntax**

Anonymous type with 2 fields, `a` and `b`:

```julia
@Anon(a, b)
```

Anonymous type with 3 unnamed fields of type `T_i` for `i = 1:3`:

```julia
@Anon(:: T_1, :: T_2, :: T_3)
```

Anonymous type with 1 field named `a` subtyping from `Integer`:

```julia
@Anon(a :: Integer)
```
"""
macro Anon(args...) buildsig(tvar(:M), args...) end

"""
    @Type(...)

Similar to `@Anon` but limited to mutable types.
"""
macro Type(args...) buildsig(true, args...) end

"""
    @Immutable(...)

Similar to `@Anon` but limited to immutable types.
"""
macro Immutable(args...) buildsig(false, args...) end

function buildsig(mutable, args...)
    fields, types = Any[], Any[]
    for (i, x) in enumerate(args)
        f, t = term(x, i)
        push!(fields, f)
        push!(types, t)
    end
    fields, types = map(esc, fields), map(esc, types)
    :(GeneratedType{$mutable, Tuple{$(fields...)}, Tuple{$(types...)}})
end

function term(x, n)
    F_n, T_n = symbol("F_", n), symbol("T_", n)
    isexpr(x, :(::), 1) ? (tvar(F_n),       xtvar(T_n, x.args[1])) :
    isexpr(x, :(::), 2) ? (quot(x.args[1]), xtvar(T_n, x.args[2])) :
    error("invalid syntax. $x")
end
term(s :: Symbol, n) = (quot(s), tvar(symbol("T_", n)))

tvar(s)     = TypeVar(s, Any, true)
tvar(s, t)  = TypeVar(s, t, true)

xtvar(s, x) = :(TypeVar($(quot(s)), $x, true))


# Construction macros.

export @type, @immutable

@eval macro $(:type)(args...) buildcall(:m, args...) end
"""
    @type(...)

Create an anonymous mutable type instance.

**Examples**

```julia
t = @type x = 1 y = 2
t.x + t.y == 3
```

Variables may be used in place of `=` expressions:

```julia
x = 1
t = @type x y = 2
t.x + t.y == 3
```
"""
:(@type)

@eval macro $(:immutable)(args...) buildcall(:i, args...) end
"""
    @immutable(...)

Create an anonymous immutable type instance.

See `@type` for examples.
"""
:(@immutable)

function buildcall(kind, args...)
    # Types are generated on a per-module basis.
    modname = Val{hash(fullname(current_module()))}()
    names, values = Expr(:tuple), Expr(:tuple)
    for a in args
        addfields!(names.args, values.args, a)
    end
    :($(symbol(kind, "_struct"))($(esc(modname)), $(esc(names)), $(esc(values))...))
end

function addfields!(n, v, x)
    if isexpr(x, [:(=), :kw])
        push!(n, Val{x.args[1]}())
        push!(v, x.args[2])
    else
        error("invalid '@type'/'@immutable' syntax: '$x'")
    end
end
addfields!(n, v, s::Symbol) = (push!(n, Val{s}()); push!(v, s))

@generated m_struct(::Val, fields, args...) = struct(true,  fields, args...)
@generated i_struct(::Val, fields, args...) = struct(false, fields, args...)

function struct{T}(ismutable, ::Type{T}, args...)
    # Build type expression.
    fields = [x.parameters[1] for x in T.parameters]
    name   = typename(ismutable, fields, args)
    super  = GeneratedType{ismutable, Tuple{fields...}, Tuple{args...}}
    expr   = Expr(:type, ismutable, Expr(:(<:), name, super), quote end)

    expr.args[end].args = [:($x :: $y) for (x, y) in zip(fields, args)]

    # Avoid redefining the type if `struct` is run multiple times.
    isdefined(current_module(), name) || eval(current_module(), expr)

    # Return a new instance of the generated type.
    :($(current_module()).$(name)(args...))
end

function typename(ismutable, fields, args)
    id = join(["$f::$t" for (f, t) in zip(fields, args)], ", ")
    symbol("[generated $(ismutable ? "type" : "immutable")]#{$(id)}")
end

end # module
