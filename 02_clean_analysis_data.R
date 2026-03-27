rm(list = ls())

library(dplyr)
library(readr)
library(stringr)

nhanes <- readRDS("data/processed/nhanes_2011_2018_merged.rds")

vars_keep <- c(
  "SEQN", "cycle",
  
  # demographics
  "RIDAGEYR", "RIAGENDR", "RIDRETH3", "DMDEDUC2", "DMDMARTL", "INDFMPIR", "DMDHHSIZ",
  
  # weights
  "WTMEC2YR", "WTDRD1",
  
  # dietary exposure
  "DR1TSUGR", "DR1TKCAL", "DR1TCARB", "DR1TTFAT", "DR1TPROT",
  
  # depression questionnaire
  "DPQ010", "DPQ020", "DPQ030", "DPQ040", "DPQ050",
  "DPQ060", "DPQ070", "DPQ080", "DPQ090",
  
  # alcohol
  "ALQ101", "ALQ120Q", "ALQ120U", "ALQ130",
  
  # physical activity
  "PAQ650", "PAQ665", "PAQ620", "PAQ635",
  
  # smoking
  "SMQ020", "SMQ040",
  
  # sleep
  "SLD010H", "SLQ050",
  
  # food security
  "FSD032C", "FSD151",
  
  # BMI
  "BMXBMI"
)

vars_keep <- intersect(vars_keep, names(nhanes))

dat <- nhanes %>%
  select(all_of(vars_keep))

# -----------------------------
# Helper: safely convert obvious numeric strings
# -----------------------------
to_num <- function(x) {
  suppressWarnings(as.numeric(x))
}

# -----------------------------
# Convert variables that should already be numeric-like
# -----------------------------
numeric_like_vars <- c(
  "SEQN", "RIDAGEYR", "INDFMPIR", "DMDHHSIZ",
  "WTMEC2YR", "WTDRD1",
  "DR1TSUGR", "DR1TKCAL", "DR1TCARB", "DR1TTFAT", "DR1TPROT",
  "ALQ120Q", "ALQ120U", "ALQ130",
  "SLD010H",
  "BMXBMI"
)

numeric_like_vars <- intersect(numeric_like_vars, names(dat))

dat <- dat %>%
  mutate(across(all_of(numeric_like_vars), to_num))

# -----------------------------
# Recode labeled categorical vars
# -----------------------------

# Gender
if ("RIAGENDR" %in% names(dat)) {
  dat <- dat %>%
    mutate(
      RIAGENDR = case_when(
        RIAGENDR %in% c("1", "Male") ~ 1,
        RIAGENDR %in% c("2", "Female") ~ 2,
        TRUE ~ NA_real_
      )
    )
}

# Smoking ever
if ("SMQ020" %in% names(dat)) {
  dat <- dat %>%
    mutate(
      SMQ020 = case_when(
        SMQ020 %in% c("1", "Yes") ~ 1,
        SMQ020 %in% c("2", "No") ~ 2,
        TRUE ~ NA_real_
      )
    )
}

# Physical activity
for (v in intersect(c("PAQ650", "PAQ665", "PAQ620", "PAQ635"), names(dat))) {
  dat[[v]] <- case_when(
    dat[[v]] %in% c("1", "Yes") ~ 1,
    dat[[v]] %in% c("2", "No") ~ 2,
    TRUE ~ NA_real_
  )
}

# -----------------------------
# PHQ-9 recode from labels OR numeric strings
# -----------------------------
recode_phq <- function(x) {
  case_when(
    x %in% c("0", "Not at all") ~ 0,
    x %in% c("1", "Several days") ~ 1,
    x %in% c("2", "More than half the days") ~ 2,
    x %in% c("3", "Nearly every day") ~ 3,
    x %in% c("7", "Refused", "9", "Don't know") ~ NA_real_,
    TRUE ~ suppressWarnings(as.numeric(x))
  )
}

phq_vars <- intersect(
  c("DPQ010", "DPQ020", "DPQ030", "DPQ040", "DPQ050",
    "DPQ060", "DPQ070", "DPQ080", "DPQ090"),
  names(dat)
)

for (v in phq_vars) {
  dat[[v]] <- recode_phq(dat[[v]])
}

