using MPSGE
using DataFrames
using JuMP

I = 1:9
J = 1:11
G = 1:11

include("big/CompetitiveDirect.jl")
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);

solve!(M_direct)

M_mcp_d = CompetitiveDirect.mcp_competitive_model(I, J, [:L, :K], G);

optimize!(M_mcp_d)

include("big/CompetitiveDirect_modify.jl")
using .CompetitiveDirect_modify

M_modify = CompetitiveDirect_modify.competitive_model(I, J, [:L, :K], G);

solve!(M_modify)

M_mcp_m = CompetitiveDirect_modify.mcp_competitive_model(I, J, [:L, :K], G);

optimize!(M_mcp_m)


var = :PCX

var_m = M_modify[var]
var_d = M_direct[var]
var_mcp_m = M_mcp_m[var]
var_mcp_d = M_mcp_d[var]

df = DataFrame([
    (i=i, j=j, g=g, var_m = value(var_m[i,j,g]), var_d = value(var_d[i,j,g]), var_mcp_m = value(var_mcp_m[i,j,g]), var_mcp_d = value(var_mcp_d[i,j,g]))
    for i=I, j=J, g=G
])

df |>
    x -> subset(x,
        [:var_mcp_d, :var_mcp_m] => ByRow((x,y) -> abs(x-y) > 1e-10)
    ) |>
    x -> sort(x, [:i, :j, :g])

df |>
    x -> subset(x,
        [:var_d, :var_m] => ByRow((x,y) -> abs(x-y) > 1e-10)
    ) |>
    x -> sort(x, [:i, :j, :g])

df |>
    x -> subset(x,
        [:var_m, :var_mcp_m] => ByRow((x,y) -> abs(x-y) > 1e-10)
    ) |>
    x -> sort(x, [:i, :j, :g])



    df |>
    x -> subset(x,
        [:var_d] => ByRow(==(0))
    )