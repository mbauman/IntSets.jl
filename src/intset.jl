immutable IntSet
    bits::BitVector
    IntSet() = new(fill!(BitVector(256), false))
end
IntSet(itr) = union!(IntSet(), itr)

similar(s::IntSet) = IntSet()
copy(s1::IntSet) = copy!(IntSet(), s1)
function copy!(to::IntSet, from::IntSet)
    resize!(to.bits, length(from.bits))
    copy!(to.bits, from.bits)
    to
end
eltype(s::IntSet) = Int
sizehint!(s::IntSet, n::Integer) = (_resize0!(s.bits, n+1); s)

# An internal function for setting the inclusion bit for a given integer n >= 0
@inline function _setint!(s::IntSet, n::Integer, b::Bool)
    idx = n+1
    if idx > length(s.bits)
        !b && return s # setting a bit to zero outside the set's bits is a no-op
        newlen = idx + idx>>1 # This operation may overflow; we want saturation
        _resize0!(s.bits, ifelse(newlen<0, typemax(Int), newlen))
    end
    unsafe_setindex!(s.bits, b, idx) # Use @inbounds once available
    s
end

# An internal function to resize a bitarray and ensure the newly allocated
# elements are zeroed (will become unnecessary if this behavior changes)
@inline function _resize0!(b::BitVector, newlen::Integer)
    len = length(b)
    resize!(b, newlen)
    len < newlen && unsafe_setindex!(b, false, len+1:newlen) # resize! gives dirty memory
    b
end

# An internal function that takes a pure function `f` and maps across two BitArrays
# allowing the lengths to be different and altering b1 with the result
function _matched_map!{F}(f::F, b1::BitArray, b2::BitArray)
    l1, l2 = length(b1), length(b2)
    if l1 == l2
        map!(f, b1, b1, b2)
    elseif l1 < l2
        _resize0!(b1, l2)
        map!(f, b1, b1, b2)
    elseif l1 > l2
        if f(false, false) == f(true, false) == false
            # We don't need to worry about the trailing bits — they're all false
            resize!(b1, l2)
            map!(f, b1, b1, b2)
        else
            # We transiently extend b2 — as IntSet internal storage this is unobservable
            _resize0!(b2, l1)
            map!(f, b1, b1, b2)
            resize!(b2, l2)
        end
    end
    b1
end

@noinline _throw_intset_bounds_err() = throw(ArgumentError("elements of IntSet must be between 0 and typemax(Int)-1"))
@noinline _throw_keyerror(n) = throw(KeyError(n))

@inline function push!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || _throw_intset_bounds_err()
    _setint!(s, n, true)
end
push!(s::IntSet, ns::Integer...) = (for n in ns; push!(s, n); end; s)

@inline function pop!(s::IntSet)
    pop!(s, last(s))
end
@inline function pop!(s::IntSet, n::Integer)
    n in s ? (_delete!(s, n); n) : _throw_keyerror(n)
end
@inline function pop!(s::IntSet, n::Integer, default)
    n in s ? (_delete!(s, n); n) : default
end
function pop!(f::Function, s::IntSet, n::Integer)
    n in s ? (_delete!(s, n); n) : f()
end
@inline _delete!(s::IntSet, n::Integer) = _setint!(s, n, false)
@inline delete!(s::IntSet, n::Integer) = n < 0 ? s : _delete!(s, n)
shift!(s::IntSet) = pop!(s, first(s))

empty!(s::IntSet) = (fill!(s.bits, false); s)
isempty(s::IntSet) = !any(s.bits)

# Mathematical set functions: union!, intersect!, setdiff!, symdiff!

union(s::IntSet, ns) = union!(copy(s), ns)
union!(s::IntSet, ns) = (for n in ns; push!(s, n); end; s)
function union!(s1::IntSet, s2::IntSet)
    _matched_map!(|, s1.bits, s2.bits)
    s1
end

intersect(s1::IntSet) = copy(s1)
intersect(s1::IntSet, ss...) = intersect(s1, intersect(ss...))
function intersect(s1::IntSet, ns)
    s = IntSet()
    for n in ns
        n in s1 && push!(s, n)
    end
    s
end
intersect(s1::IntSet, s2::IntSet) =
    (length(s1.bits) >= length(s2.bits) ? intersect!(copy(s1), s2) : intersect!(copy(s2), s1))
function intersect!(s1::IntSet, s2::IntSet)
    _matched_map!(&, s1.bits, s2.bits)
    s1
end

setdiff(s::IntSet, ns) = setdiff!(copy(s), ns)
setdiff!(s::IntSet, ns) = (for n in ns; _delete!(s, n); end; s)
function setdiff!(s1::IntSet, s2::IntSet)
    _matched_map!(>, s1.bits, s2.bits)
    s1
end

symdiff(s::IntSet, ns) = symdiff!(copy(s), ns)
symdiff!(s::IntSet, ns) = (for n in ns; symdiff!(s, n); end; s)
function symdiff!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || _throw_intset_bounds_err()
    val = !(n in s)
    _setint!(s, n, val)
    s
end
function symdiff!(s1::IntSet, s2::IntSet)
    _matched_map!(xor, s1.bits, s2.bits)
    s1
end

@inline function in(n::Integer, s::IntSet)
    idx = n+1
    if 1 <= idx <= length(s.bits)
        unsafe_getindex(s.bits, idx)
    else
        false
    end
end

# Use the next-set index as the state to prevent looking it up again in done
start(s::IntSet) = next(s, 0)[2]
function next(s::IntSet, i)
    nextidx = i == typemax(Int) ? 0 : findnext(s.bits, i+1)
    (i-1, nextidx)
end
done(s::IntSet, i) = i <= 0


@noinline _throw_intset_notempty_error() = throw(ArgumentError("collection must be non-empty"))
function last(s::IntSet)
    l = length(s.bits)
    idx = findprev(s.bits, l)
    idx == 0 ? _throw_intset_notempty_error() : idx - 1
end

length(s::IntSet) = sum(s.bits)

function show(io::IO, s::IntSet)
    print(io, "IntSet([")
    first = true
    for n in s
        !first && print(io, ", ")
        print(io, n)
        first = false
    end
    print(io, "])")
end

function ==(s1::IntSet, s2::IntSet)
    l1 = length(s1.bits)
    l2 = length(s2.bits)
    # Do this without allocating memory or checking bit-by-bit
    # If the lengths are the same, simply punt to bitarray comparison
    l1 == l2 && return s1.bits == s2.bits

    # Swap so s1 is always longer
    if l1 < l2
        s2, s1 = s1, s2
        l2, l1 = l1, l2
    end
    # Iteratively check the chunks of the bitarrays
    c1 = s1.bits.chunks
    c2 = s2.bits.chunks
    @inbounds for i in 1:length(c2)
        c1[i] == c2[i] || return false
    end
    # Ensure remaining chunks are zero
    @inbounds for i in length(c2)+1:length(c1)
        c1[i] == UInt64(0) || return false
    end
    return true
end

issubset(a::IntSet, b::IntSet) = isequal(a, intersect(a,b))
<(a::IntSet, b::IntSet) = (a<=b) && !isequal(a,b)
<=(a::IntSet, b::IntSet) = issubset(a, b)

const hashis_seed = UInt === UInt64 ? 0x88989f1fc7dea67d : 0xc7dea67d
function hash(s::IntSet, h::UInt)
    # Only hash the bits array up to the last-set bit to prevent extra empty
    # bits from changing the hash result
    l = findprev(s.bits, length(s.bits))
    hash(s.bits[1:l], h) ⊻ hashis_seed
end
