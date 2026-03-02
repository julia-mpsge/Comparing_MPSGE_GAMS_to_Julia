using MPSGE
using DataFrames

I = 1:9
J = 1:11
G = 1:11

include("big/CompetitiveDirect.jl")
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);

solve!(M_direct)


include("big/CompetitiveDirect_modify.jl")
using .CompetitiveDirect_modify

M_modify = CompetitiveDirect_modify.competitive_model(I, J, [:L, :K], G);

solve!(M_modify)


for i=I, j=J, g=G
    var_m = M_modify[:PX][i,j,g]
    var_d = M_direct[:PX][i,j,g]

    if abs(value(var_m) - value(var_d)) > 1e-10
        println("Difference in variable PX for i=$i, j=$j, g=$g: $(value(var_m)) vs $(value(var_d))")
    end
end

