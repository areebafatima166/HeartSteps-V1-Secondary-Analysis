# ============================================================
# HEARTSTEPS V1: REPRODUCIBLE SECONDARY ANALYSIS
# Project: KU Leuven PhD Profile Development
# ============================================================

# STEP 1: Clear the R environment
rm(list = ls())

# STEP 2: Load required packages
required_packages <- c("geepack", "dplyr")

for (package in required_packages) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)
  }
  library(package, character.only = TRUE)
}

# STEP 3: Define project folders
data_folder <- "data/HeartStepsV1-main/data_files"
results_folder <- "results"

if (!dir.exists(results_folder)) {
  dir.create(results_folder, recursive = TRUE)
}

# STEP 4: Load original datasets
suggestions <- read.csv(
  file.path(data_folder, "suggestions.csv"),
  stringsAsFactors = FALSE
)

users <- read.csv(
  file.path(data_folder, "users.csv"),
  stringsAsFactors = FALSE
)

gfsteps <- read.csv(
  file.path(data_folder, "gfsteps.csv"),
  stringsAsFactors = FALSE
)

jbsteps <- read.csv(
  file.path(data_folder, "jbsteps.csv"),
  stringsAsFactors = FALSE
)

# STEP 5: Check dataset dimensions
dim(suggestions)
dim(users)
dim(gfsteps)
dim(jbsteps)


# ============================================================
# HEARTSTEPS V1
# RECONSTRUCTED DATA PREPARATION AND PRIMARY ANALYSIS
# STEPS 6-34
# ============================================================

# STEP 6: Parse decision timestamps

suggestions$decision_time <- as.POSIXct(
  suggestions$sugg.decision.utime,
  format = "%Y-%m-%d %H:%M:%S",
  tz = "UTC"
)

# STEP 7: Classify treatment conditions

suggestions$treatment <- NA_character_

suggestions$treatment[
  suggestions$avail == "True" &
    suggestions$send == "False"
] <- "no_suggestion"

suggestions$treatment[
  suggestions$avail == "True" &
    suggestions$send == "True" &
    suggestions$send.active == "True" &
    suggestions$send.sedentary == "False"
] <- "active"

suggestions$treatment[
  suggestions$avail == "True" &
    suggestions$send == "True" &
    suggestions$send.active == "False" &
    suggestions$send.sedentary == "True"
] <- "sedentary"

suggestions$treatment[
  suggestions$user.index == 36 &
    suggestions$decision.index == 59
] <- "unclassified"

# STEP 8: Check treatment classification

table(suggestions$treatment, useNA = "ifany")

# STEP 9: Merge participant travel dates

suggestions <- merge(
  suggestions,
  users[, c("user.index", "travel.start", "travel.end")],
  by = "user.index",
  all.x = TRUE,
  sort = FALSE
)

# STEP 10: Convert travel dates

suggestions$travel.start <- as.Date(
  suggestions$travel.start,
  format = "%Y-%m-%d"
)

suggestions$travel.end <- as.Date(
  suggestions$travel.end,
  format = "%Y-%m-%d"
)

# STEP 11: Calculate local decision datetime

suggestions$decision_datetime_local <-
  suggestions$decision_time + suggestions$sugg.gmtoff

# STEP 12: Extract local decision date

suggestions$local_decision_date <-
  as.Date(suggestions$decision_datetime_local)

# STEP 13: Identify decisions during travel

suggestions$during_travel <- FALSE

travel_records <- !is.na(suggestions$travel.start) &
  !is.na(suggestions$travel.end) &
  !is.na(suggestions$local_decision_date)

suggestions$during_travel[travel_records] <-
  suggestions$local_decision_date[travel_records] >=
  suggestions$travel.start[travel_records] &
  suggestions$local_decision_date[travel_records] <=
  suggestions$travel.end[travel_records]

# STEP 14: Exclude decisions during travel

suggestions_no_travel <- subset(
  suggestions,
  during_travel == FALSE
)

# STEP 15: Retain available decision points

available_decisions <- subset(
  suggestions_no_travel,
  avail == "True"
)

# STEP 16: Calculate participant intake dates

users$intake_time <- as.POSIXct(
  users$intake.survey.utime,
  format = "%Y-%m-%d %H:%M:%S",
  tz = "UTC"
)

users$intake_time_local <-
  users$intake_time + users$intake.survey.gmtoff

users$intake_local_date <-
  as.Date(users$intake_time_local)

# STEP 17: Merge intake dates

