#!/usr/bin/env Rscript

library(data.table)
library(argparse)
library(ggplot2)
library(ks)

commandline_parser = ArgumentParser(
        description="plot thickness map")
commandline_parser$add_argument('-d', '--datasets',
            type='character', nargs='?', default='datasets.csv',
            help='table with all the dataset paths')
args = commandline_parser$parse_args()

dt = fread(args$d)
print(dt)

kde_prediction = function(filename) {
    kde = readRDS(filename)
    diameter = seq(0.1, 100, 0.1)
    density = predict(kde, x=diameter)
    return(data.table(diameter=diameter, density=density))
}

thickness.map = dt[, kde_prediction(kde), by=name]

thickness.plot = ggplot(thickness.map, aes(x=diameter, y=density)) +
    geom_line(aes(color=name)) + 
    labs(
        color="sample",
        x="structure size (μm)",
        y="probability density function"
        ) +
    scale_x_continuous(expand=c(0, 0), limits=c(0, 60)) +
    scale_y_continuous(expand=c(0, 0), limits=c(0, 0.04))

width = 6
factor = 0.618
height = width * factor
ggsave("size_pdf.png", thickness.plot, width=width, height=height, dpi=300)
print(thickness.plot)
invisible(readLines(con="stdin", 1))
