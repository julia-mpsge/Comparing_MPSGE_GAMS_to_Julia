using MPSGE
using DataFrames

I = 1:9
J = 1:11
G = 1:11


# Translation of `bigmps.gms` into Julia style
include("big/Competitive.jl")
using .Competitive

@doc Competitive

countries = [Competitive.Country(i, j) for i in I, j in J]
factors = [Competitive.Labor(), Competitive.Capital()]
goods = [Competitive.Good(g) for g in G]


M = Competitive.competitive_model(countries, factors, goods);
solve!(M)
df = generate_report(M)


df |>
    x -> subset(x, :value => ByRow(==(0)))


# A direct translation of the GAMS code, no special Julia structures
include("big/CompetitiveDirect.jl")
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);

solve!(M_direct)
df_direct = generate_report(M_direct)


df_direct |>
    x -> subset(x, :value => ByRow(==(0)))

#PRODX = value.(X).!=0
#EXPORTX = value.(EX).!=0
#IMPORTX = value.(IX).!=0
#NONTRADEX = @. PRODX*(1-EXPORTX)*(1-IMPORTX)
#VOT = Dict((i,j) => 100*sum(value(PFX[g]*(EX[i,j,g]*TC[i] + IX[i,j,g])/CONS[i,j]) for g in G) for i∈I, j∈J)
#
#Welfare = value.(W)*11

# Comparing the two models, they should be the same

df |>
    x -> subset(x, 
        :value => ByRow(==(0)),
        :margin => ByRow(==(0)),
    ) 

df_direct |>
    x -> subset(x, 
        :value => ByRow(==(0)),
        :margin => ByRow(==(0)),
    ) 




for i=I, j=J, g=G
    var = M[:Producer_Price][Competitive.Country(i,j), Competitive.Good(g)]
    var_d = M_direct[:PX][i,j,g]

    if abs(value(var) - value(var_d)) > 1e-10
        println("Difference in variable for country $i, sector $j, good $g: $(value(var)) vs $(value(var_d))")
    end
end





value.(M[:Good_Production])
value.(M_direct[:X])


is_fixed.(M[:World_Price])
is_fixed.(M_direct[:PFX])


for g∈G
    var = M[:World_Price][Competitive.Good(g)]
    var_d = M_direct[:PFX][g]

    if abs(value(var) - value(var_d)) > 1e-10
        println("Difference in world price for good $g: $(value(var)) vs $(value(var_d))")
    end
end

var = M[:Producer_Price][Competitive.Country(2,2), Competitive.Good(10)]
value(var)

var_d = M_direct[:PX][2,2,10]
value(var_d)


market_clearance(var)
market_clearance(var_d)

value.(M[:Trade_Cost])
value.(M_direct[:TC])