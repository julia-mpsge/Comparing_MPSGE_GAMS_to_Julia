using MPSGE
using DataFrames

#I = Symbol.("country_",1:9)
I = 1:9
J = 1:11
#J = Symbol.("endowment_",1:11)
F = [:L, :K]
G = 1:11


begin

    M = MPSGEModel()

    @parameters(M, begin
        TC[i=I],              1.45-.05*i, (description = "Trade cost of country i")
        ENDOW[i=I, j=J, f=F], ifelse(f == :K, 120 - 10*j, 10*j), (description = "Country i's endowment j factor f")
        FX[f=F, g=G],         ifelse(f==:K, 120 - 10*g, 10*g), (description = "Factor f's share in good g")
        SCALE,                1, (description = "Size of fringe in countries")
    end)

    set_value!(TC[9], 1.0000025)


    @sectors(M, begin
        X[i=I,j=J ,g=G]  , (description = "production activity for good g")
        EX[i=I,j=J,g=G] , (description = "export activity for good g")
        IX[i=I,j=J,g=G] , (description = "import activity for good g")
        XX[i=I,j=J,g=G] , (description = "supply of domestically produced g to home")
        W[i=I,j=J]    , (description = "welfare of country ij")
    end)

    @commodities(M, begin
        PW[i=I,j=J]      ,(description = "utility price index for country j")
        PX[i=I,j=J,g=G]  ,(description = "domestic producer price (mc) of good G")
        PCX[i=I,j=J,g=G] ,(description = "domestic consumer price of good G")
        PF[i=I,j=J,f=F]  ,(description = "price of factor F in country ij")
        PFX[g=G]         ,(description = "world (central market) price of good G")
    end)

    @consumer(M, CONS[i=I,j=J], description = "Income of representative consumer in ij")

    @production(M, X[i=I, j=J, g=G], [t=0, s=1], begin
        @output(PX[i,j,g], 100, t)
        @input(PF[i, j, f=F], FX[f,g], s)
    end)

    @production(M, EX[i=I, j=J, g=G], [t=0, s=0], begin
        @output(PFX[g], 100, t)
        @input(PX[i, j, g], 100*TC[i], s)
    end)

    @production(M, IX[i=I, j=J, g=G], [t=0, s=0], begin
        @output(PCX[i, j, g], 100, t)
        @input(PFX[g], 100*TC[i], s)
    end)

    @production(M, XX[i=I, j=J, g=G], [t=0, s=0], begin
        @output(PCX[i, j, g], 100, t)
        @input(PX[i, j, g], 100, s)
    end)

    @production(M, W[i=I, j=J], [t=0, s=1], begin
        @output(PW[i, j], 100, t)
        @input(PCX[i, j, g=G], 100, s)
    end)


    @demand(M, CONS[i=I,j=J], begin
        @final_demand(PW[i,j], sum(ENDOW[i,j,f] for f in F))
        @endowment(PF[i,j,f=F], ENDOW[i,j,f])
    end)
end

fix(PFX[6], 1)



solve!(M)
generate_report(M)

PRODX = value.(X).!=0
EXPORTX = value.(EX).!=0
IMPORTX = value.(IX).!=0
NONTRADEX = @. PRODX*(1-EXPORTX)*(1-IMPORTX)
VOT = Dict((i,j) => 100*sum(value(PFX[g]*(EX[i,j,g]*TC[i] + IX[i,j,g])/CONS[i,j]) for g in G) for i∈I, j∈J)

Welfare = value.(W)*11