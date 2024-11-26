# Match-Statistics-Visualizations
The R script provides visualizations of match statistics from Match Statistics dataset

Files Included
analysis_script.R: The R script used to load, analyze, and visualize the dataset. The script includes data cleaning, transformation, and plotting procedures.
dataset.csv: The dataset used for the analysis. This file contains the raw data that is processed by the R script.
Prerequisites
To run the R script, you will need the following:

R (version 4.0 or later) installed on your system.
Required R packages, including but not limited to:
ggplot2 (for graphing and visualizations)
dplyr (for data manipulation)
readr (for reading CSV files)
tidyr (for data cleaning)
You can install these packages by running the following commands in R:

R
Copy code
install.packages("ggplot2")
install.packages("dplyr")
install.packages("readr")
install.packages("tidyr")
Usage
Download the files:

Download the R file named mps.R and mps.csv files from this repository to your local machine.
Run the script:

Open the mps.R file in an R environment (e.g., RStudio).
Run the script. It will automatically load the dataset, perform the analysis, and generate the graphs.
Interpret the results:

The script generates several visualizations that help to interpret the data. These include bar charts, scatter plots, and other relevant plots based on the analysis goals.
Example Output
After running the R script, you should see the generated graphs, such as:

A bar chart visualizing category distribution.
A scatter plot showing correlations between two variables.

Acknowledgments
The dataset used in this project was obtained from https://data.world/cervus/uefa-euro-2020.
The R packages ggplot2, dplyr, readr, and tidyr were essential for data visualization and manipulation.