available_decisions <- merge(
  available_decisions,
  users[, c("user.index", "intake_local_date")],
  by = "user.index",
  all.x = TRUE,
  sort = FALSE
)

# STEP 18: Calculate calendar study day

available_decisions$calendar_study_day <-
  as.integer(
    available_decisions$local_decision_date -
      available_decisions$intake_local_date
  )

# STEP 19: Calculate completed travel days

available_decisions$completed_travel_days <- 0L

has_travel <- !is.na(available_decisions$travel.start) &
  !is.na(available_decisions$travel.end)

travel_idx <- which(
  has_travel &
    available_decisions$local_decision_date >
    available_decisions$intake_local_date
)

travel_start_overlap <- pmax(
  available_decisions$intake_local_date[travel_idx],
  available_decisions$travel.start[travel_idx]
)

travel_end_overlap <- pmin(
  available_decisions$travel.end[travel_idx],
  available_decisions$local_decision_date[travel_idx] - 1
)

overlap_days <- as.integer(
  travel_end_overlap - travel_start_overlap
) + 1L

available_decisions$completed_travel_days[travel_idx] <-
  pmax(0L, overlap_days)

# STEP 20: Calculate provisional study day

available_decisions$provisional_study_day <-
  available_decisions$calendar_study_day -
  available_decisions$completed_travel_days

# STEP 21: Restrict to study days 0-41

candidate_decisions <- subset(
  available_decisions,
  provisional_study_day >= 0 &
    provisional_study_day <= 41
)

# STEP 22: Retain classified treatment conditions

main_candidates <- subset(
  candidate_decisions,
  !is.na(treatment) &
    treatment %in% c(
      "active",
      "no_suggestion",
      "sedentary"
    )
)

# STEP 23: Inspect outcome variables

summary(main_candidates$jbsteps30)
summary(main_candidates$jbsteps30pre)

# STEP 24: Examine missingness overlap

table(
  Post_Outcome_Missing = is.na(main_candidates$jbsteps30),
  Pre_Outcome_Missing = is.na(main_candidates$jbsteps30pre)
)

# STEP 25: Create complete-case analysis dataset

analysis_data <- main_candidates[
  complete.cases(
    main_candidates[, c("jbsteps30", "jbsteps30pre")]
  ),
]

# STEP 26: Log-transform outcomes

analysis_data$log_steps30 <-
  log(analysis_data$jbsteps30 + 0.5)

analysis_data$log_steps30pre <-
  log(analysis_data$jbsteps30pre + 0.5)

# STEP 27: Create centered treatment indicators

analysis_data$active <- ifelse(
  analysis_data$treatment == "active",
  1,
  0
)

analysis_data$sedentary <- ifelse(
  analysis_data$treatment == "sedentary",
  1,
  0
)

analysis_data$active_centered <-
  analysis_data$active - 0.30

analysis_data$sedentary_centered <-
  analysis_data$sedentary - 0.30

# STEP 28: Primary exchangeable GEE model

gee_model_primary <- geepack::geeglm(
  log_steps30 ~
    log_steps30pre +
    active_centered +
    sedentary_centered,
  id = user.index,
  data = analysis_data,
  family = gaussian,
  corstr = "exchangeable",
  scale.fix = TRUE
)

summary(gee_model_primary)

# STEP 29: Calculate primary treatment effects

primary_coef <- summary(
  gee_model_primary
)$coefficients

primary_effects <- data.frame(
  Treatment = c("Walking", "Anti-sedentary"),
  Estimate = c(
    primary_coef["active_centered", "Estimate"],
    primary_coef["sedentary_centered", "Estimate"]
  ),
  SE = c(
    primary_coef["active_centered", "Std.err"],
    primary_coef["sedentary_centered", "Std.err"]
  ),
  P_value = c(
    primary_coef["active_centered", "Pr(>|W|)"],
    primary_coef["sedentary_centered", "Pr(>|W|)"]
  )
)

primary_effects$Percent_Change <-
  (exp(primary_effects$Estimate) - 1) * 100

primary_effects$CI_Lower <-
  (exp(primary_effects$Estimate -
         1.96 * primary_effects$SE) - 1) * 100

primary_effects$CI_Upper <-
  (exp(primary_effects$Estimate +
         1.96 * primary_effects$SE) - 1) * 100

print(primary_effects)

# STEP 30: Independence GEE sensitivity model

