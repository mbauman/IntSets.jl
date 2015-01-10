module IntSets

import Base: similar, copy, eltype, sizehint!, push!, union, union!, pop!,
             delete!, empty!, setdiff, setdiff!, symdiff!, symdiff, copy!, in,
             start, next, done, first, last, isempty, shift!, length, show,
             complement, complement!, intersect, intersect!, hash, findnextnot
export IntSet

include("bitarray.jl")
include("intset.jl")

end # module
