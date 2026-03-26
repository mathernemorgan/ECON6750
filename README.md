# ECON6750 NHANES Analysis: Daily Sugar Intake and Mental Health (PHQ-9)

## Project Overview
This repository contains a causal inference study investigating the relationship between **daily total sugar intake (grams)** and **depression severity**. The analysis utilizes data from the **2017-2018 NHANES cycle** (Cycle J).

The core research question asks: *Does daily sugar intake affect mental health after controlling for socioeconomic and behavioral confounders?*

## Methodology

### 1. Data Integration & Cleaning
Data was merged from eight NHANES components using the `SEQN` (Respondent Sequence Number) key. 
* **Target Cohort:** Adults (18+) who were eligible for the PHQ-9 depression screener.
* **Outcome Variable:** A clinical **PHQ-9 Total Score** (0–27), calculated by summing nine individual symptom questions. 
* **Treatment Variable:** Daily sugar intake (`DR1TSUGR`) from the first day of dietary recall.
* **Refusal Handling:** Participant responses of "Refused" (7) or "Don't Know" (9) were recoded as `NA` to avoid skewing the scoring system.

### 2. Multiple Imputation (MICE)
To handle missingness in dietary data and sensitive demographic questions (like income), I used **Multivariate Imputation by Chained Equations (MICE)** with **Predictive Mean Matching (PMM)**. This generated five unique imputed datasets to ensure the final estimates account for the uncertainty of the missing values.

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
