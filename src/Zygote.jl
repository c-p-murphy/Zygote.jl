__precompile__(false)

module Zygote

# This flag enables Zygote to grab extra type inference information during
# compiles. When control flow is present, this can give gradient code a
# performance boost.

# HOWEVER, this is not Jameson-approved, nor well supported by the compiler, and
# has several caveats. Recursion will cause inference to stack overflow.
# Gradient redefinitions may result in ugly type errors. And Jameson *will* know.
const usetyped = false

using IRTools
using MacroTools, Requires
using MacroTools: @forward

export Params, gradient, derivative, forward, @code_grad

map(f, args...) = Base.map(f, args...)
map(f, t::Tuple{})              = ()
map(f, t::Tuple{Any,})          = (f(t[1]),)
map(f, t::Tuple{Any, Any})      = (f(t[1]), f(t[2]))
map(f, t::Tuple{Any, Any, Any}) = (f(t[1]), f(t[2]), f(t[3]))
@inline map(f, t::Tuple)                = (f(t[1]), map(f,tail(t))...)
# 2 argument function
map(f, t::Tuple{},        s::Tuple{})        = ()
map(f, t::Tuple{Any,},    s::Tuple{Any,})    = (f(t[1],s[1]),)
map(f, t::Tuple{Any,Any}, s::Tuple{Any,Any}) = (f(t[1],s[1]), f(t[2],s[2]))
@inline function map(f, t::Tuple, s::Tuple)
    (f(t[1],s[1]), map(f, tail(t), tail(s))...)
end
# n argument function
heads(ts::Tuple...) = map(t -> t[1], ts)
tails(ts::Tuple...) = map(tail, ts)
map(f, ::Tuple{}...) = ()
@inline function map(f, t1::Tuple, t2::Tuple, ts::Tuple...)
    (f(heads(t1, t2, ts...)...), map(f, tails(t1, t2, ts...)...)...)
end

include("tools/idset.jl")
include("tools/ir.jl")
include("tools/reflection.jl")

include("compiler/reverse.jl")
include("compiler/emit.jl")
include("compiler/interface.jl")

include("lib/grad.jl")
include("lib/lib.jl")
include("lib/real.jl")
include("lib/base.jl")
include("lib/array.jl")
include("lib/nnlib.jl")
include("lib/broadcast.jl")

# helps to work around 265-y issues
function refresh()
  include(joinpath(@__DIR__, "compiler/interface2.jl"))
  include(joinpath(@__DIR__, "precompile.jl"))
  return
end

# we need to define this late, so that the genfuncs see lib.jl
include("compiler/interface2.jl")
include("precompile.jl")

@init @require Flux="587475ba-b771-5e3f-ad9e-33799f191a9c" include("flux.jl")

end # module
