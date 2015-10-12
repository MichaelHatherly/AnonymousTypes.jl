__precompile__()

"""
    AnonymousTypes

Create anonymous mutable and immutable type instances using `@type` and `@immutable` macros.
"""
module AnonymousTypes

using Base.Meta, Compat

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
    # Typed are generated on a per-module basis.
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
    expr   = Expr(:type, ismutable, name, quote end)

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
