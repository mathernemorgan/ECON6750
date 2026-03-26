# ECON6750 NHANES Analysis: Daily Sugar Intake and Mental Health (PHQ-9)

## Project Overview
This repository contains a causal inference study investigating the relationship between **daily total sugar intake (grams)** and **depression severity**. The analysis utilizes data from the **2017-2018 NHANES cycle** (Cycle J).

The core research question asks: *Does daily sugar intake affect mental health after controlling for socioeconomic and behavioral confounders?*

## Quick Start (Recreation)
To replicate the results on your machine:

1.  **Open the Project:** Launch `ECON4750.Rproj` in RStudio.
2.  **Get the Data:** We aren't tracking the 10MB of raw data files in Git. Run the following in your console to download them directly from the CDC:
    ```R
    source("download_data.R")
    ```
3.  **Install Libraries:** Ensure you have the required packages:
    ```R
    install.packages(c("haven", "tidyverse", "mice"))
    ```
4.  **Run Analysis:** Execute `script.R`.

---

## Data Dictionary & Verification
If you need to check how the CDC coded a specific variable or response (e.g., what does "Value 2" mean for marital status?), use these direct links to the official codebooks:

* [**Demographics (DEMO_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/DEMO_J.htm): Age, Income-to-Poverty Ratio (`INDFMPIR`), Education, Marital Status.
* [**Dietary Recall (DR1TOT_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/DR1TOT_J.htm): Total Sugar (`DR1TSUGR`), Total Calories, Caffeine.
* [**Depression Screener (DPQ_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/DPQ_J.htm): The 9 symptoms used to calculate our `phq9_total`.
* [**Sleep Disorders (SLQ_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/SLQ_J.htm): Troubleshooting sleep quality.
* [**Food Security (FSQ_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/FSQ_J.htm): Adult food security categories.
* [**Smoking (SMQ_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/SMQ_J.htm): Recent cigarette use.
* [**Alcohol Use (ALQ_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/ALQ_J.htm): Alcohol consumption frequency.
* [**Physical Activity (PAQ_J)**](https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/PAQ_J.htm): Vigorous work/recreation activity.

---

## Methodology

### 1. Data Integration & Cleaning
Data was merged from eight NHANES components using the `SEQN` (Respondent Sequence Number) key. 
* **Target Cohort:** Adults (18+) who were eligible for the PHQ-9 depression screener.
* **Outcome Variable:** A clinical **PHQ-9 Total Score** (0–27), calculated by summing nine individual symptom questions. 
* **Treatment Variable:** Daily sugar intake (`DR1TSUGR`) from the first day of dietary recall.
* **Refusal Handling:** Participant responses of "Refused" (7) or "Don't Know" (9) were recoded as `NA` to avoid skewing the scoring system.

### 2. Multiple Imputation (MICE)
To handle missingness in dietary data and sensitive demographic questions (like income), we used **Multivariate Imputation by Chained Equations (MICE)** with **Predictive Mean Matching (PMM)**. This generated five unique imputed datasets to ensure the final estimates account for the uncertainty of the missing values.

### 3. Econometric Model
A pooled linear regression was executed across the imputed datasets. The model controls for:
* **Metabolic Confounders:** Total caloric intake and caffeine.
* **Socioeconomic Status:** Income-to-poverty ratio, education, and marital status.
* **Behavioral Factors:** Sleep quality, physical activity, smoking, and food security.

## Key Results
* **Total Sugar Intake:** The analysis yielded a **null result** ($p \approx 0.92$). Within this dataset, daily sugar intake was not a statistically significant predictor of depression scores.
* **Environmental Drivers:** The model identified **Sleep Trouble** and **Food Security** as the most powerful predictors of mental health, both showing massive statistical significance ($p < 0.001$).
* **Conclusion:** Socioeconomic stress and biological factors (sleep) far outweigh the impact of a single day's sugar intake in predicting depression severity.

## How to Recreate this Study

### Files in this Repo
* `ECON4750.Rproj`: The R Project file. Open this first to ensure relative file paths work.
* `script.R`: The complete analysis script (cleaning, imputation, and regression).
* `README.md`: Project documentation.

### Instructions
1.  **Environment:** Ensure you have R and RStudio installed.
2.  **Packages:** Install the necessary libraries:
    ```R
    install.packages(c("haven", "tidyverse", "mice"))
    ```
3.  **Data:** Ensure the following NHANES `.xpt` files are in the project root folder:
    * `DEMO_J`, `DR1TOT_J`, `DPQ_J`, `ALQ_J`, `FSQ_J`, `PAQ_J`, `SMQ_J`, `SLQ_J`.
4.  **Run:** Open `.Rproj`, then open and run `script.R`.