gee_model_independence <- geepack::geeglm(
  log_steps30 ~
    log_steps30pre +
    active_centered +
    sedentary_centered,
  id = user.index,
  data = analysis_data,
  family = gaussian,
  corstr = "independence",
  scale.fix = TRUE
)

summary(gee_model_independence)

# STEP 31: Calculate independence model effects

ind_coef <- summary(
  gee_model_independence
)$coefficients

independence_effects <- data.frame(
  Treatment = c("Walking", "Anti-sedentary"),
  Estimate = c(
    ind_coef["active_centered", "Estimate"],
    ind_coef["sedentary_centered", "Estimate"]
  ),
  SE = c(
    ind_coef["active_centered", "Std.err"],
    ind_coef["sedentary_centered", "Std.err"]
  ),
  P_value = c(
    ind_coef["active_centered", "Pr(>|W|)"],
    ind_coef["sedentary_centered", "Pr(>|W|)"]
  )
)

independence_effects$Percent_Change <-
  (exp(independence_effects$Estimate) - 1) * 100

independence_effects$CI_Lower <-
  (exp(independence_effects$Estimate -
         1.96 * independence_effects$SE) - 1) * 100

independence_effects$CI_Upper <-
  (exp(independence_effects$Estimate +
         1.96 * independence_effects$SE) - 1) * 100

print(independence_effects)

# STEP 32: Prepare zero-adjusted analysis dataset

zero_analysis_data <- main_candidates

zero_analysis_data$log_steps30_zero <-
  log(zero_analysis_data$jbsteps30.zero + 0.5)

zero_analysis_data$log_steps30pre_zero <-
  log(zero_analysis_data$jbsteps30pre.zero + 0.5)

zero_analysis_data$active <- ifelse(
  zero_analysis_data$treatment == "active",
  1,
  0
)

zero_analysis_data$sedentary <- ifelse(
  zero_analysis_data$treatment == "sedentary",
  1,
  0
)

zero_analysis_data$active_centered <-
  zero_analysis_data$active - 0.30

zero_analysis_data$sedentary_centered <-
  zero_analysis_data$sedentary - 0.30

# STEP 33: Zero-adjusted exchangeable GEE model

gee_model_zero <- geepack::geeglm(
  log_steps30_zero ~
    log_steps30pre_zero +
    active_centered +
    sedentary_centered,
  id = user.index,
  data = zero_analysis_data,
  family = gaussian,
  corstr = "exchangeable",
  scale.fix = TRUE
)

summary(gee_model_zero)

# STEP 34: Calculate zero-adjusted model effects

zero_coef <- summary(
  gee_model_zero
)$coefficients

zero_effects <- data.frame(
  Treatment = c("Walking", "Anti-sedentary"),
  Estimate = c(
    zero_coef["active_centered", "Estimate"],
    zero_coef["sedentary_centered", "Estimate"]
  ),
  SE = c(
    zero_coef["active_centered", "Std.err"],
    zero_coef["sedentary_centered", "Std.err"]
  ),
  P_value = c(
    zero_coef["active_centered", "Pr(>|W|)"],
    zero_coef["sedentary_centered", "Pr(>|W|)"]
  )
)

zero_effects$Percent_Change <-
  (exp(zero_effects$Estimate) - 1) * 100

zero_effects$CI_Lower <-
  (exp(zero_effects$Estimate -
         1.96 * zero_effects$SE) - 1) * 100

zero_effects$CI_Upper <-
  (exp(zero_effects$Estimate +
         1.96 * zero_effects$SE) - 1) * 100

print(zero_effects)


