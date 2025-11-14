#!/usr/bin/env Rscript

# Setup: ensure necessary packages are installed and loaded
required_packages <- c("data.table", "ggplot2")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(data.table)
library(ggplot2)

# Ensure output directories exist
if (!dir.exists("results")) dir.create("results")
if (!dir.exists("visualizations")) dir.create("visualizations")

# Load input CSV files (expect them in ./data)
films_dt <- fread("data/film.csv")
languages_dt <- fread("data/language.csv")
customers_dt <- fread("data/customer.csv")
stores_dt <- fread("data/store.csv")
payments_dt <- fread("data/payment.csv")
staff_dt <- fread("data/staff.csv")
rentals_dt <- fread("data/rental.csv")

# 1) Select films rated 'PG' with rental duration longer than 5 days
pg_long_rental_films <- films_dt[rating == "PG" & rental_duration > 5]
fwrite(pg_long_rental_films, "results/q1_pg_films.csv")

# 2) Compute average rental rate per film rating
avg_rental_rate_by_rating <- films_dt[, .(avg_rental_rate = mean(rental_rate, na.rm = TRUE)), by = rating]
fwrite(avg_rental_rate_by_rating, "results/q2_avg_rental_by_rating.csv")

# 3) Count total films per language (join films with language lookup)
films_with_language <- merge(films_dt, languages_dt, by.x = "language_id", by.y = "language_id")
film_counts_by_language <- films_with_language[, .N, by = name]
setnames(film_counts_by_language, "N", "total_films")
fwrite(film_counts_by_language, "results/q3_film_count_by_language.csv")

# 4) List customers and the store they belong to (first name, last name, store id)
customers_with_store <- merge(customers_dt, stores_dt, by.x = "store_id", by.y = "store_id")
customers_store_list <- customers_with_store[, .(first_name, last_name, store_id)]
fwrite(customers_store_list, "results/q4_customers_store.csv")

# 5) For each payment record, include amount, date, and the staff member who processed it
payments_with_staff <- merge(payments_dt, staff_dt, by.x = "staff_id", by.y = "staff_id")
payment_records_with_staff <- payments_with_staff[, .(
  amount,
  payment_date,
  staff_first_name = first_name,
  staff_last_name = last_name
)]
fwrite(payment_records_with_staff, "results/q5_payment_staff.csv")


# 6) Identify films that have never been rented
rented_film_ids <- unique(rentals_dt$film_id)
films_never_rented <- films_dt[!(film_id %in% rented_film_ids)]
fwrite(films_never_rented, "results/q6_unrented_films.csv")

# 7) Create and save several plots exploring films by rating

# 7a) Simple vertical bar (original) - number of films per rating
films_by_rating_plot <- ggplot(films_dt, aes(x = rating)) +
  geom_bar(fill = "steelblue") +
  theme_minimal() +
  labs(title = "Number of Films by Rating", x = "Rating", y = "Count")
ggsave("visualizations/q7_films_by_rating.png", plot = films_by_rating_plot)

# Prepare counts summary used by multiple plots
counts_by_rating <- films_dt[, .N, by = rating]
setnames(counts_by_rating, "N", "count")

# 7b) Horizontal bar chart (often easier to read when labels are long)
films_by_rating_horizontal <- ggplot(counts_by_rating, aes(x = reorder(rating, count), y = count)) +
  geom_col(fill = "cornflowerblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Number of Films by Rating (horizontal)", x = "Rating", y = "Count")
ggsave("visualizations/q7a_films_by_rating_horizontal.png", plot = films_by_rating_horizontal)

# 7c) Pie chart showing share of films by rating
counts_by_rating[, pct := count / sum(count) * 100]
films_by_rating_pie <- ggplot(counts_by_rating, aes(x = "", y = count, fill = rating)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  theme_void() +
  labs(title = "Share of Films by Rating") +
  geom_text(aes(label = paste0(round(pct, 1), "%")), position = position_stack(vjust = 0.5), color = "white", size = 3)
ggsave("visualizations/q7b_films_by_rating_pie.png", plot = films_by_rating_pie)

# 7d) Average rental rate by rating (bar)
films_by_rating_avg_rate <- ggplot(avg_rental_rate_by_rating, aes(x = rating, y = avg_rental_rate)) +
  geom_col(fill = "seagreen3") +
  theme_minimal() +
  labs(title = "Average Rental Rate by Rating", x = "Rating", y = "Average Rental Rate")
ggsave("visualizations/q7c_avg_rental_rate_by_rating.png", plot = films_by_rating_avg_rate)

# 7e) Boxplot of rental rate distribution by rating (shows spread and outliers)
films_rental_rate_boxplot <- ggplot(films_dt, aes(x = rating, y = rental_rate)) +
  geom_boxplot(fill = "lightgoldenrod1") +
  theme_minimal() +
  labs(title = "Rental Rate Distribution by Rating", x = "Rating", y = "Rental Rate")
ggsave("visualizations/q7d_rental_rate_boxplot_by_rating.png", plot = films_rental_rate_boxplot)