# -----------------------------
# Recode common NHANES missing for numeric columns
# -----------------------------
recode_nhanes_missing <- function(x) {
  ifelse(x %in% c(7, 9, 77, 99, 777, 999, 7777, 9999), NA, x)
}

dat <- dat %>%
  mutate(across(where(is.numeric), recode_nhanes_missing))

# -----------------------------
# Restrict to adults
# -----------------------------
dat <- dat %>%
  filter(!is.na(RIDAGEYR), RIDAGEYR >= 18)

# -----------------------------
# Build outcome and exposure
# -----------------------------
dat <- dat %>%
  mutate(
    phq9_score = rowSums(across(all_of(phq_vars)), na.rm = FALSE),
    depression_binary = ifelse(!is.na(phq9_score) & phq9_score >= 10, 1, 0),
    depression_binary = ifelse(is.na(phq9_score), NA, depression_binary),
    
    total_sugar_g = DR1TSUGR,
    total_kcal = DR1TKCAL,
    sugar_per_1000kcal = ifelse(!is.na(DR1TSUGR) & !is.na(DR1TKCAL) & DR1TKCAL > 0,
                                DR1TSUGR / DR1TKCAL * 1000,
                                NA_real_)
  )
# -----------------------------
# Winsorize sugar variables at 99th percentile
# -----------------------------
sugar_cap <- quantile(dat$total_sugar_g, 0.99, na.rm = TRUE)
sugar_density_cap <- quantile(dat$sugar_per_1000kcal, 0.99, na.rm = TRUE)

dat <- dat %>%
  mutate(
    total_sugar_g_winsor = ifelse(!is.na(total_sugar_g),
                                  pmin(total_sugar_g, sugar_cap),
                                  NA_real_),
    sugar_per_1000kcal_winsor = ifelse(!is.na(sugar_per_1000kcal),
                                       pmin(sugar_per_1000kcal, sugar_density_cap),
                                       NA_real_)
  )

# -----------------------------
# Control vars
# -----------------------------
dat <- dat %>%
  mutate(
    female = ifelse(RIAGENDR == 2, 1,
                    ifelse(RIAGENDR == 1, 0, NA)),
    ever_smoked = ifelse(SMQ020 == 1, 1,
                         ifelse(SMQ020 == 2, 0, NA)),
    sleep_hours = SLD010H,
    drinks_per_day = ALQ130,
    vigorous_activity = ifelse(PAQ650 == 1, 1,
                               ifelse(PAQ650 == 2, 0, NA)),
    moderate_activity = ifelse(PAQ665 == 1, 1,
                               ifelse(PAQ665 == 2, 0, NA)),
    bmi = BMXBMI,
    cycle = as.character(cycle)
  )

# -----------------------------
# Create pooled survey weights
# Prefer dietary day-1 weight if available; otherwise use MEC weight
# 4 cycles = divide by 4
# -----------------------------
dat <- dat %>%
  mutate(
    weight_raw = if ("WTDRD1" %in% names(dat)) WTDRD1 else WTMEC2YR,
    weight_8yr = weight_raw / 4
  )
# -----------------------------
# Missingness check BEFORE filtering
# -----------------------------
cat("\nMissingness in core vars:\n")
print(colSums(is.na(dat[c("phq9_score", "total_sugar_g", "RIDAGEYR", "RIAGENDR", "INDFMPIR")])))

cat("\nNon-missing counts in core vars:\n")
print(colSums(!is.na(dat[c("phq9_score", "total_sugar_g", "RIDAGEYR", "RIAGENDR", "INDFMPIR")])))

# -----------------------------
# Final analysis sample
# -----------------------------
analysis_dat <- dat %>%
  filter(
    !is.na(phq9_score),
    !is.na(total_sugar_g),
    !is.na(sugar_per_1000kcal),
    !is.na(RIDAGEYR),
    !is.na(RIAGENDR),
    !is.na(weight_8yr)
  )

saveRDS(analysis_dat, "data/processed/nhanes_analysis_ready.rds")
write_csv(analysis_dat, "data/processed/nhanes_analysis_ready.csv")

cat("\nRows in cleaned data:", nrow(analysis_dat), "\n")
cat("Columns in cleaned data:", ncol(analysis_dat), "\n")