# STEP 35: MISSINGNESS ANALYSIS BY TREATMENT
# ============================================================
# Create missingness indicators
main_candidates$post_missing <-
as.integer(is.na(main_candidates$jbsteps30))
main_candidates$pre_missing <-
as.integer(is.na(main_candidates$jbsteps30pre))
# Define treatment groups
treatment_groups <- c(
"active",
"no_suggestion",
"sedentary"
)
# Calculate missingness for each treatment group
missingness_by_treatment <- do.call(
rbind,
lapply(treatment_groups, function(group) {
group_data <- subset(
main_candidates,
treatment == group
)
data.frame(
Treatment = group,
Total = nrow(group_data),
Post_Missing = sum(group_data$post_missing),
Pre_Missing = sum(group_data$pre_missing),
Post_Missing_Percent =
mean(group_data$post_missing) * 100,
Pre_Missing_Percent =
mean(group_data$pre_missing) * 100
)
})
)
# Round percentages
missingness_by_treatment[, 5:6] <-
round(missingness_by_treatment[, 5:6], 2)
# Display missingness by treatment
print(missingness_by_treatment)
# Examine overlap between pre- and post-outcome missingness
missingness_overlap <- table(
Post_Outcome_Missing = main_candidates$post_missing,
Pre_Outcome_Missing = main_candidates$pre_missing
)
print(missingness_overlap)
# Count observations with at least one missing outcome
sum(
main_candidates$post_missing == 1 |
main_candidates$pre_missing == 1
)
print(missingness_by_treatment)
# ============================================================
# STEP 36: POST-OUTCOME MISSINGNESS MODEL
# ============================================================
# Retain observations with available pretreatment activity
post_missing_data <- subset(
main_candidates,
!is.na(jbsteps30pre)
)
# Log-transform pretreatment activity
post_missing_data$log_pre <-
log(post_missing_data$jbsteps30pre + 0.5)
# Create missingness indicator
post_missing_data$post_missing <-
as.integer(is.na(post_missing_data$jbsteps30))
# Fit logistic GEE model
post_missing_model <- geepack::geeglm(
post_missing ~ log_pre + treatment,
id = user.index,
data = post_missing_data,
family = binomial(link = "logit"),
corstr = "exchangeable"
)
# Display results
summary(post_missing_model)
# Check sample size
nrow(post_missing_data)
length(unique(post_missing_data$user.index))
# ============================================================
# STEP 37: POST-MISSINGNESS ODDS RATIOS
# ============================================================
post_coef <- summary(post_missing_model)$coefficients
post_or_table <- data.frame(
Predictor = rownames(post_coef),
Odds_Ratio = exp(post_coef[, "Estimate"]),
CI_Lower = exp(
post_coef[, "Estimate"] -
1.96 * post_coef[, "Std.err"]
),
CI_Upper = exp(
post_coef[, "Estimate"] +
1.96 * post_coef[, "Std.err"]
),
P_Value = post_coef[, "Pr(>|W|)"]
)
# Exclude intercept
post_or_table <- subset(
post_or_table,
Predictor != "(Intercept)"
)
# Round results
post_or_table[, 2:5] <-
lapply(post_or_table[, 2:5], round, 3)
print(post_or_table)
# ============================================================
# STEP 38: PRETREATMENT MISSINGNESS MODEL
# ============================================================
# Create pretreatment missingness indicator
main_candidates$pre_missing <-
as.integer(is.na(main_candidates$jbsteps30pre))
# Fit logistic GEE model
pre_missing_model <- geepack::geeglm(
pre_missing ~ treatment,
id = user.index,
data = main_candidates,
family = binomial(link = "logit"),
corstr = "exchangeable"
)
# Display model results
summary(pre_missing_model)
# Check sample size
nrow(main_candidates)
length(unique(main_candidates$user.index))
# ============================================================
# STEP 39: PRETREATMENT MISSINGNESS ODDS RATIOS
# ============================================================
pre_coef <- summary(pre_missing_model)$coefficients
pre_or_table <- data.frame(
Predictor = rownames(pre_coef),
Odds_Ratio = exp(pre_coef[, "Estimate"]),
CI_Lower = exp(
pre_coef[, "Estimate"] -
1.96 * pre_coef[, "Std.err"]
),
CI_Upper = exp(
pre_coef[, "Estimate"] +
1.96 * pre_coef[, "Std.err"]
),
P_Value = pre_coef[, "Pr(>|W|)"]
)
# Exclude intercept
pre_or_table <- subset(
pre_or_table,
Predictor != "(Intercept)"
)
# Round results
pre_or_table[, 2:5] <-
lapply(pre_or_table[, 2:5], round, 3)
print(pre_or_table)
# ============================================================
# STEP 40: SAMPLE FLOW TABLE
# ============================================================
sample_flow <- data.frame(
Stage = c(
"Original decision records",
"After excluding travel decisions",
"Available decision points",
"Study days 0-41",
"After excluding unclassified treatment",
"Complete-case analysis"
),
Observations = c(
nrow(suggestions),
nrow(suggestions_no_travel),
nrow(available_decisions),
nrow(candidate_decisions),
nrow(main_candidates),
nrow(analysis_data)
),
Participants = c(
length(unique(suggestions$user.index)),
length(unique(suggestions_no_travel$user.index)),
length(unique(available_decisions$user.index)),
length(unique(candidate_decisions$user.index)),
length(unique(main_candidates$user.index)),
length(unique(analysis_data$user.index))
)
)
print(sample_flow)
# ============================================================
# STEP 41: PREPARE FINAL MODEL COMPARISON
# ============================================================
final_model_comparison <- rbind(
data.frame(
Model = "Exchangeable complete-case",
primary_effects
),
data.frame(
Model = "Independence complete-case",
independence_effects
),
data.frame(
Model = "Zero-adjusted exchangeable",
zero_effects
)
)
# Round numerical results
numeric_columns <- sapply(final_model_comparison, is.numeric)
final_model_comparison[numeric_columns] <- lapply(
  final_model_comparison[numeric_columns],
  round,
  3
)
print(final_model_comparison)
# Ensure results folder exists
results_folder <- "results"
if (!dir.exists(results_folder)) {
dir.create(results_folder, recursive = TRUE)
}
dir.exists(results_folder)
# ============================================================
# STEP 42: EXPORT RESULTS TABLES
# ============================================================
final_results_folder <- file.path(
  results_folder,
  "final_submission_tables"
)
dir.create(
  final_results_folder,
  showWarnings = FALSE,
  recursive = TRUE
)
write.csv(sample_flow, file.path(final_results_folder, "01_sample_flow.csv"), row.names = FALSE)
write.csv(primary_effects, file.path(final_results_folder, "02_primary_model_effects.csv"), row.names = FALSE)
write.csv(independence_effects, file.path(final_results_folder, "03_independence_model_effects.csv"), row.names = FALSE)
write.csv(zero_effects, file.path(final_results_folder, "04_zero_adjusted_effects.csv"), row.names = FALSE)
write.csv(missingness_by_treatment, file.path(final_results_folder, "05_missingness_by_treatment.csv"), row.names = FALSE)
write.csv(post_or_table, file.path(final_results_folder, "06_post_missingness_odds_ratios.csv"), row.names = FALSE)
write.csv(pre_or_table, file.path(final_results_folder, "07_pre_missingness_odds_ratios.csv"), row.names = FALSE)
write.csv(final_model_comparison, file.path(final_results_folder, "08_final_model_comparison.csv"), row.names = FALSE)
write.csv(missingness_overlap, file.path(results_folder, "HeartSteps_Missingness_Overlap.csv"))
# ============================================================
# STEP 43: COMBINE ALL GEE MODEL COEFFICIENTS
# ============================================================
extract_gee_results <- function(model, model_name) {
coefficients <- as.data.frame(
summary(model)$coefficients
)
coefficients$Predictor <- rownames(coefficients)
coefficients$Model <- model_name
rownames(coefficients) <- NULL
coefficients <- coefficients[
,
c(
"Model",
"Predictor",
"Estimate",
"Std.err",
"Wald",
"Pr(>|W|)"
)
]
return(coefficients)
}
all_gee_results <- rbind(
extract_gee_results(
gee_model_primary,
"Primary exchangeable complete-case"
),
extract_gee_results(
gee_model_independence,
"Independence complete-case"
),
extract_gee_results(
gee_model_zero,
"Zero-adjusted exchangeable"
),
extract_gee_results(
post_missing_model,
"Post-outcome missingness"
),
extract_gee_results(
pre_missing_model,
"Pretreatment missingness"
)
)
# Export combined coefficients
write.csv(
all_gee_results,
file.path(
final_results_folder,
"09_all_gee_model_coefficients.csv"
),
row.names = FALSE
)
# Display results
print(all_gee_results)
# ============================================================
# STEP 44: VERIFY EXPORTED RESULTS
# ============================================================
# Check all nine expected output files
expected_files <- c(
  "01_sample_flow.csv",
  "02_primary_model_effects.csv",
  "03_independence_model_effects.csv",
  "04_zero_adjusted_effects.csv",
  "05_missingness_by_treatment.csv",
  "06_post_missingness_odds_ratios.csv",
  "07_pre_missingness_odds_ratios.csv",
  "08_final_model_comparison.csv",
  "09_all_gee_model_coefficients.csv"
)
file_check <- data.frame(
  File = expected_files,
  Exists = file.exists(file.path(final_results_folder, expected_files))
)
print(file_check)
# Read exported coefficients back into R
verified_coefficients <- read.csv(
  file.path(final_results_folder, '09_all_gee_model_coefficients.csv')
)
# Check dimensions and model names
print(dim(verified_coefficients))
print(head(verified_coefficients))
print(unique(verified_coefficients$Model))
# Check whether all nine files exist
stopifnot(all(file_check$Exists))
# ============================================================
