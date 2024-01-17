abstract type AbstractCounter end
export Counter

@eval mutable struct Counter <: AbstractCounter
    $((:($(Symbol(op[1], typ[2])) ::Int) for op in ops for typ in typs)...)
end
Counter() = Counter(zeros(length(fieldnames(Counter)))...)

n_reads(c::AbstractCounter) = n_ops(c; match=:getindex)
n_writes(c::AbstractCounter) = n_ops(c; match=:setindex)
function n_ops(c::AbstractCounter; match=nothing, count_all::Bool = false)
    n = 0
    for fn in fieldnames(typeof(c))
        if isnothing(match)
            if count_all
                n+=getfield(c, fn)
            end
        else
            if occursin(string(match), string(fn)) || count_all
                n+=getfield(c, fn)
            end
        end
    end
    return n
end

function flop(c::AbstractCounter)
    total = 0
    for (typ, suffix) in typs
        for (name, op, cnt) in ops
            fn = Symbol(name, suffix)
            total += cnt * getfield(c, fn)
        end
    end
    total
end

function Base.show(io::IO, c::AbstractCounter)
    empty_counter = true
    for fn in fieldnames(typeof(c))
        v = getfield(c, fn)
        if v > 0
            println(io, "$fn: $(v)")
            empty_counter = false
        end
    end
    empty_counter && println(io, "Counter is empty")
end

function Base.:(==)(c1::T, c2::T) where {T <: AbstractCounter}
    all(getfield(c1, fn)==getfield(c2, fn) for fn in fieldnames(T))
end

function Base.:(*)(n::Int, c::T) where {T <: AbstractCounter}
    ret = T()
    for fn in fieldnames(T)
        setfield!(ret, fn, n*getfield(c, fn))
    end
    ret
end
