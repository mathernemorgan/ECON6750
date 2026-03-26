# download_data.R
# This script downloads the required NHANES 2017-2018 files directly from the CDC.

# List of components needed for the analysis
nhanes_files <- c(
  "DEMO_J",   # Demographics
  "DR1TOT_J", # Dietary Recall - Day 1
  "DPQ_J",    # Depression Screener
  "ALQ_J",    # Alcohol Use
  "FSQ_J",    # Food Security
  "PAQ_J",    # Physical Activity
  "SMQ_J",    # Smoking - Recent Use
  "SLQ_J"     # Sleep Disorders
)

base_url <- "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/"

message("Starting downloads from CDC...")

for (file_name in nhanes_files) {
  dest_file <- paste0(file_name, ".xpt")
  
  # Only download if the file doesn't already exist
  if (!file.exists(dest_file)) {
    url <- paste0(base_url, file_name, ".XPT")
    message(paste("Downloading:", file_name))
    
    # mode = "wb" is critical for downloading binary files like .xpt on Windows
    tryCatch({
      download.file(url, destfile = dest_file, mode = "wb")
    }, error = function(e) {
      message(paste("Failed to download:", file_name, "-", e$message))
    })
  } else {
    message(paste("File already exists, skipping:", file_name))
  }
}

message("All downloads completed.")
