#!/usr/bin/env Rscript

library(data.table)

structure.factors.file = "structure_factors.csv"
structure.factors = fread(structure.factors.file)
spectrum = fread("spectrum.csv")
thickness.map = fread("data/thickness-map-microct.csv")
norm = 1 / spectrum[, sum(total_weight)]
spectrum = spectrum[, total_weight := norm * total_weight]

mu.total = function(dfec) {
    logB = (spectrum[, total_weight] %*% dfec)
    return(logB)
}

sf = structure.factors[, mu.total(dfec_lynch), by=diameter]
setnames(sf, "V1", "mu.d")
sf[, density := thickness.map[, density]]
print(sf)
mu = sf[,density %*% mu.d]
print(mu)
print("expected dark field value:")
print(exp(-mu * 0.005))
