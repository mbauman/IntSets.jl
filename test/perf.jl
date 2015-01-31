## Performance tests
import IntSets
using DataFrames, HDF5, JLD

const REPS = 10000

function test_density(T, N)
    sz = 10000
    
    times = Float64[]
    param = Float64[]
    test = Symbol[]
    sizehint!(times, N*10*11)
    sizehint!(param, N*10*11)
    sizehint!(test, N*10*11)
    for density=logspace(-3,0,7)
        println("Density: $density")
        elts = unique(round(Int, 0:1/density:sz))
        set = sizehint!(T(),sz)
        scratch1 = sizehint!(T(), sz)
        scratch2 = sizehint!(T(), sz)
        empty = sizehint!(T(), sz)
        full = T(0:sz)
        for _=1:N
            # push!
            push!(times, @elapsed for e in elts push!(set, e); end)
            push!(param, density)
            push!(test, :push!)
        
            # Isempty
            push!(times, @elapsed isempty(set))
            push!(param, density)
            push!(test, :isempty)
        
            # Iteration (sum)
            push!(times, @elapsed sum(set))
            push!(param, density)
            push!(test, :sum)

            # Containment
            push!(times, @elapsed for e=0:sz e in set end)
            push!(param, density)
            push!(test, :in)
        
            # Intersection
            copy!(scratch1, set)
            copy!(scratch2, full)
            push!(times, @elapsed (intersect!(scratch1, full); intersect!(scratch2, set)))
            push!(param, density)
            push!(test, :intersect)

            # Union
            copy!(scratch1, set)
            copy!(scratch2, empty)
            push!(times, @elapsed (union!(scratch1, empty); union!(scratch2, set)))
            push!(param, density)
            push!(test, :union)

            # Setdiff
            copy!(scratch1, set)
            copy!(scratch2, full)
            push!(times, @elapsed (setdiff!(scratch1, full); setdiff!(scratch2, set)))
            push!(param, density)
            push!(test, :setdiff)

            # Symdiff
            copy!(scratch1, set)
            copy!(scratch2, full)
            push!(times, @elapsed (symdiff!(scratch1, full); symdiff!(scratch2, set)))
            push!(param, density)
            push!(test, :symdiff)

            # Comparison
            set2 = copy(set)
            push!(times, @elapsed set == set2)
            push!(param, density)
            push!(test, :eq)

            push!(times, @elapsed set < set2)
            push!(param, density)
            push!(test, :lt)

            push!(times, @elapsed set <= set2)
            push!(param, density)
            push!(test, :lte)
        
            # Popping
            push!(times, @elapsed for e in elts pop!(set, e); end)
            push!(param, density)
            push!(test, :pop!)
        end
    end
    (times,param,test)
end

function test_size(T, N)
    times = Float64[]
    param = Float64[]
    test = Symbol[]
    sizehint!(times, N*10*11)
    sizehint!(param, N*10*11)
    sizehint!(test, N*10*11)
    for sz=round(Int,logspace(1,5,9))
        println("Size: $sz")
        elts = 0:sz
        set = sizehint!(T(),sz)
        scratch1 = sizehint!(T(), sz)
        scratch2 = sizehint!(T(), sz)
        empty = sizehint!(T(), sz)
        full = T(0:sz)
        for _=1:N
            # Isempty
            push!(times, @elapsed isempty(set))
            push!(param, sz)
            push!(test, symbol("isempty (empty)"))

            # push!
            push!(times, @elapsed for e in elts push!(set, e); end)
            push!(param, sz)
            push!(test, :push!)
        
            # Isempty
            push!(times, @elapsed isempty(set))
            push!(param, sz)
            push!(test, symbol("isempty (full)"))
        
            # Iteration (sum)
            push!(times, @elapsed sum(set))
            push!(param, sz)
            push!(test, :sum)

            # Containment
            push!(times, @elapsed for e=0:sz e in set end)
            push!(param, sz)
            push!(test, :in)
        
            # Intersection
            copy!(scratch1, set)
            copy!(scratch2, full)
            push!(times, @elapsed (intersect!(scratch1, full); intersect!(scratch2, set)))
            push!(param, sz)
            push!(test, :intersect)

            # Union
            copy!(scratch1, set)
            copy!(scratch2, empty)
            push!(times, @elapsed (union!(scratch1, empty); union!(scratch2, set)))
            push!(param, sz)
            push!(test, :union)

            # Setdiff
            copy!(scratch1, set)
            copy!(scratch2, full)
            push!(times, @elapsed (setdiff!(scratch1, full); setdiff!(scratch2, set)))
            push!(param, sz)
            push!(test, :setdiff)

            # Symdiff
            copy!(scratch1, set)
            copy!(scratch2, full)
            push!(times, @elapsed (symdiff!(scratch1, full); symdiff!(scratch2, set)))
            push!(param, sz)
            push!(test, :symdiff)

            # Comparison
            set2 = copy!(scratch1, set)
            push!(times, @elapsed set == set2)
            push!(param, sz)
            push!(test, :eq)

            push!(times, @elapsed set < set2)
            push!(param, sz)
            push!(test, :lt)

            push!(times, @elapsed set <= set2)
            push!(param, sz)
            push!(test, :lte)
        
            # Popping
            push!(times, @elapsed for e in elts pop!(set, e); end)
            push!(param, sz)
            push!(test, :pop!)
        end
    end
    (times,param,test)
end

##
test_density(Base.IntSet, 1)
test_density(IntSets.IntSet, 1)
test_size(Base.IntSet, 1)
test_size(IntSets.IntSet, 1)

##
(time, param, fn) = test_density(Base.IntSet, REPS)
base = DataFrame(Any[time, param, fn, fill!(Array(Symbol, size(time)), :Base)], [:time, :density, :test, :module])
(time, param, fn) = test_density(IntSets.IntSet, REPS)
test = DataFrame(Any[time, param, fn, fill!(Array(Symbol, size(time)), :IntSets)], [:time, :density, :test, :module])
df = append!(base, test)
save("perf_density.jld", "df", df)

(time, param, fn) = test_size(Base.IntSet, REPS)
base = DataFrame(Any[time, param, fn, fill!(Array(Symbol, size(time)), :Base)], [:time, :size, :test, :module])
(time, param, fn) = test_size(IntSets.IntSet, REPS÷10)
test = DataFrame(Any[time, param, fn, fill!(Array(Symbol, size(time)), :IntSets)], [:time, :size, :test, :module])
df = append!(base, test)
save("perf_size.jld", "df", df)
