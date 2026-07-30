
# This R script runs the API

library(plumber)
r <- plumb("API.R")
r$run(host = "0.0.0.0", port=8000)

