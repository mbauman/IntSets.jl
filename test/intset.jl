## Existing base tests
import IntSets: IntSet

@test setdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == IntSet([1, 3])
@test symdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == IntSet([1, 3, 5, 6])

s2 = IntSet([1, 2, 3, 4])
setdiff!(s2, IntSet([2, 4, 5, 6]))
@test s2 == IntSet([1, 3])

# issue #7851
@test_throws ArgumentError IntSet(-1)
@test !(-1 in IntSet(1:10))

s = IntSet([1,2,10,20,200,300,1000,10000,10002])
@test last(s) == 10002
@test first(s) == 1
@test length(s) == 9
@test pop!(s) == 10002
@test length(s) == 8
@test shift!(s) == 1
@test length(s) == 7
@test !in(0,s)
@test !in(1,s)
@test in(2,s)
@test !in(10002,s)
@test in(10000,s)
# @test_throws ArgumentError first(IntSet())
@test_throws ArgumentError last(IntSet())
t = copy(s)
sizehint!(t, 20000) #check that hash does not depend on size of internal Array{UInt32, 1}
@test hash(s) == hash(t)

# issue #8570
s = IntSet(2^32)
@test length(s) == 1
@test [b for b in s] == [2^32]

## Additional tests

# Copy, copy!, similar
s1 = IntSet([1,2,3])
s2 = similar(s1)
copy!(s2, s1)
s3 = copy(s2)
@test s3 == s2 == s1
@test collect(s3) == collect(s2) == [1,2,3]

# Push, union
s1 = IntSet()
@test_throws ArgumentError push!(s1, -1)
push!(s1, 1, 10, 100, 1000)
@test collect(s1) == [1, 10, 100, 1000]
push!(s1, 606)
@test collect(s1) == [1, 10, 100, 606, 1000]
s2 = IntSet()
@test s2 === union!(s2, s1)
s3 = IntSet([1, 10, 100])
union!(s3, [1, 606, 1000])
s4 = union(IntSet([1, 100, 1000]), IntSet([10, 100, 606]))
@test s1 == s2 == s3 == s4

## pop!, delete!
s = IntSet(1:2:10)
@test pop!(s, 1) === 1
@test !(1 in s)
@test_throws KeyError pop!(s, 1)
@test_throws KeyError pop!(s, -1)
@test pop!(s, -1, 1) === 1
@test_throws ErrorException pop!(()->error(), s, -1)
@test pop!(s, 1, 0) === 0
@test s === delete!(s, 1)
for i in s; pop!(s, i); end
@test isempty(s)
x = 0
@test 1 == pop!(()->(global x; x+=1), s, 100) 
@test x == 1
push!(s, 100)
@test pop!(()->error(), s, 100) == 100
push!(s, 1:2:10...)
@test pop!(s) == 9
@test pop!(s) == 7
@test shift!(s) == 1
@test shift!(s) == 3
@test collect(s) == [5]
empty!(s)
@test isempty(s)

## Intersect
@test isempty(intersect(IntSet()))
@test isempty(intersect(IntSet(1:10), IntSet()))
@test isempty(intersect(IntSet(), IntSet(1:10)))

@test intersect(IntSet([1,2,3])) == IntSet([1,2,3])

@test intersect(IntSet(1:7), IntSet(3:10)) ==
      intersect(IntSet(3:10), IntSet(1:7)) == IntSet(3:7)

@test intersect(IntSet(1:10), IntSet(1:4), 1:5, [2,3,10]) == IntSet(2:3)

## Setdiff
s1 = IntSet(1:100)
setdiff!(s1, IntSet(1:2:100))
s2 = setdiff(IntSet(1:100), IntSet(1:2:100))
@test s1 == s2 == IntSet(2:2:100)
@test collect(s1) == collect(2:2:100)

## Symdiff
@test symdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == 
      symdiff(IntSet([2, 4, 5, 6]), IntSet([1, 2, 3, 4])) == 
      symdiff(IntSet([1, 2, 3, 4]), [2, 4, 5, 6]) == 
      symdiff(IntSet([2, 4, 5, 6]), [1, 2, 3, 4]) == IntSet([1, 3, 5, 6])

## Subsets, equality
@test IntSet(2:2:10) < IntSet(1:10)
@test !(IntSet(2:2:10) < IntSet(2:2:10))
@test IntSet(2:2:10) <= IntSet(2:10)
@test IntSet(2:2:10) <= IntSet(2:2:10)

# Test logic against Set
p = IntSet([1,2,5,6])
resize!(p.bits, 6)
q = IntSet([1,3,5,7])
resize!(q.bits, 8)
a = Set(p)
b = Set(q)
for f in (union, intersect, setdiff, symdiff)
    @test collect(f(p, p)) == sort(collect(f(a, a)))
    @test collect(f(q, q)) == sort(collect(f(b, b)))
    @test collect(f(p, q)) == sort(collect(f(a, b)))
    @test collect(f(q, p)) == sort(collect(f(b, a)))
end

## Other
s = IntSet()
push!(s, 1, 2, 100)
@test !(0 in s)
@test 1 in s
@test 2 in s
@test !(3 in s)
@test 100 in s
@test !(101 in s)
@test !(1000 in s)
@test first(s) == 1
@test last(s) == 100
@test s == IntSet([1, 2, 100])
push!(s, 1000)
@test [i for i in s] == [1, 2, 100, 1000]
@test pop!(s) == 1000
@test s == IntSet([1, 2, 100])
@test hash(s) == hash(IntSet([1, 2, 100]))

b = 1:1000
s = IntSet(b)
@test collect(s) == collect(b)
@test length(s) == length(b)
@test pop!(s, 100) == 100
@test collect(s) == [1:99; 101:1000]
@test_throws KeyError pop!(s, 100)
@test_throws KeyError pop!(s, 0)
@test pop!(s, 100, 0) == 0
@test pop!(s, 99, 0) == 99
@test pop!(()->1, s, 99) == 1
@test pop!(()->1, s, 98) == 98

show(IOBuffer(), IntSet())
