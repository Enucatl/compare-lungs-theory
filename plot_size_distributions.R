#!/usr/bin/env Rscript

library(data.table)
library(argparse)
library(ggplot2)

commandline_parser = ArgumentParser(
        description="plot thickness map")
commandline_parser$add_argument('-f', '--file',
            type='character', nargs='?', default='data/goran-3-samples.rds',
            help='file with the thickness map')
args = commandline_parser$parse_args()

col.a = paste("y", 1:3, sep="")
col.b = paste("y", 1:3, "_std", sep="")
print(col.a)
print(col.b)
thickness.map = melt(
    data.table(readRDS(args$f)),
    measure=list(col.a, col.b),
    value.name=c("y", "y_std"))

print(thickness.map)

thickness.plot = ggplot(thickness.map, aes(x=x_axis, y=y)) +
    geom_line(aes(color=variable)) + 
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
