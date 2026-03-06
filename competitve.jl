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


# Demonstrate the differences in the solutions

var = :PCX

var_m = M_modify[var];
var_d = M_direct[var];
var_mcp_m = M_mcp_m[var];
var_mcp_d = M_mcp_d[var];

df = DataFrame([
    (
        i=i, 
        j=j, 
        g=g, 
        var_m = value(var_m[i,j,g]), 
        var_d = value(var_d[i,j,g]), 
        var_mcp_m = value(var_mcp_m[i,j,g]), 
        var_mcp_d = value(var_mcp_d[i,j,g])
    )
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





# Update M_mcp_d with values from M_direct


M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);
solve!(M_direct)

M_mcp_d = CompetitiveDirect.mcp_competitive_model(I, J, [:L, :K], G);
optimize!(M_mcp_d)

## Verify solutions do not match

### Sectors
sum(value.(M_direct[:X]) .- value.(M_mcp_d[:X]))
sum(value.(M_direct[:EX]) .- value.(M_mcp_d[:EX]))
sum(value.(M_direct[:IX]) .- value.(M_mcp_d[:IX]))
sum(value.(M_direct[:XX]) .- value.(M_mcp_d[:XX]))
sum(value.(M_direct[:W]) .- value.(M_mcp_d[:W]))

### Commodities
sum(value.(M_direct[:PW]) .- value.(M_mcp_d[:PW]))
sum(value.(M_direct[:PX]) .- value.(M_mcp_d[:PX]))
sum(value.(M_direct[:PCX]) .- value.(M_mcp_d[:PCX]))
sum(value.(M_direct[:PF]) .- value.(M_mcp_d[:PF]))
sum(value.(M_direct[:PFX]) .- value.(M_mcp_d[:PFX]))

### Consumers
sum(value.(M_direct[:CONS]) .- value.(M_mcp_d[:CONS]))

## Update the start values
set_start_value.(M_mcp_d[:X], value.(M_direct[:X]));
set_start_value.(M_mcp_d[:EX], value.(M_direct[:EX]));
set_start_value.(M_mcp_d[:IX], value.(M_direct[:IX]));
set_start_value.(M_mcp_d[:XX], value.(M_direct[:XX]));
set_start_value.(M_mcp_d[:W], value.(M_direct[:W]));

set_start_value.(M_mcp_d[:PW], value.(M_direct[:PW]));
set_start_value.(M_mcp_d[:PX], value.(M_direct[:PX]));
set_start_value.(M_mcp_d[:PCX], value.(M_direct[:PCX]));
set_start_value.(M_mcp_d[:PF], value.(M_direct[:PF]));
set_start_value.(M_mcp_d[:PFX], value.(M_direct[:PFX]));

set_start_value.(M_mcp_d[:CONS], value.(M_direct[:CONS]));

## Resolve
JuMP.set_attribute(M_mcp_d, "cumulative_iteration_limit", 0)
optimize!(M_mcp_d)


## Verify solutions match

### Sectors
sum(value.(M_direct[:X]) .- value.(M_mcp_d[:X]))
sum(value.(M_direct[:EX]) .- value.(M_mcp_d[:EX]))
sum(value.(M_direct[:IX]) .- value.(M_mcp_d[:IX]))
sum(value.(M_direct[:XX]) .- value.(M_mcp_d[:XX]))
sum(value.(M_direct[:W]) .- value.(M_mcp_d[:W]))

### Commodities
sum(value.(M_direct[:PW]) .- value.(M_mcp_d[:PW]))
sum(value.(M_direct[:PX]) .- value.(M_mcp_d[:PX]))
sum(value.(M_direct[:PCX]) .- value.(M_mcp_d[:PCX]))
sum(value.(M_direct[:PF]) .- value.(M_mcp_d[:PF]))
sum(value.(M_direct[:PFX]) .- value.(M_mcp_d[:PFX]))

### Consumers
sum(value.(M_direct[:CONS]) .- value.(M_mcp_d[:CONS]))



# Update M_direct with values from M_mcp_d


M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);
solve!(M_direct)

M_mcp_d = CompetitiveDirect.mcp_competitive_model(I, J, [:L, :K], G);
optimize!(M_mcp_d)

