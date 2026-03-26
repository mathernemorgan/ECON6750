library(haven)
library(tidyverse)
library(mice)

# Load each component
demo <- read_xpt("DEMO_J.xpt")
diet <- read_xpt("DR1TOT_J.xpt")
depr <- read_xpt("DPQ_J.xpt")
alc <- read_xpt("ALQ_J.xpt")
food_safety <- read_xpt("FSQ_J.xpt")
phys_activity <- read_xpt("PAQ_J.xpt")
smoking <- read_xpt("SMQ_J.xpt")
sleep <- read_xpt("SLQ_J.xpt")

# Join them into one dataframe
df_master <- demo %>%
  full_join(diet, by = "SEQN") %>%
  full_join(depr, by = "SEQN") %>%
  full_join(alc, by = "SEQN") %>%
  full_join(food_safety, by = "SEQN") %>%
  full_join(phys_activity, by = "SEQN") %>%
  full_join(smoking, by = "SEQN") %>%
  full_join(sleep, by = "SEQN")

# Create a focused subset for your study
df_study <- df_master %>%
  filter(RIDAGEYR >= 18) %>% # Only adults are eligible for the PHQ-9
  select(
    SEQN, 
    sugar = DR1TSUGR,           # Treatment
    matches("DPQ0[1-9]0"),      # Outcome
    income_ratio = INDFMPIR,    # Key Confounder
    age = RIDAGEYR, 
    gender = RIAGENDR, 
    edu = DMDEDUC2, 
    marital = DMDMARTL,
    calories = DR1TKCAL, 
    caffeine = DR1TCAFF,
    food_sec = FSDAD,
    active = PAQ605,            # Vigorous work activity
    sleep_trouble = SLQ050, 
    smoking = SMQ020
  ) %>%
# Clean 7s and 9s across all DPQ columns
  mutate(across(starts_with("DPQ"), ~ifelse(.x > 3, NA, .x)))

# Calculate total depression score
df_study <- df_study %>%
  rowwise() %>%
  mutate(phq9_total = sum(c_across(starts_with("DPQ")), na.rm = FALSE)) %>%
  ungroup()

# Convert categorical variables to factors
df_study <- df_study %>%
  mutate(across(c(gender, edu, marital, food_sec, sleep_trouble, smoking), as.factor))

# Now check the missingness again
colSums(is.na(df_study))


# This will create 5 different 'imputed' versions of your dataset
# 'm = 5' is the standard for stable estimates
# 'maxit = 50' gives the algorithm enough iterations to converge
imp_model <- mice(df_study, m = 5, method = 'pmm', seed = 123, printFlag = FALSE)


# dropped edu and marital because of collinearity

# Check if there were any errors during the process
imp_model$loggedEvents

# Visualize the density of observed (blue) vs imputed (red) data
densityplot(imp_model, ~ sugar + income_ratio + calories)

# 1. Run the regression model on all 5 imputed versions of your data
# This uses the 'depressed' variable (DPQ020) as your outcome
fit <- with(imp_model, lm(phq9_total ~ sugar + calories + income_ratio + 
                            age + gender + edu + marital + 
                            caffeine + food_sec + active + 
                            sleep_trouble + smoking))

# 2. Pool the results into one set of estimates
pooled_results <- pool(fit)

# 3. View the summary
summary(pooled_results)


library(ggplot2)

# Convert pooled results to a tidy dataframe for plotting
plot_data <- summary(pooled_results) %>%
  filter(term != "(Intercept)") # Remove intercept to keep scale readable

ggplot(plot_data, aes(x = reorder(term, estimate), y = estimate)) +
  geom_point(size = 3, color = "#2c3e50") +
  geom_errorbar(aes(ymin = estimate - 1.96*std.error, 
                    ymax = estimate + 1.96*std.error), 
                width = 0.2, color = "#2c3e50") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  coord_flip() +
  labs(title = "Causal Drivers of Depression Score (PHQ-9)",
       subtitle = "Sugar intake vs. Socioeconomic & Behavioral Controls",
       x = "Variable",
       y = "Effect on PHQ-9 Total Score (with 95% CI)") +
  theme_minimal()
