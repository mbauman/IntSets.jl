## Extensions to BitArray
import Base: findprev, _div64, _mod64, _msk64, _msk_end

# returns the index of the previous non-zero element, or 0 if all zeros
function findprev(B::BitArray, start::Integer)
    start > 0 || return 0
    start > length(B) && throw(BoundsError(B, start))

    Bc = B.chunks

    chunk_start = _div64(start)+1
    within_chunk_start = _mod64(start)
    mask = ~(_msk64 << within_chunk_start)

    @inbounds begin
        if Bc[chunk_start] & mask != 0
            return (chunk_start-1) << 6 + (64 - leading_zeros(Bc[chunk_start] & mask))
        end

        for i = chunk_start-1:-1:1
            if Bc[i] != 0
                return (i-1) << 6 + (64 - leading_zeros(Bc[i]))
            end
        end
    end
    return 0
end

function findprevnot(B::BitArray, start::Integer)
    start > 0 || return 0
    start > length(B) && throw(BoundsError(B, start))

    Bc = B.chunks

    chunk_start = _div64(start)+1
    within_chunk_start = _mod64(start)
    mask = _msk64 << within_chunk_start

    @inbounds begin
        if Bc[chunk_start] | mask != _msk64
            return (chunk_start-1) << 6 + (64 - leading_ones(Bc[chunk_start] | mask))
        end

        for i = chunk_start-1:-1:1
            if Bc[i] != _msk64
                return (i-1) << 6 + (64 - leading_ones(Bc[i]))
            end
        end
    end
    return 0
end
findlastnot(B::BitArray) = findprevnot(B, length(B))

# returns the index of the first matching element
function findprev(B::BitArray, v, start::Integer)
    v ? findprev(B, start) : findprevnot(B, start)
end
#findlast(B::BitArray, v) = findprev(B, 1, v)  ## defined in array.jl

# returns the index of the first element for which the function returns true
function findprev(testf::Function, B::BitArray, start::Integer)
    f0::Bool = testf(false)
    f1::Bool = testf(true)
    !f0 && f1 && return findprev(B, start)
    f0 && !f1 && return findprevnot(B, start)

    start > 0 || return 0
    start > length(B) && throw(BoundsError(B, start))
    length(B) == 0 && return 0
    f0 && f1 && return start
    return 0 # last case: !f0 && !f1
end
#findlast(testf::Function, B::BitArray) = findprev(testf, B, 1)  ## defined in array.jl
