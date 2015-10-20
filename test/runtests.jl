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

f(:: @Anon(a, b)) = 1
f(:: @Anon(x :: Int, y :: AbstractString)) = 2
f(:: @Anon(:: Integer, :: AbstractFloat, :: Vector)) = 3

g(:: @Type(a, b)) = 1
g(:: @Type(x :: Int, y :: AbstractString)) = 2
g(:: @Type(:: Integer, :: AbstractFloat, :: Vector)) = 3

g(:: @Immutable(a, b)) = 4
g(:: @Immutable(x :: Int, y :: AbstractString)) = 5
g(:: @Immutable(:: Integer, :: AbstractFloat, :: Vector)) = 6

x_1 = @type      a = 1 b = 2
x_2 = @immutable a = 2 b = 3

y_1 = @type      x = 1 y = ""
y_2 = @immutable x = 1 y = ""

z_1 = @type      a = 1 b = 1.0 c = [1, 2, 3]
z_2 = @immutable a = 1 b = 1.0 c = [1, 2, 3]

@test f(x_1) == 1
@test g(x_1) == 1
@test f(x_2) == 1
@test g(x_2) == 4

@test f(y_1) == 2
@test g(y_1) == 2
@test f(y_2) == 2
@test g(y_2) == 5

@test f(z_1) == 3
@test g(z_1) == 3
@test f(z_2) == 3
@test g(z_2) == 6

@test_throws ErrorException AnonymousTypes.buildsig(true, 1)

end
