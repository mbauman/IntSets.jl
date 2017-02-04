# Julia 0.5
using HDF5, JLD, DataFrames, Gadfly, Colors

for (fname, param) in (("perf_density", :density),
                       ("perf_size", :size))
    !isdir(fname) && mkdir(fname)
    df = readtable(fname*".csv", header=false, names=[:time, param, :test, :module])
    bdf = by(df, [:test,:module,param]) do df
        t = df[:time]
        DataFrame(min=minimum(t), median=median(t), mean=mean(t), p95=quantile(t,.95), max=maximum(t))
    end
    for d in groupby(bdf, :test)
        p = plot(d, x=param, y=:median, ymin=:min, ymax=:p95, color=:module, 
                    Geom.line, Geom.ribbon, Scale.x_log10, Scale.y_log10, 
                    Guide.Title(string(d[:test][1])), Guide.YLabel("time (s)"),
                    Theme(background_color=colorant"white"))
        draw(PNG(joinpath(fname, string(d[:test][1], ".png")), 4inch, 3inch), p)
    end
    # Relative plots
    rdf = by(bdf, [:test,param]) do df
        t = df[:min]
        mods = df[:module]
        baset = t[mods .== "Base"]
        testt = t[mods .!= "Base"]
        DataFrame(min=testt./baset)
    end
    for d in groupby(rdf, :test)
        p = plot(d, x=param, y=:min, Geom.line, Scale.x_log10,
                    Guide.Title(string(d[:test][1])), Guide.YLabel("min relative to base"),
                    Theme(background_color=colorant"white"))
        draw(PNG(joinpath(fname, string(d[:test][1], "_rel.png")), 4inch, 3inch), p)
    end
end