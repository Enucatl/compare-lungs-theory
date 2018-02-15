#!/usr/bin/env Rscript

library(argparse)
library(data.table)
library(ggplot2)
library(tools)
library(ks)

parser = ArgumentParser(description='compare csv files')
parser$add_argument('files' , metavar= 'FILES', nargs= '+', help='files with the kde')
parser$add_argument('--output' , help='output file for the plot')

args = parser$parse_args()

input = data.table(args$files)
print(input)

kde_prediction = function(filename) {
    kde = readRDS(filename)
    x = seq(0.1, 400, by=0.1)
    return(list(
        x=x,
        y=predict(kde, x=x),
        name=basename(tools::file_path_sans_ext(filename))))
}

dt = input[, kde_prediction(V1), by=V1]
print(dt)

plot = ggplot(dt, aes(x=x, y=y, color=name)) +
    geom_line() +
    xlab("size (um)") +
    ylab("kde") +
    theme(legend.position="bottom",legend.direction="vertical")

width = 14
factor = 0.618
height = width * factor
dev.new(width=width, height=height)
print(plot)
ggsave(args$output, plot, width=width, height=height, dpi=300)
invisible(readLines(con="stdin", 1))
