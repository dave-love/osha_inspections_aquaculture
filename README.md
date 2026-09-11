# OSHA Inspection Data Analysis - Aquaculture (NAICS 1125)
A repository to download and analyze OSHA inspection and violation data for the aquaculture sector.

This repository contains R code used to reproduce Supplementary Tables S4 and S5 in a manuscript about worker safety in U.S. aquaculture by Dave Love and colleagues. The analysis summarizes OSHA inspection and violation records for the U.S. aquaculture sector (NAICS code 1125), by state and by OSHA State Plan status.

## Data source

Data are scraped directly from OSHA's public inspection search tool:
https://www.osha.gov/ords/imis/industry.html

**Note:** This is a live government database. Records may be added, corrected,
or removed by OSHA over time, so re-running the scraping script in the future
may not return identical results to the raw data archived here. For this
reason, the exact data pull used in the manuscript is included in `data/`
(see below).

## Repository structure

```
.
├── 01_download_osha_data.R      # Scrapes raw OSHA data, saves to /data
├── 02_make_summary_tables.R     # Cleans data, generates Tables S4-S5
├── data/
│   ├── osha_1125_raw.rds        # Raw scraped data (R format)
│   ├── osha_1125_raw.csv        # Raw scraped data (CSV, human-readable)
│   └── osha_1125_pull_log.txt   # Date of pull and date ranges queried
├── output/
│   └── osha_summary_tables.xlsx # Generated Tables S4-S5 (created by script 2)
└── README.

```
## Declaration of generative AI use:
Generative AI was used to assist in writing and debugging R code used to download, clean, and prepare tables as well as to develop the file structure for this GitHub repository. All code was reviewed, tested, and verified by the authors, who take full responsibility for its accuracy and outputs.

## Contact for more information

Dave Love, PhD, MSPH  
Research Professor  
Johns Hopkins Center for a Livable Future  
Department of Environmental Health and Engineering  
Johns Hopkins Bloomberg School of Public Health  
dlove8@jhu.edu
