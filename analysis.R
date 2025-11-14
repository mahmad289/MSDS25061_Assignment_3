# Automatically install required packages if missing
required_packages <- c("data.table", "ggplot2")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# Load required packages
library(data.table)
library(ggplot2)

# Create results folder if it doesn't exist
if(!dir.exists("results")) dir.create("results")

# Load CSVs into data.tables
film <- fread("data/film.csv")
language <- fread("data/language.csv")
customer <- fread("data/customer.csv")
store <- fread("data/store.csv")
payment <- fread("data/payment.csv")
staff <- fread("data/staff.csv")
rental <- fread("data/rental.csv")

# 1. Films with rating PG and rental duration > 5 days
pg_films <- film[rating == "PG" & rental_duration > 5]
fwrite(pg_films, "results/q1_pg_films.csv")

