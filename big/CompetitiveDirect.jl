""" 
    CompetitiveDirect

This module provides a direct translation of the GAMS code in `bigmps.gms` into 
Julia using the MPSGE framework. Variable names have not been changed from the 
GAMS code. Note that initial parameter values are set earlier in this version of
the model.

The only provided function is `competitive_model`, which constructs the MPSGE model.
The documentation string for this function provides a detailed description of the model.

# Example

```julia
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(1:9, 1:11, [:L, :K], 1:11)

solve!(M_direct)
df_direct = generate_report(M_direct)


df_direct |>
    x -> subset(x, :value => ByRow(==(0)))
```
"""
module CompetitiveDirect

    using MPSGE
    using DataFrames


    """
        competitive_model(I::UnitRange, J::UnitRange, F::Vector{Symbol}, G::UnitRange)

    Constructs a competative model using the MPSGE framework. This is a direct translation
    of the GAMS code in `bigmps.gms`, without any special Julia structures. The model is parameterized
    by the number of countries (I), the number of sectors (J), the set of factors (F), and the set of goods (G).

    # Arguments

    - `I::UnitRange`: A range representing the number of countries.
    - `J::UnitRange`: A range representing the number of sectors.
    - `F::Vector{Symbol}`: A vector of symbols representing the factors (e.g., `[:L, :K]`).
    - `G::UnitRange`: A range representing the number of goods.

    # Returns

    - `M::MPSGEModel`: An instance of the MPSGE model representing the competitive equilibrium.

    # Model Description

    ## Parameters

    ```julia
    @parameters(M, begin
        TC[i=I],              1.45-.05*i,                        (description = "Trade cost of country i")
        ENDOW[i=I, j=J, f=F], ifelse(f == :K, 120 - 10*j, 10*j), (description = "Country i's endowment j factor f")
        FX[f=F, g=G],         ifelse(f==:K, 120 - 10*g, 10*g),   (description = "Factor f's share in good g")
        SCALE,                1,                                 (description = "Size of fringe in countries")
    end)

    set_value!(TC[end], 1.0000025)
    ```

    ## Sectors

    ```julia
    @sectors(M, begin
        X[i=I,j=J ,g=G] ,  (description = "production activity for good g")
        EX[i=I,j=J,g=G] ,  (description = "export activity for good g")
        IX[i=I,j=J,g=G] ,  (description = "import activity for good g")
        XX[i=I,j=J,g=G] ,  (description = "supply of domestically produced g to home")
        W[i=I,j=J]      ,  (description = "welfare of country ij")
    end)
    ```

    ## Commodities

    ```julia
    @commodities(M, begin
        PW[i=I,j=J]     , (description = "utility price index for country j")
        PX[i=I,j=J,g=G] , (description = "domestic producer price (mc) of good G")
        PCX[i=I,j=J,g=G], (description = "domestic consumer price of good G")
        PF[i=I,j=J,f=F] , (description = "price of factor F in country ij")
        PFX[g=G]        , (description = "world (central market) price of good G")
    end)
    ```

    ## Consumer

    ```julia
    @consumer(M, CONS[i=I,j=J], description = "Income of representative consumer in ij")
    ```

    ## Production

    ```julia
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
    ```

    ## Demand

    ```julia
    @demand(M, CONS[i=I,j=J], begin
        @final_demand(PW[i,j], sum(ENDOW[i,j,f] for f in F))
        @endowment(PF[i,j,f=F], ENDOW[i,j,f])
    end)
    ```
    """
    function competitive_model(I::UnitRange, J::UnitRange, F::Vector{Symbol}, G::UnitRange)

        M = MPSGEModel()

        @parameters(M, begin
            TC[i=I],              1.45-.05*i,                        (description = "Trade cost of country i")
            ENDOW[i=I, j=J, f=F], ifelse(f == :K, 120 - 10*j, 10*j), (description = "Country i's endowment j factor f")
            FX[f=F, g=G],         ifelse(f==:K, 120 - 10*g, 10*g),   (description = "Factor f's share in good g")
            SCALE,                1,                                 (description = "Size of fringe in countries")
        end)

        set_value!(TC[end], 1.0000025)


        @sectors(M, begin
            X[i=I,j=J ,g=G] ,  (description = "production activity for good g")
            EX[i=I,j=J,g=G] ,  (description = "export activity for good g")
            IX[i=I,j=J,g=G] ,  (description = "import activity for good g")
            XX[i=I,j=J,g=G] ,  (description = "supply of domestically produced g to home")
            W[i=I,j=J]      ,  (description = "welfare of country ij")
        end)

        @commodities(M, begin
            PW[i=I,j=J]     , (description = "utility price index for country j")
            PX[i=I,j=J,g=G] , (description = "domestic producer price (mc) of good G")
            PCX[i=I,j=J,g=G], (description = "domestic consumer price of good G")
            PF[i=I,j=J,f=F] , (description = "price of factor F in country ij")
            PFX[g=G]        , (description = "world (central market) price of good G")
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

        fix(PFX[div(length(G),2)+1], 1)

        return M

    end
end

