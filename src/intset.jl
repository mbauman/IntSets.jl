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
        newlen = idx + idx÷2 # This operation may overflow
        _resize0!(s.bits, ifelse(newlen<0, typemax(Int), newlen))
    end
    Base.unsafe_setindex!(s.bits, b, idx) # Use @inbounds once available
    s
end

# An internal function to resize a bitarray and ensure the newly allocated
# elements are zeroed (will become unnecessary if this behavior changes)
@inline function _resize0!(b::BitArray, newlen::Integer)
    len = length(b)
    resize!(b, newlen)
    len < newlen && Base.unsafe_setindex!(b, false, len+1:newlen) # resize! gives dirty memory
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

const _intset_bounds_err_msg = string("elements of IntSet must be between 0 and ", typemax(Int)-1)

function push!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    _setint!(s, n, !s.inverse)
end
push!(s::IntSet, ns::Integer...) = (for n in ns; push!(s, n); end; s)

function pop!(s::IntSet)
    s.inverse && error("cannot pop the last element of complement IntSet")
    pop!(s, last(s))
end
function pop!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    n in s ? (_delete!(s, n); n) : throw(KeyError(n))
end
function pop!(s::IntSet, n::Integer, default)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    n in s ? (_delete!(s, n); n) : default
end
function pop!(f::Function, s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
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
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
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
    0 <= n < typemax(Int) || return false
    length(s.bits) < n+1 && return s.inverse
    s.bits[n+1] != s.inverse
end

# Use the subsequent element as the state to prevent looking it up again in done
start(s::IntSet) = next(s, 0)[2]
function next(s::IntSet, i, invert=false)
    if s.inverse $ invert
        n = findnextnot(s.bits, i+1)
        (i-1, ifelse(n == 0, max(i+1, length(s.bits)), n))
    else
        (i-1, findnext(s.bits, i+1))
    end
end
done(s::IntSet, i) = (i == 0) | (i == typemax(Int))

# Nextnot iterates through elements *not* in the set
startnot(s::IntSet) = next(s, 0, true)[2]
nextnot(s::IntSet, i) = next(s, i, true)
donenot(s::IntSet, i) = i == 0

first(a::IntSet) = (s = start(a); done(a, s) ? error("set is empty") : next(a, s)[1])
function last(s::IntSet)
    if s.inverse
        length(s.bits) < typemax(Int) && return typemax(Int)-1
        n = findprevnot(s.bits, typemax(Int))-1
    else
        n = findprev(s.bits, length(s.bits))-1
    end
    n == -1 ? error("set is empty") : n
end
firstnot(a::IntSet) = (s = startnot(a); donenot(a, s) ? error("set is empty") : nextnot(a, s)[1])
function lastnot(s::IntSet)
    if !s.inverse
        length(s.bits) < typemax(Int) && return typemax(Int)-1
        n = findprevnot(s.bits, typemax(Int))-1
    else
        n = findprev(s.bits, length(s.bits))-1
    end
    n == -1 ? error("set is empty") : n
end

length(s::IntSet) = (n = sum(s.bits); ifelse(s.inverse, typemax(Int) - n, n))

complement(s::IntSet) = complement!(copy(s))
complement!(s::IntSet) = (s.inverse = !s.inverse; s)

function show(io::IO, s::IntSet)
    print(io, "IntSet([")
    first = true
    for n in s
        if s.inverse && n > 2 && done(s, nextnot(s, n-3)[2])
             print(io, ", ..., ", typemax(Int)-1)
             break
         end
        !first && print(io, ", ")
        print(io, n)
        first = false
    end
    print(io, "])")
end

function ==(s1::IntSet, s2::IntSet)
    l1 = length(s1.bits)
    l2 = length(s2.bits)
    l1 < l2 && return ==(s2, s1) # Swap so s1 is longer

    if s1.inverse == s2.inverse
        # Try to do this without allocating memory
        if l1 == l2
            return s1.bits == s2.bits
        elseif (!s1.inverse && last(s1) != last(s2)) ||
               (s1.inverse && lastnot(s1) != lastnot(s2))
            return false
        else
            return s1.bits[1:l2] == s2.bits # We know the last bits are the same
        end
    else
        # one complement, one not. Could feasibly be true on 32 bit machines
        if l1 < typemax(Int) || last(s1) != last(s2)
            return false
        else
            return map!(!, s1.bits[1:l2]) == s2.bits
        end
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
