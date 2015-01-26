module IntSets

import Base: similar, copy, eltype, sizehint!, push!, union, union!, pop!,
             delete!, empty!, setdiff, setdiff!, symdiff!, symdiff, copy!, in,
             start, next, done, first, last, isempty, shift!, length, show,
             complement, complement!, intersect, intersect!, hash, findnextnot,
             findprevnot
export IntSet

import Base: setindex!, unsafe_bitsetindex!, _msk64, get_chunks_id

include("bitarray.jl")
include("intset.jl")

end # module
