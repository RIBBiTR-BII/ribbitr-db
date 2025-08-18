
# setup

librarian::shelf(tidyverse, dbplyr, here, lubridate, RPostgres, DBI, RIBBiTR-BII/ribbitrrr, ggplot2)

## Connect to DB
dbcon <- hopToDB("ribbitr")

## Pull column metadata from database
mdc = tbl(dbcon, Id("public", "all_columns")) %>%
  filter(table_schema == "survey_data") %>%
  collect()



# data table pointers

db_bd = tbl(dbcon, Id("survey_data", "bd_qpcr_results"))
db_sample = tbl(dbcon, Id("survey_data", "sample"))
db_capture = tbl(dbcon, Id("survey_data", "capture"))
db_ves = tbl(dbcon, Id("survey_data", "ves"))
db_survey = tbl(dbcon, Id("survey_data", "survey"))
db_visit = tbl(dbcon, Id("survey_data", "visit"))
db_site = tbl(dbcon, Id("survey_data", "site"))
db_region = tbl(dbcon, Id("survey_data", "region"))
db_country = tbl(dbcon, Id("survey_data", "country"))



# queries

# all brazil bd samples with associated capture in database
bd_samples = db_sample %>%
  left_join(db_capture, by = "capture_id") %>%
  left_join(db_survey, by = "survey_id") %>%
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  filter(sample_type == "bd") %>%
  collect()

# all bd sample counts by year
bd_samples_by_year = bd_samples %>%
  mutate(year = year(date)) %>%
  group_by(country, region, year) %>%
  summarize(bd_sample_count = n())

# all samples with corresponding results in database
bd_results = db_bd %>%
  select(sample_id) %>%
  distinct() %>%
  collect() %>%
  inner_join(bd_samples, by = "sample_id")

# all brazil bd result counts by year
bd_results_by_year = bd_results %>%
  mutate(year = year(date)) %>%
  group_by(country, region, year) %>%
  summarize(bd_result_count = n())

bd_samples_results = bd_samples_by_year %>%
  full_join(bd_results_by_year, by = c("country", "region", "year")) %>%
  arrange(year, country, region) %>%
  mutate(bd_result_count = ifelse(is.na(bd_result_count), 0, bd_result_count),
         discrepancy = bd_sample_count - bd_result_count)



# captures, visuals, acoustics


get_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

report_visit_all = db_visit %>%
  mutate(year = year(date)) %>%
  filter(date >= "2021-10-01") %>%
  group_by(year) %>%
  count() %>%
  collect() %>%
  arrange(year)

report_visit_all = db_visit %>%
  mutate(year = year(date)) %>%
  filter(date >= "2021-10-01") %>%
  count() %>%
  collect()

report_visit = db_visit %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  filter(date >= "2021-10-01") %>%
  group_by(country, region) %>%
  count() %>%
  collect()

report_survey = db_survey %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  filter(date >= "2021-10-01") %>%
  group_by(detection_type) %>%
  count() %>%
  collect()

report_capture = db_capture %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  filter(year >= 2022) %>%
  count() %>%
  collect()

report_capture_all = db_capture %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  count() %>%
  collect()

report_ves = db_ves %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  filter(date >= "2021-10-01") %>%
  count() %>%
  collect()

report_ves_all = db_ves %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  count() %>%
  collect()

report_sample = db_sample %>%
  left_join(db_capture, by = "capture_id") %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  filter(date >= "2021-10-01") %>%
  select(sample_type, region, country) %>%
  collect() %>%
  mutate(region = case_when(
    region == "california" ~ "california",
    region == "pennsylvania" ~ "pensylvania",
    country == "panama" ~ "panama",
    country == "brazil" ~ "brazil",
    .default = "other"
  )) %>%
  group_by(sample_type, region) %>%
  filter(sample_type != "crispr") %>%
  count() %>%
  arrange(sample_type)

report_sample_all = db_sample %>%
  left_join(db_capture, by = "capture_id") %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  group_by(sample_type) %>%
  count() %>%
  collect() %>%
  arrange(sample_type)

report_taxa = db_capture %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  filter(year >= 2022) %>%
  select(taxon_capture, region, country) %>%
  collect() %>%
  mutate(region = case_when(
    region == "california" ~ "california",
    region == "pennsylvania" ~ "pensylvania",
    country == "panama" ~ "panama",
    country == "brazil" ~ "brazil",
    .default = "other"
  )) %>%
  group_by(taxon_capture) %>%
  summarize(n = n(),
            region = get_mode(region)) %>%
  arrange(desc(n)) %>%
  rename(taxon = taxon_capture) %>%
  filter(n > 10,
         !is.na(taxon))

report_taxa_all = db_capture %>%
  left_join(db_survey, by = "survey_id") %>% 
  left_join(db_visit, by = "visit_id") %>%
  left_join(db_site, by = "site_id") %>%
  left_join(db_region, by = "region_id") %>%
  left_join(db_country, by = "country_id") %>%
  mutate(year = year(date)) %>%
  select(taxon_capture) %>%
  distinct() %>%
  count() %>%
  collect()



# visualize

# taxa histogram
ggplot(report_taxa, aes(x = reorder(taxon, -n), y = n, fill = region)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) + 
  scale_y_log10() +
  xlab("taxon") +
  ylab("Captured individuals (2021-2024)")



# sample histogram
report_sample_bd = report_sample %>%
  filter(sample_type == "bd")

report_sample_other = report_sample %>%
  filter(sample_type != "bd")

ggplot(report_sample_other, aes(x = sample_type, y = n, fill = region)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  xlab("Sample type") +
  ylab("Samples collected (2021-2024)")

ggplot(report_sample_bd, aes(x = sample_type, y = n, fill = region)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  xlab("Sample type") +
  ylab("Samples collected (2021-2024)")