## Verify solutions do not match
### Sectors
sum(value.(M_direct[:X]) .- value.(M_mcp_d[:X]))
sum(value.(M_direct[:EX]) .- value.(M_mcp_d[:EX]))
sum(value.(M_direct[:IX]) .- value.(M_mcp_d[:IX]))
sum(value.(M_direct[:XX]) .- value.(M_mcp_d[:XX]))
sum(value.(M_direct[:W]) .- value.(M_mcp_d[:W]))

### Commodities
sum(value.(M_direct[:PW]) .- value.(M_mcp_d[:PW]))
sum(value.(M_direct[:PX]) .- value.(M_mcp_d[:PX]))
sum(value.(M_direct[:PCX]) .- value.(M_mcp_d[:PCX]))
sum(value.(M_direct[:PF]) .- value.(M_mcp_d[:PF]))
sum(value.(M_direct[:PFX]) .- value.(M_mcp_d[:PFX]))

### Consumers
sum(value.(M_direct[:CONS]) .- value.(M_mcp_d[:CONS]))

## Update the start values
set_start_value.(M_direct[:X], value.(M_mcp_d[:X]));
set_start_value.(M_direct[:EX], value.(M_mcp_d[:EX]));
set_start_value.(M_direct[:IX], value.(M_mcp_d[:IX]));
set_start_value.(M_direct[:XX], value.(M_mcp_d[:XX]));
set_start_value.(M_direct[:W], value.(M_mcp_d[:W]));

set_start_value.(M_direct[:PW], value.(M_mcp_d[:PW]));
set_start_value.(M_direct[:PX], value.(M_mcp_d[:PX]));
set_start_value.(M_direct[:PCX], value.(M_mcp_d[:PCX]));
set_start_value.(M_direct[:PF], value.(M_mcp_d[:PF]));
set_start_value.(M_direct[:PFX], value.(M_mcp_d[:PFX]));

set_start_value.(M_direct[:CONS], value.(M_mcp_d[:CONS]));


## Resolve
solve!(M_direct, cumulative_iteration_limit=0)


# Compare MPSGE Models


M_direct = CompetitiveDirect.competitive_model(I, J, [:L, :K], G);
solve!(M_direct)

M_modify = CompetitiveDirect_modify.competitive_model(I, J, [:L, :K], G);
solve!(M_modify)

## Verify solutions do not match
### Sectors
sum(value.(M_direct[:X]) .- value.(M_modify[:X]))
sum(value.(M_direct[:EX]) .- value.(M_modify[:EX]))
sum(value.(M_direct[:IX]) .- value.(M_modify[:IX]))
sum(value.(M_direct[:XX]) .- value.(M_modify[:XX]))
sum(value.(M_direct[:W]) .- value.(M_modify[:W]))

### Commodities
sum(value.(M_direct[:PW]) .- value.(M_modify[:PW]))
sum(value.(M_direct[:PX]) .- value.(M_modify[:PX]))
sum(value.(M_direct[:PCX]) .- value.(M_modify[:PCX]))
sum(value.(M_direct[:PF]) .- value.(M_modify[:PF]))
sum(value.(M_direct[:PFX]) .- value.(M_modify[:PFX]))

### Consumers
sum(value.(M_direct[:CONS]) .- value.(M_modify[:CONS]))

## Update the start values
set_start_value.(M_direct[:X], value.(M_modify[:X]));
set_start_value.(M_direct[:EX], value.(M_modify[:EX]));
set_start_value.(M_direct[:IX], value.(M_modify[:IX]));
set_start_value.(M_direct[:XX], value.(M_modify[:XX]));
set_start_value.(M_direct[:W], value.(M_modify[:W]));

set_start_value.(M_direct[:PW], value.(M_modify[:PW]));
set_start_value.(M_direct[:PX], value.(M_modify[:PX]));
set_start_value.(M_direct[:PCX], value.(M_modify[:PCX]));
set_start_value.(M_direct[:PF], value.(M_modify[:PF]));
set_start_value.(M_direct[:PFX], value.(M_modify[:PFX]));

set_start_value.(M_direct[:CONS], value.(M_modify[:CONS]));

## Resolve
solve!(M_direct, cumulative_iteration_limit=0)
