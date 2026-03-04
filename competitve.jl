using MPSGE
using DataFrames

I = 1:3
J = 1:3
G = 1:3

include("big/CompetitiveDirect.jl")
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);

solve!(M_direct)

M_mcp = CompetitiveDirect.mcp_competitive_model(I, J, [:L, :K], G);

optimize!(M_mcp)

include("big/CompetitiveDirect_modify.jl")
using .CompetitiveDirect_modify

M_modify = CompetitiveDirect_modify.competitive_model(I, J, [:L, :K], G);

solve!(M_modify)


var_m = M_modify[:PX]
var_d = M_direct[:PX]
var_mcp = M_mcp[:PX]

df = DataFrame([
    (i=i, j=j, g=g, var_m = value(var_m[i,j,g]), var_d = value(var_d[i,j,g]), var_mcp = value(var_mcp[i,j,g]))
    for i=I, j=J, g=G
])

df |>
    x -> subset(x,
        [:var_d, :var_mcp] => ByRow((x,y) -> abs(x-y) > 1e-10)
    )