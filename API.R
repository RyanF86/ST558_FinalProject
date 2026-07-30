
# This R script defines the API

# Install Packages
library(tidyverse)
library(tidymodels)
library(ranger)
library(plumber)

# Read in the data

water_data <- read_rds("Data/water_clean.rds") # read cleaned water data from the .rds file

# Define the recipe
water_rec <- recipe(Potability ~ ., data = water_data) 

# Specify the random forest model
RandForest_spec <- rand_forest(mtry = 9) |> # mtry = 9 determined best from Modeling.qmd
  set_engine("ranger") |> 
  set_mode("classification")

# Create the workflow
RandForest_wkf <- workflow() |>
  add_recipe(water_rec) |>
  add_model(RandForest_spec)

# Fit to the entire data set
set.seed(123) # setting a seed for reproducibility
RandForest_final <- RandForest_wkf |> # fit to entire data set
  fit(water_data)

# Determine mean values of each of the predictors in the dataset
ph_mean <- mean(water_data$ph)
Hardness_mean <- mean(water_data$Hardness)
Solids_mean <- mean(water_data$Solids)
Chloramines_mean <- mean(water_data$Chloramines)
Sulfate_mean <- mean(water_data$Sulfate)
Conductivity_mean <- mean(water_data$Conductivity)
Organic_carbon_mean <- mean(water_data$Organic_carbon)
Trihalomethanes_mean <- mean(water_data$Trihalomethanes)
Turbidity_mean <- mean(water_data$Turbidity)

# API endpoint: pred
#* Takes in predictor values and returns a prediction
#* @param ph pH 0 to 14 scale
#* @param Hardness Hardness in mg/L
#* @param Solids Solids in ppm
#* @param Chloramines Chloramine concentration in ppm
#* @param Sulfate Sulfate in mg/L
#* @param Conductivity Conductivity in μS/cm
#* @param Organic_carbon Organic Carbon in ppm
#* @param Trihalomethanes Trihalomethanes in μg/L
#* @param Turbidity Turbidity in NTU
#* @get /pred
function(ph = ph_mean, # nine numerical predictors as inputs, with their means as the default values
         Hardness = Hardness_mean,
         Solids = Solids_mean,
         Chloramines = Chloramines_mean,
         Sulfate = Sulfate_mean,
         Conductivity = Conductivity_mean,
         Organic_carbon = Organic_carbon_mean,
         Trihalomethanes = Trihalomethanes_mean,
         Turbidity = Turbidity_mean){
  predictors <- suppressWarnings( # build the tibble of predictors, suppressing any warnings from as.numeric()
    tibble(ph = as.numeric(ph), 
                       Hardness = as.numeric(Hardness), 
                       Solids = as.numeric(Solids),
                       Chloramines = as.numeric(Chloramines), 
                       Sulfate = as.numeric(Sulfate),
                       Conductivity = as.numeric(Conductivity), 
                       Organic_carbon = as.numeric(Organic_carbon),
                       Trihalomethanes = as.numeric(Trihalomethanes), 
                       Turbidity = as.numeric(Turbidity)))
  if (any(is.na(predictors))) { # NA would occur if non-numeric input was attempted
    stop("All predictor inputs must be numeric")
  }
  predict(RandForest_final, new_data = predictors, type = "prob")$.pred_1 # use the model to return prediction of whether Potability = 1
}
# Example calls:
# http://localhost:8000/pred?ph=7&Hardness=200&Solids=22000&Chloramines=7&Sulfate=300&Conductivity=400&Organic_carbon=14&Trihalomethanes=60&Turbidity=4
# http://localhost:8000/pred?ph=5&Sulfate=250&Hardness=150
# http://localhost:8000/pred
# http://localhost:8000/pred?ph=abcd

# API endpoint: info
#* Return's author name and rendered github pages URL
#* @get /info
function(){ # 
  list(name = "Ryan Friedman",
       url = "https://ryanf86.github.io/ST558_FinalProject/")
}
# Example call:
# http://localhost:8000/info

# API endpoint: confusion
#* Returns confusion matrix plot for the model
#* @serializer png
#* @get /confusion
function(){
  cm <- conf_mat(data = water_data |> mutate(estimate = RandForest_final |> predict(water_data) |> pull()),
           truth = Potability,
           estimate)
  print(autoplot(cm, type = "heatmap"))
}
# Example call:
# http://localhost:8000/confusion