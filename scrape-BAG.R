# scrape-BAG.R
#
# Script to scrape (part of) the BAG's Excel file about corona virus/COVID-19 cases.
# 
# 2020-03-31
# Ralph Straumann, @rastrau, ralphstraumann.ch
#

library(here)
library(httr)
library(readxl)
library(tidyverse)
library(lubridate)


BAG_URL = "https://www.bag.admin.ch/dam/bag/de/dokumente/mt/k-und-i/aktuelle-ausbrueche-pandemien/2019-nCoV/covid-19-datengrundlage-lagebericht.xlsx.download.xlsx/200325_Datengrundlage_Grafiken_COVID-19-Bericht.xlsx"

ALTERSVERTEILUNG_CSV = "allages.csv"

# Get date of running this script (could also (should?) be parsed from the BAG Excel file)
update_time <- format(Sys.time(), "%Y-%m-%d")

# Download the BAG Excel file to a temporary file
GET(BAG_URL, write_disk(tf <- tempfile(fileext = ".xlsx")))

# Read Excel sheets, ignoring topmatter
df_epikurve <- read_excel(tf, sheet = "COVID19 Epikurve", skip = 5)
df_altersverteilung <- read_excel(tf, sheet = "COVID19 Altersverteilung", skip = 6)
df_kantone <- read_excel(tf, sheet = "COVID19 Kantone", skip = 6)
df_hospit <- read_excel(tf, sheet = "COVID19 Altersverteilung Hospit", skip = 6)
df_todf <- read_excel(tf, sheet = "COVID19 Altersverteilung TodF", skip = 6)

# Get relevant data 
df_altersverteilung <- df_altersverteilung[0:9,]

# Split data into male and female data, change gender/age label to be compatible with target data model
df_altersverteilung %>%
  select(Altersklasse, "Männlich: Inzidenz") %>%
  mutate(Altersklasse = str_c("m", str_replace_all(Altersklasse, " ", ""))) -> df_altersverteilung_m
df_altersverteilung %>%
  select(Altersklasse, "Weiblich: Inzidenz") %>%
  mutate(Altersklasse = str_c("f", str_replace_all(Altersklasse, " ", ""))) -> df_altersverteilung_f

# Harmonise variable names
names(df_altersverteilung_m) <- c("variable", "value")
names(df_altersverteilung_f) <- c("variable", "value")

# Merge male and female dataframe into one dataframe and add update day
df_altersverteilung <- rbind(df_altersverteilung_m, df_altersverteilung_f)
rm(df_altersverteilung_m)
rm(df_altersverteilung_f)
df_altersverteilung$date <- update_time

# Change table from long to wide format
df_altersverteilung <- spread(df_altersverteilung, variable, value)

# Read existing CSV file, append new data, write to disk
data <- read_csv(ALTERSVERTEILUNG_CSV)
data <- rbind(data, df_altersverteilung)
write_csv(data, ALTERSVERTEILUNG_CSV)
rm(data)
rm(data, df_altersverteilung)

