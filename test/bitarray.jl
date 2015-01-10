B = trues(1000)
for i=1:1000
    @test findprev(B,i) == findprevnot(~B,i) == i
end

odds = bitbroadcast(isodd, 1:2000)
evens = bitbroadcast(iseven, 1:2000)
for i=1:2:2000
    @test findprev(odds,i)  == findprevnot(evens,i) == i
    @test findnext(odds,i)  == findnextnot(evens,i) == i
    @test findprev(evens,i) == findprevnot(odds,i)  == i-1
    if i < 2000
        @test findnext(evens,i) == findnextnot(odds,i)  == i+1
    else
        @test findnext(evens,i) == findnextnot(odds,i)  == 0
    end
end
for i=2:2:2000
    @test findprev(odds,i)  == findprevnot(evens,i) == i-1
    @test findprev(evens,i) == findprevnot(odds,i)  == i
    @test findnext(evens,i) == findnextnot(odds,i)  == i
    if i < 2000
        @test findnext(odds,i) == findnextnot(evens,i) == i+1
    else
        @test findnext(odds,i) == findnextnot(evens,i) == 0
    end
end

elts = (1:64:64*64+1) .+ (0:64)
B1 = falses(maximum(elts))
B1[elts] = true
B2 = fill!(Array(Bool, maximum(elts)), false)
B2[elts] = true
@test B1 == B2
@test all(B1 .== B2)
for i=1:length(maximum(elts))
    @test findprev(B1,i) == findprev(B2, i) == findprevnot(~B1, i)
    @test findnext(B1,i) == findnext(B2, i) == findnextnot(~B1, i)
end
B1 = ~B1
B2 = ~B2
@test B1 == B2
@test all(B1 .== B2)
for i=1:length(maximum(elts))
    @test findprev(B1,i) == findprev(B2, i) == findprevnot(~B1, i)
    @test findnext(B1,i) == findnext(B2, i) == findnextnot(~B1, i)
end

B = falses(1000)
B[77] = true
B[777] = true
B′ = ~B
@test_throws BoundsError findprev(B, 1001)
@test_throws BoundsError findprevnot(B′, 1001)
@test findprev(B, 1000) == findprevnot(B′, 1000) == 777
@test findprev(B, 777)  == findprevnot(B′, 777)  == 777
@test findprev(B, 776)  == findprevnot(B′, 776)  == 77
@test findprev(B, 77)   == findprevnot(B′, 77)   == 77
@test findprev(B, 76)   == findprevnot(B′, 76)   == 0
@test findprev(B, -1)   == findprevnot(B′, -1)   == 0
@test_throws BoundsError findnext(B, -1)
@test_throws BoundsError findnextnot(B′, -1)
@test findnext(B, 1)    == findnextnot(B′, 1)    == 77
@test findnext(B, 77)   == findnextnot(B′, 77)   == 77
@test findnext(B, 78)   == findnextnot(B′, 78)   == 777
@test findnext(B, 777)  == findnextnot(B′, 777)  == 777
@test findnext(B, 778)  == findnextnot(B′, 778)  == 0
@test findnext(B, 1001) == findnextnot(B′, 1001) == 0
