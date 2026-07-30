# start from the rstudio/plumber image
FROM rstudio/plumber

# install the linux libraries needed for plumber
RUN apt-get update -qq && apt-get install -y  libssl-dev  libcurl4-gnutls-dev  libpng-dev pandoc 
    
    
# install plumber and other packages
RUN R -e "install.packages(c('plumber', 'tidyverse', 'tidymodels', 'ranger'))"

# copy the API .R scripts and also the Data folder from current directory into the container
COPY API.R API.R
COPY runAPI.R runAPI.R
COPY Data/ Data/

# open port to traffic
EXPOSE 8000

# when the container starts, start the runAPI.R script
ENTRYPOINT ["Rscript", "runAPI.R"]
