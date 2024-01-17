module CountFlops

isequal_op(::T, ::T) where {T} = true
isequal_op(a, b) = error("oops")

function gen_count(ops, suffix)
    body = Expr(:block)
    for (name, op) in ops
        fieldname = Symbol(name, suffix)
        e = quote
            if op == $op
                ctx.metadata.$fieldname += 1
                return
            end
        end
        push!(body.args, e)
    end
    body
end

export @count_ops

include("overdub.jl")
include("counter.jl")
include("count_ops.jl")

end # module CountReadsWrites
