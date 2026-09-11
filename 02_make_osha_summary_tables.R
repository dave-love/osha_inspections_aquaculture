# ==============================================================================
# Clean OSHA inspection data and generate Supplementary Tables S4-S5
#
# Purpose: Loads the raw OSHA pull saved by 01_download_osha_data.R,
# cleans/derives variables, flags OSHA State Plan states, and produces
# summary tables exported to Excel.
#
# Requires: data/osha_1125_raw.rds (created by 01_download_osha_data.R)
# ==============================================================================

required_pkgs <- c("dplyr", "lubridate", "openxlsx", "here")
missing_pkgs  <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) install.packages(missing_pkgs)

library(dplyr)
library(lubridate)
library(openxlsx)
library(here)

# ---- 1. Load raw data -----------------------------------------------------------

raw_path <- here("data", "osha_1125_raw.rds")
if (!file.exists(raw_path)) {
  stop(
    "Raw data file not found at ", raw_path,
    ". Run 01_download_osha_data.R first, or confirm the /data folder ",
    "from the GitHub repo was downloaded correctly."
  )
}

osha_raw <- readRDS(raw_path)

# ---- 2. Clean and derive variables -----------------------------------------------

state_plan_states <- c(
  "Alaska", "Arizona", "California", "Hawaii", "Indiana", "Iowa",
  "Kentucky", "Maryland", "Michigan", "Minnesota", "Nevada",
  "New Mexico", "North Carolina", "Oregon", "South Carolina",
  "Tennessee", "Utah", "Virginia", "Vermont", "Washington", "Wyoming"
)

osha1125 <- osha_raw %>%
  select(-1, -2) %>%
  mutate(
    Date_Opened  = mdy(`Date Opened`),
    RID          = as.numeric(RID),
    State        = state.name[match(State, state.abb)],
    Type         = as.factor(Type),
    Scope        = as.factor(Scope),
    SIC          = as.factor(SIC),
    NAICS        = as.factor(NAICS),
    Sector       = "Aquaculture",
    `State Plan` = ifelse(State %in% state_plan_states, "yes", "no")
  ) %>%
  select(-`Date Opened`)

# ---- 3. Summarize ----------------------------------------------------------------

violations_by_state <- osha1125 %>%
  group_by(State, `State Plan`) %>%
  summarise(
    Inspections = n(),
    Violations  = sum(Violations, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Violations))

summary_state_plan <- osha1125 %>%
  group_by(`State Plan`) %>%
  summarise(
    Inspections = n(),
    Violations  = sum(Violations, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Violations))

# ---- 4. Export to Excel (Supplementary Tables S4-S5) -----------------------------

output_dir <- here("output")
if (!dir.exists(output_dir)) dir.create(output_dir)

wb <- createWorkbook()

addWorksheet(wb, "Table S4 - Violations by State")
writeData(wb, "Table S4 - Violations by State", violations_by_state)

addWorksheet(wb, "Table S5 - Summary by State Plan")
writeData(wb, "Table S5 - Summary by State Plan", summary_state_plan)

saveWorkbook(wb, file.path(output_dir, "osha_summary_tables.xlsx"), overwrite = TRUE)

message("Done. Tables saved to: ", file.path(output_dir, "osha_summary_tables.xlsx"))

# ---- 5. Session info for reproducibility -----------------------------------------

sessionInfo()