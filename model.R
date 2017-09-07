#!/usr/bin/env Rscript

library(data.table)
library(argparse)
library(ggplot2)

commandline_parser = ArgumentParser(
        description="calculate the expected dark field signal")
commandline_parser$add_argument('-a', '--aggregated',
            type='character', nargs='?', default='data/aggregated.csv',
            help='file with the aggregated')
commandline_parser$add_argument('-f', '--file',
            type='character', nargs='?', default='data/goran-renamed.rds',
            help='file with the thickness map')
commandline_parser$add_argument('-s', '--spectrum',
            type='character', nargs='?', default='spectrum.csv',
            help='file with the spectral weights')
commandline_parser$add_argument('-d', '--dfec',
            type='character', nargs='?', default='structure_factors.csv',
            help='table with all the dark field extintion coefficients calculated with saxs')

args = commandline_parser$parse_args()
aggregated = fread(args$a)
structure.factors = fread(args$d)
spectrum = fread(args$s)
thickness.map = data.table(readRDS(args$f)[-1, ])
print(thickness.map)
norm = 1 / spectrum[, sum(total_weight)]
spectrum = spectrum[, total_weight := norm * total_weight]

mu.total = function(dfec) {
    logB = (spectrum[, total_weight] %*% dfec)
    return(logB)
}

sf = structure.factors[, mu.total(dfec_lynch), by=diameter]
setnames(sf, "V1", "mu.d")
sf[, KO373 := thickness.map[, KO373]]
sf[, WT256 := thickness.map[, WT256]]
sf[, WT353 := thickness.map[, WT353]]
print(sf)
mu.d.plot = ggplot(sf) +
    geom_line(aes(x=diameter, y=mu.d)) +
    ylab(expression(mu[dfec]))
print(mu.d.plot)
width = 5
height = 5
ggsave("dfec_vs_diameter.png", mu.d.plot, width=width, height=height, dpi=300)
invisible(readLines(con="stdin", 1))
r1 = -sf[, KO373 %*% mu.d] * 0.005 / log(aggregated[name == "KO373", A_median])
r2 = -sf[, WT256 %*% mu.d] * 0.005 / log(aggregated[name == "WT256", A_median])
r3 = -sf[, WT353 %*% mu.d] * 0.005 / log(aggregated[name == "WT353", A_median])
print(c(r1, aggregated[name == "KO373", R_median]))
print(c(r2, aggregated[name == "WT256", R_median]))
print(c(r3, aggregated[name == "WT353", R_median]))
