rm(list = ls())

library(dplyr)

dat <- readRDS("data/processed/nhanes_analysis_ready.rds")

# -----------------------------
# Quick summaries
# -----------------------------
summary(dat$phq9_score)
summary(dat$total_sugar_g)
summary(dat$total_sugar_g_winsor)
summary(dat$sugar_per_1000kcal)
summary(dat$sugar_per_1000kcal_winsor)
summary(dat$bmi)
summary(dat$weight_8yr)

# -----------------------------
# Model 1: raw sugar
# -----------------------------
m1 <- lm(phq9_score ~ total_sugar_g, data = dat)
summary(m1)

# -----------------------------
# Model 2: winsorized sugar
# -----------------------------
m2 <- lm(phq9_score ~ total_sugar_g_winsor, data = dat)
summary(m2)

# -----------------------------
# Model 3: sugar density with controls
# -----------------------------
m3 <- lm(phq9_score ~ sugar_per_1000kcal +
           RIDAGEYR + female + INDFMPIR +
           sleep_hours + ever_smoked +
           vigorous_activity + moderate_activity +
           cycle,
         data = dat)
summary(m3)

# -----------------------------
# Model 4: winsorized sugar density with controls
# -----------------------------
m4 <- lm(phq9_score ~ sugar_per_1000kcal_winsor +
           RIDAGEYR + female + INDFMPIR +
           sleep_hours + ever_smoked +
           vigorous_activity + moderate_activity +
           cycle,
         data = dat)
summary(m4)

# -----------------------------
# Model 5: add BMI
# -----------------------------
m5 <- lm(phq9_score ~ sugar_per_1000kcal_winsor +
           RIDAGEYR + female + INDFMPIR +
           sleep_hours + ever_smoked +
           vigorous_activity + moderate_activity +
           bmi + cycle,
         data = dat)
summary(m5)

# -----------------------------
# Model 6: weighted model
# -----------------------------
m6 <- lm(phq9_score ~ sugar_per_1000kcal_winsor +
           RIDAGEYR + female + INDFMPIR +
           sleep_hours + ever_smoked +
           vigorous_activity + moderate_activity +
           bmi + cycle,
         data = dat,
         weights = weight_8yr)
summary(m6)

# -----------------------------
# Model 7: weighted logistic model
# -----------------------------
m7 <- glm(depression_binary ~ sugar_per_1000kcal_winsor +
            RIDAGEYR + female + INDFMPIR +
            sleep_hours + ever_smoked +
            vigorous_activity + moderate_activity +
            bmi + cycle,
          data = dat,
          family = binomial(),
          weights = weight_8yr)
summary(m7)

# -----------------------------
# Model 8: nonlinear weighted model
# -----------------------------
m8 <- lm(phq9_score ~ sugar_per_1000kcal_winsor +
           I(sugar_per_1000kcal_winsor^2) +
           RIDAGEYR + female + INDFMPIR +
           sleep_hours + ever_smoked +
           vigorous_activity + moderate_activity +
           bmi + cycle,
         data = dat,
         weights = weight_8yr)
summary(m8)

# -----------------------------
# Model 9: interaction by gender
# -----------------------------
m9 <- lm(phq9_score ~ sugar_per_1000kcal_winsor * female +
           RIDAGEYR + INDFMPIR +
           sleep_hours + ever_smoked +
           vigorous_activity + moderate_activity +
           bmi + cycle,
         data = dat,
         weights = weight_8yr)
summary(m9)


