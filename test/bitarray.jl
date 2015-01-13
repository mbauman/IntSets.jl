B = trues(100)
B′ = falses(100)
for i=1:100
    @test findprev(B,i)     == findprev(B,true,i) == findprev(identity,B,i)
          findprevnot(B′,i) == findprev(!,B′,i)   == i
end

odds = bitbroadcast(isodd, 1:2000)
evens = bitbroadcast(iseven, 1:2000)
for i=1:2:2000
    @test findprev(odds,i)  == findprevnot(evens,i) == i
    @test findnext(odds,i)  == findnextnot(evens,i) == i
    @test findprev(evens,i) == findprevnot(odds,i)  == i-1
    @test findnext(evens,i) == findnextnot(odds,i)  == (i < 2000 ? i+1 : 0)
end
for i=2:2:2000
    @test findprev(odds,i)  == findprevnot(evens,i) == i-1
    @test findprev(evens,i) == findprevnot(odds,i)  == i
    @test findnext(evens,i) == findnextnot(odds,i)  == i
    @test findnext(odds,i)  == findnextnot(evens,i) == (i < 2000 ? i+1 : 0)
end

elts = (1:64:64*64+1) .+ (0:64)
B1 = falses(maximum(elts))
B1[elts] = true
B1′ = ~B1
B2 = fill!(Array(Bool, maximum(elts)), false)
B2[elts] = true
@test B1 == B2
@test all(B1 .== B2)
for i=1:length(maximum(elts))
    @test findprev(B1,i) == findprev(B2, i) == findprevnot(B1′, i) == findprev(!, B1′, i)
    @test findnext(B1,i) == findnext(B2, i) == findnextnot(B1′, i) == findnext(!, B1′, i)
end
B1 = ~B1
B2 = ~B2
B1′ = ~B1
@test B1 == B2
@test all(B1 .== B2)
for i=1:length(maximum(elts))
    @test findprev(B1,i) == findprev(B2, i) == findprevnot(B1′, i) == findprev(!, B1′, i)
    @test findnext(B1,i) == findnext(B2, i) == findnextnot(B1′, i) == findnext(!, B1′, i)
end

B = falses(1000)
B[77] = true
B[777] = true
B′ = ~B
@test_throws BoundsError findprev(B, 1001)
@test_throws BoundsError findprevnot(B′, 1001)
@test_throws BoundsError findprev(!, B′, 1001)
@test_throws BoundsError findprev(identity, B, 1001)
@test_throws BoundsError findprev(x->false, B, 1001)
@test_throws BoundsError findprev(x->true, B, 1001)
@test findprev(B, 1000) == findprevnot(B′, 1000) == findprev(!, B′, 1000) == 777
@test findprev(B, 777)  == findprevnot(B′, 777)  == findprev(!, B′, 777)  == 777
@test findprev(B, 776)  == findprevnot(B′, 776)  == findprev(!, B′, 776)  == 77
@test findprev(B, 77)   == findprevnot(B′, 77)   == findprev(!, B′, 77)   == 77
@test findprev(B, 76)   == findprevnot(B′, 76)   == findprev(!, B′, 76)   == 0
@test findprev(B, -1)   == findprevnot(B′, -1)   == findprev(!, B′, -1)   == 0
@test findprev(identity, B, -1) == findprev(x->false, B, -1) == findprev(x->true, B, -1) == 0
@test_throws BoundsError findnext(B, -1)
@test_throws BoundsError findnextnot(B′, -1)
@test_throws BoundsError findnext(!, B′, -1)
@test_throws BoundsError findnext(identity, B, -1)
# @test_throws BoundsError findnext(x->false, B, -1)
# @test_throws BoundsError findnext(x->true, B, -1)
@test findnext(B, 1)    == findnextnot(B′, 1)    == findnext(!, B′, 1)    == 77
@test findnext(B, 77)   == findnextnot(B′, 77)   == findnext(!, B′, 77)   == 77
@test findnext(B, 78)   == findnextnot(B′, 78)   == findnext(!, B′, 78)   == 777
@test findnext(B, 777)  == findnextnot(B′, 777)  == findnext(!, B′, 777)  == 777
@test findnext(B, 778)  == findnextnot(B′, 778)  == findnext(!, B′, 778)  == 0
@test findnext(B, 1001) == findnextnot(B′, 1001) == findnext(!, B′, 1001) == 0
# @test findnext(identity, B, 1001) == findnext(x->false, B, 1001) == findnext(x->true, B, 1001) == 0

