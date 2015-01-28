type IntSet
    bits::BitVector
    inverse::Bool
    IntSet() = new(fill!(BitVector(256), false), false)
end
IntSet(itr) = union!(IntSet(), itr)

similar(s::IntSet) = IntSet()
copy(s1::IntSet) = copy!(IntSet(), s1)
function copy!(to::IntSet, from::IntSet)
    resize!(to.bits, length(from.bits))
    copy!(to.bits, from.bits)
    to.inverse = from.inverse
    to
end
eltype(s::IntSet) = Int
sizehint!(s::IntSet, sz::Integer) = (sizehint!(s.bits, sz); s)

# An internal function for setting the inclusion bit for a given integer n >= 0
@inline function _setint!(s::IntSet, n::Integer, b::Bool)
    idx = n+1
    if idx > length(s.bits)
        !b && return s # setting a bit to zero outside the set's bits is a no-op
        _resize0!(s.bits, idx + idx÷2)
    end
    Base.unsafe_setindex!(s.bits, b, idx) # Use @inbounds once available
    s
end

# An internal function to resize a bitarray and ensure the newly allocated
# elements are zeroed (will become unnecessary if this behavior changes)
@inline function _resize0!(b::BitArray, newlen::Integer)
    len = length(b)
    resize!(b, newlen)
    Base.unsafe_setindex!(b, false, len+1:newlen) # resize! gives dirty memory
    b
end

# An internal function that resizes a bitarray so it matches the length newlen
# Returns a bitvector of the removed elements (empty if none were removed)
function _matchlength!(b::BitArray, newlen::Integer)
    len = length(b)
    len > newlen && return splice!(b, newlen+1:len)
    len < newlen && _resize0!(b, newlen)
    return BitVector(0)
end
function push!(s::IntSet, n::Integer)
    n < 0 && throw(ArgumentError("elements of IntSet must not be negative"))
    _setint!(s, n, !s.inverse)
end
push!(s::IntSet, ns::Integer...) = (for n in ns; push!(s, n); end; s)

function pop!(s::IntSet)
    s.inverse && error("cannot pop the last element of complement IntSet")
    pop!(s, last(s))
end
function pop!(s::IntSet, n::Integer)
    n < 0 && throw(BoundsError(s, n))
    n in s ? (_delete!(s, n); n) : throw(KeyError(n))
end
function pop!(s::IntSet, n::Integer, default)
    n < 0 && throw(BoundsError(s, n))
    n in s ? (_delete!(s, n); n) : default
end
function pop!(f::Function, s::IntSet, n::Integer)
    n < 0 && throw(BoundsError(s, n))
    n in s ? (_delete!(s, n); n) : f()
end
_delete!(s::IntSet, n::Integer) = _setint!(s, n, s.inverse)
delete!(s::IntSet, n::Integer) = n < 0 ? s : _delete!(s, n)
shift!(s::IntSet) = pop!(s, first(s))

empty!(s::IntSet) = (fill!(s.bits, false); s.inverse = false; s)
isempty(s::IntSet) = s.inverse ? length(s.bits) == typemax(Int) && all(s.bits) : !any(s.bits)

union(s::IntSet, ns) = union!(copy(s), ns)
union!(s::IntSet, ns) = (for n in ns; push!(s, n); end; s)
function union!(s1::IntSet, s2::IntSet)
    l = length(s2.bits)
    if     !s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif  s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif !s1.inverse &  s2.inverse;  _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = true
    else #= s1.inverse &  s2.inverse=# _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
    end
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
intersect(s1::IntSet, s2::IntSet) = intersect!(copy(s1), s2)
function intersect!(s1::IntSet, s2::IntSet)
    l = length(s2.bits)
    if     !s1.inverse & !s2.inverse;  _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
    elseif  s1.inverse & !s2.inverse;  _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = false
    elseif !s1.inverse &  s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    else #= s1.inverse &  s2.inverse=# e = _matchlength!(s1.bits, l); map!($, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    end
    s1
