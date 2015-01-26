function setindex!{T<:Integer}(B::BitArray, x::Bool, r::UnitRange{T})
    (1 <= first(r)) & (last(r) <= length(B)) || throw(BoundsError(B, r))
    unsafe_bitsetindex!(B.chunks, x, r)
    return B
end

@inline function unsafe_bitsetindex!{T<:Integer}(Bc::Array{UInt64}, x::Bool, r::UnitRange{T})
    i1, i2 = get_chunks_id(first(r))
    j1, j2 = get_chunks_id(last(r))

    if i1 == j1
        # Range spans only one chunk.
        u = (_msk64 >> (63 - j2 + i2)) << i2
        @inbounds x ? (Bc[i1] |= u) : (Bc[i1] &= ~u)
    else
        # Set the first chunk
        u = _msk64 << i2
        @inbounds x ? (Bc[i1] |= u) : (Bc[i1] &= ~u)

        # Set all chunks in between
        v = ifelse(x, _msk64, UInt64(0))
        for i = i1+1:j1-1
            @inbounds Bc[i] = v
        end

        # Se the last chunk
        w = _msk64 >> (63 - j2)
        @inbounds x ? (Bc[j1] |= w) : (Bc[j1] &= ~w)
    end
end
