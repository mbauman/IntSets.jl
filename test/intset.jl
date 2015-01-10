## Existing base tests
@test setdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == IntSet([1, 3])
@test symdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == IntSet([1, 3, 5, 6])

s2 = IntSet([1, 2, 3, 4])
setdiff!(s2, IntSet([2, 4, 5, 6]))
@test s2 == IntSet([1, 3])

# issue #7851
@test_throws ArgumentError IntSet(-1)
@test !(-1 in IntSet(0:10))

s = IntSet([0,1,10,20,200,300,1000,10000,10002])
@test last(s) == 10002
@test first(s) == 0
@test length(s) == 9
@test pop!(s) == 10002
@test length(s) == 8
@test shift!(s) == 0
@test length(s) == 7
@test !in(0,s)
@test !in(10002,s)
@test in(10000,s)
@test_throws ErrorException first(IntSet())
@test_throws ErrorException last(IntSet())
t = copy(s)
sizehint!(t, 20000) #check that hash does not depend on size of internal Array{UInt32, 1}
@test hash(s) == hash(t)
@test hash(complement(s)) == hash(complement(t))

# issue #8570
s = IntSet(2^32)
@test length(s) == 1
@test [b for b in s] == [2^32]
