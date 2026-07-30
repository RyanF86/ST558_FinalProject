
# This R script runs the API

library(plumber)
r <- plumb("API.R")
r$run(port=8000)

