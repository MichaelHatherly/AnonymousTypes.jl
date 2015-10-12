module Tests

using AnonymousTypes
using Base.Test

a = @type x = 1 y = 2.0

@test a.x == 1
@test a.y == 2.0

@test fieldtype(typeof(a), :x) == Int
@test fieldtype(typeof(a), :y) == Float64

@test (a.x += 1) == 2

b = @immutable x = 1 y = Int[] z = ""

@test b.x == 1
@test b.y == Int[]
@test b.z == ""

@test fieldtype(typeof(b), :x) == Int
@test fieldtype(typeof(b), :y) == Vector{Int}
@test fieldtype(typeof(b), :z) == ASCIIString

@test_throws ErrorException (b.x += 1)

c = @type a b

@test c.a == a
@test c.b == b

@test_throws ErrorException AnonymousTypes.buildcall(:m, 1)
@test_throws ErrorException AnonymousTypes.buildcall(:m, :(x, y))

end
