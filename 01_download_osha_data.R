# ==============================================================================
# Download raw OSHA inspection data (NAICS 1125 - Aquaculture)
#
# Purpose: Scrapes OSHA inspection records and saves the RAW, unmodified
# pull to /data as both .rds (preserves data types) and .csv (human-readable,
# GitHub-friendly) so results can be reproduced even if OSHA's website
# changes or goes offline.
#
# Data source: https://www.osha.gov/ords/imis/industry.html
# ==============================================================================

required_pkgs <- c("httr", "rvest", "dplyr", "here")
missing_pkgs  <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) install.packages(missing_pkgs)

library(httr)
library(rvest)
library(dplyr)
library(here)

# ---- 1. Function to scrape one date-range block of OSHA inspection data ------

#' Fetch OSHA inspection records for a given NAICS code and date range
#'
#' @param naics NAICS code as a string (e.g., "1125")
#' @param start_year,end_year Integer years defining the search window
#'   (NOTE: OSHA's form labels "start" as the most recent date and "end" as
#'   the earliest date - i.e., start_year > end_year)
#' @param p_show Max records to return per query (OSHA form default max ~2000)
#' @return A tibble of raw inspection records as returned by OSHA
fetch_osha_inspections <- function(naics, start_year, end_year, p_show = 2000) {
  
  full_url <- paste0(
    "https://www.osha.gov/ords/imis/industry.search?",
    "sic=&naics=", naics,
    "&state=All&officetype=All&office=All",
    "&startmonth=12&startday=31&startyear=", start_year,
    "&endmonth=01&endday=01&endyear=", end_year,
    "&scope=&fedagncode=&owner=&p_start=&p_finish=0",
    "&p_sort=&p_desc=DESC&p_direction=Next&p_show=", p_show
  )
  
  resp <- GET(
    full_url,
    add_headers(
      `User-Agent`      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      `Accept`          = "text/html,application/xhtml+xml,application/xml;q=0.9",
      `Accept-Language` = "en-US,en;q=0.5"
    )
  )
  stop_for_status(resp)
  
  page_html  <- content(resp, as = "text", encoding = "UTF-8") %>% read_html()
  all_tables <- html_nodes(page_html, "table")
  
  if (length(all_tables) < 2) {
    stop(
      "Expected results table not found for ", end_year, "-", start_year,
      ". OSHA may have changed their page structure. Inspect this URL manually: ",
      full_url
    )
  }
  
  html_table(all_tables[[2]], fill = TRUE) %>%
    as_tibble(.name_repair = "unique")
}

# ---- 2. Define date ranges to query -------------------------------------------
# NOTE: These ranges were chosen to keep each query under OSHA's per-query
# record limit (p_show = 2000). Update / add ranges as needed - see README
# for instructions on extending this to future years.

date_ranges <- list(
  c(start_year = 2010, end_year = 2003),
  c(start_year = 2019, end_year = 2011),
  c(start_year = 2025, end_year = 2020)
)

# ---- 3. Download raw data -------------------------------------------------------

inspection_list <- vector("list", length(date_ranges))

for (i in seq_along(date_ranges)) {
  rng <- date_ranges[[i]]
  message("Fetching OSHA data for years ", rng["end_year"], "-", rng["start_year"], "...")
  inspection_list[[i]] <- fetch_osha_inspections(
    naics      = "1125",
    start_year = rng["start_year"],
    end_year   = rng["end_year"]
  )
  Sys.sleep(2)  # be polite to the OSHA server between requests
}

osha_raw <- bind_rows(inspection_list)

# ---- 4. Save raw pull to /data --------------------------------------------------
# Both formats are saved: .rds preserves R data types exactly; .csv is
# included so the raw data is viewable directly on GitHub without R.

data_dir <- here("data")
if (!dir.exists(data_dir)) dir.create(data_dir)

pull_date <- Sys.Date()

saveRDS(osha_raw, file.path(data_dir, "osha_1125_raw.rds"))
write.csv(osha_raw, file.path(data_dir, "osha_1125_raw.csv"), row.names = FALSE)

# Log exactly when and what was pulled, for the record
writeLines(
  c(
    paste("Data pulled on:", pull_date),
    paste("NAICS code:", "1125"),
    "Date ranges queried:",
    sapply(date_ranges, function(r) paste0("  ", r["end_year"], "-", r["start_year"]))
  ),
  file.path(data_dir, "osha_1125_pull_log.txt")
)

message("Raw data saved to ", data_dir, " (pulled ", pull_date, ")")