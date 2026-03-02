using MPSGE
using DataFrames


# Translation of `bigmps.gms` into Julia style
include("big/Competitive.jl")
using .Competitive

@doc Competitive

countries = [Competitive.Country(i, j) for i in 1:9, j in 1:11]
factors = [Competitive.Labor(), Competitive.Capital()]
goods = [Competitive.Good(g) for g in 1:11]


M = Competitive.competitive_model(countries, factors, goods);
solve!(M)
df = generate_report(M)


df |>
    x -> subset(x, :value => ByRow(==(0)))


# A direct translation of the GAMS code, no special Julia structures
include("big/CompetitiveDirect.jl")
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(1:9, 1:11, [:L, :K], 1:11);

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

var = M[:Export][Competitive.Country(2,6), Competitive.Good(6)]
value(var)
value(zero_profit(var))

var_d = M_direct[:EX][2,6,6]
value(var_d)
value(zero_profit(var_d))


zero_profit(var)

zero_profit(var_d)