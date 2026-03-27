# =========================================================
# 01_download_data.R
# Download NHANES tables using nhanesA and save locally
# for reproducibility
# =========================================================

rm(list = ls())

install.packages("nhanesA")
library(nhanesA)

# -----------------------------
# Survey cycles
# -----------------------------
cycles <- data.frame(
  cycle_folder = c("2011-2012", "2013-2014", "2015-2016", "2017-2018"),
  suffix = c("G", "H", "I", "J"),
  stringsAsFactors = FALSE
)

# -----------------------------
# Files to download
# -----------------------------
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

# -----------------------------
# Create data folders
# -----------------------------
if (!dir.exists("data")) dir.create("data")
if (!dir.exists("data/raw")) dir.create("data/raw", recursive = TRUE)

# -----------------------------
# Download + save function
# -----------------------------
download_nhanes_table <- function(file_code, cycle_folder) {
  
  out_dir <- file.path("data", "raw", cycle_folder)
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  out_file <- file.path(out_dir, paste0(file_code, ".rds"))
  
  if (file.exists(out_file)) {
    message("Already saved, skipping: ", out_file)
    return(invisible(NULL))
  }
  
  message("Downloading: ", file_code)
  
  tryCatch({
    dat <- nhanes(file_code)
    saveRDS(dat, out_file)
    message("Saved: ", out_file, 
            " | Rows: ", nrow(dat), 
            " | Cols: ", ncol(dat))
  }, error = function(e) {
    message("Failed: ", file_code, " | ", e$message)
  })
}

# -----------------------------
# Run downloads
# -----------------------------
for (i in seq_len(nrow(cycles))) {
  cycle_folder <- cycles$cycle_folder[i]
  suffix <- cycles$suffix[i]
  
  message("")
  message("======================================")
  message("Cycle: ", cycle_folder)
  message("======================================")
  
  for (file_root in file_roots) {
    file_code <- paste0(file_root, "_", suffix)
    download_nhanes_table(file_code, cycle_folder)
  }
}

message("")
message("All downloads completed.")

