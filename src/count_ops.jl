prepare_call!(vars, expr) = expr
prepare_call!(vars, s::Symbol) = esc(s)

function prepare_call!(vars, e::Expr)
    e.head == :$ || return Expr(e.head, map(x->prepare_call!(vars, x), e.args)...)

    var = gensym()
    push!(vars, :($var = $(prepare_call!(vars, e.args[1]))))
    var
end

prepare_call(e) = let v=[]
    e2 = prepare_call!(v, e)
    v, e2
end

function count_ops(funcall)
    v, e = prepare_call(funcall)
    quote
        let
            ctx = CounterCtx(metadata=Counter())
            $(v...)
            Cassette.overdub(ctx, ()->begin
                             $e
                             end)
            ctx.metadata
        end
    end
end

macro count_ops(funcall)
    count_ops(funcall)
end
