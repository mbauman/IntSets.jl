## Extensions to BitArray
import Base: findprev, _div64, _mod64, _msk64, _msk_end
import Base: Callable, IdFun, AndFun, OrFun, Func, map, map!, _msk_end

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

## Map

# Specializing map is much more important for bitarrays than it is for generic
# arrays since there can be a 64x speedup by working at the level of Int64
# instead of looping bit-by-bit.

# Note that there are 16 possible pure two-argument logical functions,
# of which six are trivial and two don't exist as a single function in Base:
##############################################################################
##  p = TTFF                          ##  p = TTFF                          ##
##  q = TFTF    function  name        ##  q = TFTF    function  name        ##
##  --------------------------------  ##  --------------------------------- ##
##      TTTT    (true)    -           ##      FFFF    (false)   -           ##
##      TTTF    |, max    or          ##      FFFT    ???       (nor)       ##
##      TTFT    >=, ^     ???         ##      FFTF    <         ???         ##
##      TTFF    (A)       -           ##      FFTT    (~A)      -           ##
##      TFTT    <=        implies     ##      FTFF    >         notimplies  ##
##      TFTF    (B)       -           ##      FTFT    (~B)      -           ##
##      TFFT    ==        xnor        ##      FTTF    $, !=     xor         ##
##      TFFF    &, *, min and         ##      FTTT    ???       (nand)      ##
##############################################################################

immutable NotFun <: Func{1} end
call(::NotFun, x) = ~x

# Use IdFun, AndFun, and OrFun from reduce.jl

immutable POrNotQFun <: Func{2} end
call(::POrNotQFun, x, y) = x | ~y

immutable ImpliesFun <: Func{2} end
call(::ImpliesFun, x, y) = ~x | y

immutable XNorFun <: Func{2} end
call(::XNorFun, x, y) = ~(x $ y)

immutable NotPAndQFun <: Func{2} end
call(::NotPAndQFun, x, y) = ~x & y

immutable NotImpliesFun <: Func{2} end
call(::NotImpliesFun, x, y) = x & ~y

immutable XOrFun <: Func{2} end
call(::XOrFun, x, y) = x $ y

function specialized_unary(f::Callable)
    is(f, !) | is(f, ~) && return NotFun()
    is(f, identity)     && return IdFun()
    nothing
end
function specialized_binary(f::Callable)
    is(f, |)  | is(f, max) && return OrFun()
    is(f, &)  | is(f, *)   | is(f, .*) | is(f, min) && return AndFun()
    is(f, $)  | is(f, !=)  | is(f, .!=)             && return XOrFun()
    is(f, >=) | is(f, .>=) | is(f, ^)  | is(f, .^)  && return POrNotQFun()
    is(f, <=) | is(f, .<=) && return ImpliesFun()
    is(f, ==) | is(f, .==) && return XNorFun()
    is(f, <)  | is(f, .<)  && return NotPAndQFun()
    is(f, >)  | is(f, .>)  && return NotImpliesFun()
    nothing
end

function map(f::Callable, A::BitArray)
    t = specialized_unary(f)
    t != nothing ? map(t, A) : invoke(map, (Callable, AbstractArray), f, A)
end
function map(f::Callable, A::BitArray, B::BitArray)
    t = specialized_binary(f)
    t != nothing ? map(t, A, B) : invoke(map, (Callable, AbstractArray, AbstractArray), f, A, B)
end
map(f::Func{1}, A::BitArray) = map!(f, similar(A), A)
map(f::Func{2}, A::BitArray, B::BitArray) = map!(f, similar(A), A, B)

map!(f::Callable, A::BitArray) = map!(f, A, A)
function map!(f::Callable, dest::BitArray, A::BitArray)
    t = specialized_unary(f)
    t != nothing ? map!(t, dest, A) : invoke(map!, (Callable, StridedArray, StridedArray), f, dest, A)
end
function map!(f::Callable, dest::BitArray, A::BitArray, B::BitArray)
    t = specialized_binary(f)
    t != nothing ? map!(t, dest, A, B) : invoke(map!, (Callable, StridedArray, StridedArray, StridedArray), f, dest, A, B)
end

function map!(f, dest::BitArray, A::BitArray)
    size(A) == size(dest) || throw(DimensionMismatch("sizes of dest and A must match"))
    length(A) == 0 && return dest
    for i=1:length(A.chunks)-1
        dest.chunks[i] = f(A.chunks[i])
    end
    dest.chunks[end] = f(A.chunks[end]) & _msk_end(A)
    dest
end
function map!(f, dest::BitArray, A::BitArray, B::BitArray)
    size(A) == size(B) == size(dest) || throw(DimensionMismatch("sizes of dest, A, and B must all match"))
    length(A) == 0 && return dest
    for i=1:length(A.chunks)-1
        dest.chunks[i] = f(A.chunks[i], B.chunks[i])
    end
    dest.chunks[end] = f(A.chunks[end], B.chunks[end]) & _msk_end(A)
    dest
end