@test findlast(B) == findlastnot(B′) == 777
@test findfirst(B) == findfirstnot(B′) == 77

emptyvec = BitVector(0)
@test findprev(x->true, emptyvec, -1) == 0
@test_throws BoundsError findprev(x->true, emptyvec, 1)
# @test_throws BoundsError findnext(x->true, emptyvec, -1)
@test findnext(x->true, emptyvec, 1) == 0

B = falses(10)
@test findprev(x->true, B, 5) == 5
# @test findnext(x->true, B, 5) == 5
@test findprev(x->true, B, -1) == 0
# @test findnext(x->true, B, 11) == 0
@test findprev(x->false, B, 5) == 0
@test findnext(x->false, B, 5) == 0
@test findprev(x->false, B, -1) == 0
@test findnext(x->false, B, 11) == 0
@test_throws BoundsError findprev(x->true, B, 11)
# @test_throws BoundsError findnext(x->true, B, -1)

# Map: test the truth tables
p = falses(4)
q = falses(4)
p[1:2] = true
q[[1,3]] = true

@test map(~, p) == map(x->~x, p) == ~p
@test map(identity, p) == map(x->x, p) == p

@test map(&, p, q) == map((x,y)->x&y, p, q) == p & q
@test map(|, p, q) == map((x,y)->x|y, p, q) == p | q
@test map($, p, q) == map((x,y)->x$y, p, q) == p $ q

@test map(^, p, q) == map((x,y)->x^y, p, q) == p .^ q
@test map(*, p, q) == map((x,y)->x*y, p, q) == p .* q

@test map(min, p, q) == map((x,y)->min(x,y), p, q) == min(p, q)
@test map(max, p, q) == map((x,y)->max(x,y), p, q) == max(p, q)

@test map(<, p, q)  == map((x,y)->x<y, p, q)  == (p .< q)
@test map(<=, p, q) == map((x,y)->x<=y, p, q) == (p .<= q)
@test map(==, p, q) == map((x,y)->x==y, p, q) == (p .== q)
@test map(>=, p, q) == map((x,y)->x>=y, p, q) == (p .>= q)
@test map(>, p, q)  == map((x,y)->x>y, p, q)  == (p .> q)
@test map(!=, p, q) == map((x,y)->x!=y, p, q) == (p .!= q)

# map!
r = falses(4)
@test map!(~, r, p) == map!(x->~x, r, p) == ~p == r
@test map!(identity, r, p) == map!(x->x, r, p) == p == r

@test map!(&, r, p, q) == map!((x,y)->x&y, r, p, q) == p & q == r
@test map!(|, r, p, q) == map!((x,y)->x|y, r, p, q) == p | q == r
@test map!($, r, p, q) == map!((x,y)->x$y, r, p, q) == p $ q == r

@test map!(^, r, p, q) == map!((x,y)->x^y, r, p, q) == p .^ q == r
@test map!(*, r, p, q) == map!((x,y)->x*y, r, p, q) == p .* q == r

@test map!(min, r, p, q) == map!((x,y)->min(x,y), r, p, q) == min(p, q) == r
@test map!(max, r, p, q) == map!((x,y)->max(x,y), r, p, q) == max(p, q) == r

@test map!(<, r, p, q)  == map!((x,y)->x<y, r, p, q)  == (p .< q)  == r
@test map!(<=, r, p, q) == map!((x,y)->x<=y, r, p, q) == (p .<= q) == r
@test map!(==, r, p, q) == map!((x,y)->x==y, r, p, q) == (p .== q) == r
@test map!(>=, r, p, q) == map!((x,y)->x>=y, r, p, q) == (p .>= q) == r
@test map!(>, r, p, q)  == map!((x,y)->x>y, r, p, q)  == (p .> q)  == r
@test map!(!=, r, p, q) == map!((x,y)->x!=y, r, p, q) == (p .!= q) == r

for l=[0,1,63,64,65,127,128,129,255,256,257,6399,6400,6401]
    p = bitrand(l)
    q = bitrand(l)
    @test map(~, p) == ~p
    @test map(identity, p) == p
    @test map(&, p, q) == p & q
    @test map(|, p, q) == p | q
    @test map($, p, q) == p $ q
    r = BitVector(l)
    @test map!(~, r, p) == ~p == r
    @test map!(identity, r, p) == p == r
    @test map!(~, r) == ~p == r
    @test map!(&, r, p, q) == p & q == r
    @test map!(|, r, p, q) == p | q == r
    @test map!($, r, p, q) == p $ q == r
end
