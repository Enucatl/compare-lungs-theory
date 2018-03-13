#!/usr/bin/env Rscript

library(data.table)
library(argparse)
library(ggplot2)
library(ks)

commandline_parser = ArgumentParser(
        description="calculate the expected dark field signal")
commandline_parser$add_argument('-p', '--pixels',
            type='character', nargs='?', default='data/pixels.rds',
            help='file with the aggregated')
commandline_parser$add_argument('-s', '--spectrum',
            type='character', nargs='?', default='spectrum.csv',
            help='file with the spectral weights')
commandline_parser$add_argument('-d', '--datasets',
            type='character', nargs='?', default='datasets.csv',
            help='table with all the dataset paths')
commandline_parser$add_argument('-o', '--output',
            type='character', nargs='?', default='samples.png',
            help='output png')

args = commandline_parser$parse_args()
pixels = readRDS(args$p)
aggregated = dcast(
    pixels[region == "LL", ],
    smoke + name + region ~ .,
    fun=list(median, sd, length),
    value.var=c("A", "B", "R", "v")
    )
aggregated[, sample := paste(name, region, smoke, sep="_")]
spectrum = fread(args$s)
dt = fread(args$d)
pixel_size = 0.65e-6

#print(dt)
#print(aggregated)
#thickness.map = data.table(readRDS(args$f)[-1, ])
#print(thickness.map)
norm = 1 / spectrum[, sum(total_weight)]
spectrum = spectrum[, total_weight := norm * total_weight]

<<<<<<< HEAD
calculate.expected.r = function(kde_filename, dfec_filename, thickness_density_filename, A_median, B_median, B_sd) {
    kde = readRDS(kde_filename)
    dfec = fread(dfec_filename)[diameter < 80]
=======
calculate.expected.r = function(kde_filename, dfec_filename, thickness_density_filename, A_median) {
    kde = readRDS(kde_filename)
    dfec = fread(dfec_filename)[diameter < 95]
>>>>>>> d7d605491634138892ba4a4cc828271806117668
    thickness_density = fread(thickness_density_filename)
    sum_over_spectrum = function(dfec_lynch) {
        return(spectrum[, total_weight] %*% dfec_lynch)
    }

    sf = dfec[, sum_over_spectrum(dfec_lynch), by=diameter]
    setnames(sf, "V1", "mu.d")
    diameter_sampling_step = (sf[2, diameter] - sf[1, diameter])
    sf[, density := predict(kde, x=diameter)]
    t = pixel_size * thickness_density[, thickness]
<<<<<<< HEAD
    #print(sf[, diameter])
    #print(sf[, median(density)])
    #print(sf[, mu.d])
    #print(log(B_median) / t)
    diameter_reverse_estimate = sf[which.min(abs(sf[, mu.d] + log(B_median) / t)), diameter]
    diameter_max_estimate = sf[which.min(abs(sf[, mu.d] + log(B_median + B_sd) / t)), diameter]
    #microct_diameter = sf[, (diameter %*% density) * diameter_sampling_step] / 2
    microct_diameter = sf[which.max(density), diameter] - 5
    diameter_estimate_error = diameter_max_estimate - diameter_reverse_estimate
    r = -sf[, (density %*% mu.d) * diameter_sampling_step] * t / log(A_median)
    return(data.table(R_theory=r, microct_diameter=microct_diameter, diameter_reverse_estimate=diameter_reverse_estimate, diameter_estimate_error=diameter_estimate_error))
=======
    print(sf[, sum(density) * diameter_sampling_step])
    r = -sf[, (density %*% mu.d) * diameter_sampling_step] * t / log(A_median)
    return(r)
>>>>>>> d7d605491634138892ba4a4cc828271806117668
}

dt = merge(dt, aggregated, by="name")
print(dt)
<<<<<<< HEAD
result = dt[, calculate.expected.r(kde, dfec, thickness_density, A_median, B_median, B_sd), by=name]
setnames(result, "R_theory.V1", "R_theory")
#setnames(result, "microct_diameter.V1", "microct_diameter")
print(result)

inverse_plot = ggplot(result, aes(x=name)) +
    geom_point(aes(y=diameter_reverse_estimate, color="black"), size=3) +
    geom_errorbar(aes(ymin=diameter_reverse_estimate - diameter_estimate_error, ymax=diameter_reverse_estimate + diameter_estimate_error), width=0.1) +
    geom_point(aes(y=microct_diameter, color="red"), size=3) + 
    scale_color_manual(name="", values=c("black", "red"), labels=c("tube", "microct")) +
    theme(axis.text.x=element_text(angle=75, hjust=1)) +
    xlab("sample") +
    ylab("diameter estimate")

=======
result = dt[, calculate.expected.r(kde, dfec, thickness_density, A_median), by=name]
setnames(result, "V1", "R_theory")
>>>>>>> d7d605491634138892ba4a4cc828271806117668
dt = merge(dt, result, by="name")
print(dt[, .SD, .SDcols=c("name", "R_sd", "R_median", "R_theory")])

plot = ggplot(dt, aes(x=name)) +
    geom_point(aes(y=R_median, color="black"), size=3) +
    geom_errorbar(aes(ymin=R_median - R_sd, ymax=R_median + R_sd), width=0.1) +
    geom_point(aes(y=R_theory, color="red"), size=3) +
    scale_color_manual(name="", values=c("black", "red"), labels=c("measured", "theory")) +
    theme(axis.text.x=element_text(angle=75, hjust=1)) +
    xlab("sample") +
    ylab("log(B) / log(A)")

dev_width = 10
factor = 0.618
dev_height = dev_width * factor
dev.new(width=dev_width, height=dev_height)
print(plot)
<<<<<<< HEAD
dev.new(width=dev_width, height=dev_height)
print(inverse_plot)
=======
>>>>>>> d7d605491634138892ba4a4cc828271806117668

ggsave(args$o, plot, width=dev_width, height=dev_height)

invisible(readLines(con="stdin", 1))
