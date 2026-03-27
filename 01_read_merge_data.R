# =========================================================
# 02_read_merge_data.R
# Read locally saved NHANES tables, merge within cycle
# by SEQN, then stack cycles
# =========================================================

rm(list = ls())

library(dplyr)
library(purrr)
library(readr)

cycles <- data.frame(
  cycle_folder = c("2011-2012", "2013-2014", "2015-2016", "2017-2018"),
  suffix = c("G", "H", "I", "J"),
  stringsAsFactors = FALSE
)

file_roots <- c(
  "DEMO",
  "DR1TOT",
  "DPQ",
  "ALQ",
  "PAQ",
  "SMQ",
  "SLQ",
  "FSQ",
  "BMX"
)

safe_read_rds <- function(path) {
  if (!file.exists(path)) {
    message("Missing file: ", path)
    return(NULL)
  }
  
  tryCatch({
    readRDS(path)
  }, error = function(e) {
    message("Failed to read: ", path, " | ", e$message)
    NULL
  })
}

standardize_types <- function(df) {
  df[] <- lapply(df, function(x) {
    
    if (is.factor(x)) {
      x <- as.character(x)
    }
    
    if (is.character(x)) {
      non_missing <- x[!is.na(x) & x != ""]
      
      if (length(non_missing) > 0 &&
          all(grepl("^-?[0-9.]+$", non_missing))) {
        return(as.numeric(x))
      } else {
        return(x)
      }
    }
    
    x
  })
  
  return(df)
}

read_and_merge_cycle <- function(cycle_folder, suffix, file_roots) {
  data_list <- list()
  
  for (file_root in file_roots) {
    file_code <- paste0(file_root, "_", suffix)
    path <- file.path("data", "raw", cycle_folder, paste0(file_code, ".rds"))
    dat <- safe_read_rds(path)
    
    if (!is.null(dat)) {
      data_list[[file_root]] <- dat
    }
  }
  
  if (!"DEMO" %in% names(data_list)) {
    stop("DEMO missing for cycle: ", cycle_folder)
  }
  
  merged_data <- data_list[["DEMO"]]
  other_files <- setdiff(names(data_list), "DEMO")
  
  for (file_name in other_files) {
    merged_data <- merged_data %>%
      left_join(data_list[[file_name]], by = "SEQN")
  }
  
  merged_data <- merged_data %>%
    mutate(cycle = cycle_folder)
  
  merged_data <- standardize_types(merged_data)
  
  return(merged_data)
}

all_cycles <- map2(
  cycles$cycle_folder,
  cycles$suffix,
  ~ read_and_merge_cycle(.x, .y, file_roots)
)

# Force every column in every cycle dataset to character
all_cycles_chr <- lapply(all_cycles, function(df) {
  df[] <- lapply(df, function(x) {
    if (is.list(x)) {
      return(as.character(x))
    } else {
      return(as.character(x))
    }
  })
  df
})

nhanes_merged <- bind_rows(all_cycles_chr)

nhanes_merged <- nhanes_merged %>%
  mutate(SEQN = as.numeric(SEQN))

nhanes_merged <- nhanes_merged %>%
  mutate(cycle = as.character(cycle))

if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)

saveRDS(nhanes_merged, "data/processed/nhanes_2011_2018_merged.rds")
write_csv(nhanes_merged, "data/processed/nhanes_2011_2018_merged.csv")

message("Saved merged data.")