end

setdiff(s::IntSet, ns) = setdiff!(copy(s), ns)
setdiff!(s::IntSet, ns) = (for n in ns; _delete!(s, n); end; s)
function setdiff!(s1::IntSet, s2::IntSet)
    l = length(s2.bits)
    if     !s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif  s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif !s1.inverse &  s2.inverse;  _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
    else #= s1.inverse &  s2.inverse=# _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = false
    end
    s1
end

symdiff(s::IntSet, ns) = symdiff!(copy(s), ns)
symdiff!(s::IntSet, ns) = (for n in ns; symdiff!(s, n); end; s)
function symdiff!(s::IntSet, n::Integer)
    n < 0 && throw(BoundsError(s, n))
    val = (n in s) $ !s.inverse
    _setint!(s, n, val)
    s
end
function symdiff!(s1::IntSet, s2::IntSet)
    e = _matchlength!(s1.bits, length(s2.bits))
    map!($, s1.bits, s1.bits, s2.bits)
    s2.inverse && (s1.inverse = !s1.inverse)
    append!(s1.bits, e)
    s1
end

function in(n::Integer, s::IntSet)
    (n+1 < 1) | (length(s.bits) < n+1) && return s.inverse
    s.bits[n+1] != s.inverse
end

# Use the subsequent element as the state to prevent looking it up again in done
start(s::IntSet) = next(s, 0)[2]
function next(s::IntSet, i, invert=false)
    if s.inverse $ invert
        n = findnextnot(s.bits, i+1)
        (i-1, ifelse(n == 0, max(i, length(s.bits))+1, n))
    else
        (i-1, findnext(s.bits, i+1))
    end
end
done(s::IntSet, i) = i == 0

# Nextnot iterates through elements *not* in the set
nextnot(s::IntSet, i) = next(s, i, true)

first(a::IntSet) = (s = start(a); done(a, s) ? error("collection is empty") : next(a, s)[1])
function last(s::IntSet)
    if s.inverse
        length(s.bits) < typemax(Int) ? typemax(Int)-1 : findprevnot(s.bits, typemax(Int))-1
    else
        n = findprev(s.bits, length(s.bits))-1
        n == -1 ? error("set is empty") : n
    end
end

length(s::IntSet) = (n = sum(s.bits); ifelse(s.inverse, typemax(Int) - n, n))

complement(s::IntSet) = complement!(copy(s))
complement!(s::IntSet) = (s.inverse = !s.inverse; s)

function show(io::IO, s::IntSet)
    print(io, "IntSet([")
    first = true
    for n in s
        s.inverse && n > 2 && done(s, nextnot(s, n-3)[2]) && break
        !first && print(io, ", ")
        print(io, n)
        first = false
    end
    s.inverse && print(io, ", ..., ", typemax(Int))
    print(io, "])")
end

function ==(s1::IntSet, s2::IntSet)
    l1 = length(s1.bits)
    l2 = length(s2.bits)
    if s1.inverse == s2.inverse
        l2 > l1 && ((s1, l1, s2, l2) = (s2, l2, s1, l1)) # Swap so s1 is longer
        return s1.bits[1:l2] == s2.bits && !any(s1.bits[l2+1:end])
    else
        # one complement, one not. Could actually be true on 32 bit
        return l1 == l2 == typemax(Int) && all(s1.bits .!= s2.bits)
    end
end

issubset(a::IntSet, b::IntSet) = isequal(a, intersect(a,b))
<(a::IntSet, b::IntSet) = (a<=b) && !isequal(a,b)
<=(a::IntSet, b::IntSet) = issubset(a, b)

const hashis_seed = UInt === UInt64 ? 0x88989f1fc7dea67d : 0xc7dea67d
function hash(s::IntSet, h::UInt)
    l = s.inverse ? findprevnot(s.bits, length(s.bits)) : findprev(s.bits, length(s.bits))
    hash(s.bits[1:l], h) + hashis_seed + hash(s.inverse)
end
