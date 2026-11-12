# HeartSteps V1: Reproducible Secondary Analysis of Physical Activity Suggestions

## 1. Project Overview

This project presents an independent secondary analysis of the publicly available HeartSteps V1 dataset.

The study investigates whether contextually tailored physical activity suggestions are associated with changes in participants' subsequent step activity.

HeartSteps is a mobile health intervention designed to encourage physical activity through suggestions delivered at different decision points throughout the day.

This project uses longitudinal data and Generalized Estimating Equations (GEE) to examine the relationships between intervention conditions and subsequent physical activity.

The analysis was conducted in R using a reproducible workflow, including data cleaning, treatment classification, study-day reconstruction, missing-data assessment, statistical modelling, and sensitivity analyses.

## 2. Research Question

Are walking and anti-sedentary suggestions associated with differences in subsequent 30-minute step activity compared with decision points at which no suggestion was sent?

### Treatment Conditions

Three treatment conditions were examined:

- **Active (walking suggestion):** A suggestion intended to encourage participants to increase their physical activity.
- **Sedentary (anti-sedentary suggestion):** A suggestion intended to encourage participants to interrupt sedentary behaviour.
- **No suggestion:** An available decision point at which no suggestion was sent. This was used as the reference condition.

## 3. Original Dataset and Research Paper

The analysis uses the HeartSteps V1 dataset.

**Original research paper:**

Klasnja, P., Smith, S., Seewald, N. J., Lee, A., Hall, K., Luers, B., Hekler, E. B., & Murphy, S. A. (2019). Efficacy of contextually tailored suggestions for physical activity: A micro-randomized optimization trial of HeartSteps. *Annals of Behavioral Medicine, 53*(6), 573–582.

https://doi.org/10.1093/abm/kay067

**Original dataset repository:**

https://github.com/klasnja/HeartStepsV1

The original research paper is cited to acknowledge the study from which the secondary-analysis data originate.

This project is an independent secondary analysis and does not claim to reproduce the original paper's primary statistical estimator.

## 4. Dataset Description

The HeartSteps V1 dataset contains repeated observations collected from participants during a mobile health intervention.

The project uses the following original data files:

| File | Description |
|---|---|
| `suggestions.csv` | Decision-point information and intervention suggestions |
| `users.csv` | Participant-level information |
| `gfsteps.csv` | Google Fit step activity records |
| `jbsteps.csv` | Jawbone step activity records |

The data contain repeated decision points nested within participants.

### Dataset Dimensions

The original data files used in the analysis had the following dimensions:

| Dataset | Rows | Columns |
|---|---:|---:|
| Suggestions | 8,274 | 86 |
| Users | 37 | 117 |
| Google Fit steps | 197,524 | 7 |
| Jawbone steps | 237,865 | 10 |

The final analytical sample included:

- 37 participants.
- 5,321 complete-case observations.
- Three treatment conditions.

## 5. Sample Selection and Data Processing

The analysis involved several data-processing and eligibility checks.

The sample flow was:

| Processing Stage | Observations |
|---|---:|
| Original decision records | 8,274 |
| After travel exclusions | 7,884 |
| Available decision points | 6,331 |
| Within study days 0–41 | 6,062 |
| After excluding unclassified treatment | 6,061 |
| Final complete-case analysis | 5,321 |

The processing workflow included:

1. Importing the original HeartSteps V1 data files.
2. Inspecting variable types and dataset dimensions.
3. Classifying intervention conditions using the original suggestion indicators.
4. Identifying travel-related observations.
5. Reconstructing study days.
6. Restricting observations to the defined study period.
7. Preparing subsequent and pretreatment step activity measures.
8. Identifying missing outcome and pretreatment activity observations.
9. Creating the final analytical dataset.

One available decision point had a sent suggestion but empty active and sedentary subtype indicators. This observation was retained as unclassified and excluded from the treatment-effect analysis rather than assigned an assumed treatment condition.

## 6. Outcome and Predictor Variables

### Primary Outcome

The primary outcome was subsequent 30-minute step activity.

The outcome was log-transformed for the GEE models.

### Pretreatment Activity

Pretreatment 30-minute step activity was included as an adjustment variable.

### Treatment Predictors

Two treatment indicators were created:

- Active treatment.
- Sedentary treatment.

The no-suggestion condition was used as the reference category.

Treatment indicators were centred for the statistical models.

## 7. Statistical Analysis

All statistical analyses were conducted using R.

### 7.1 Primary Analysis: Generalized Estimating Equations

The primary analysis used Gaussian Generalized Estimating Equations (GEE).

An exchangeable working correlation structure was specified to account for repeated observations within participants.

The model included:

- Subsequent log-transformed 30-minute step activity as the outcome.
- Pretreatment log-transformed step activity as an adjustment variable.
- Active treatment indicator.
- Sedentary treatment indicator.

The participant identifier was used to define clusters.

### 7.2 Independence Correlation Model

A second GEE model used an independence working correlation structure.

This analysis examined whether the estimated treatment associations were consistent under a different working correlation assumption.

### 7.3 Zero-Adjusted Sensitivity Analysis

An additional sensitivity analysis used zero-adjusted step activity variables.

The purpose was to examine whether the main treatment estimates were sensitive to the handling of zero step totals before logarithmic transformation.

### 7.4 Missing-Data Assessment

Missingness was examined across treatment conditions.

The project included:

- Missingness summaries by treatment group.
- A post-outcome missingness logistic regression model.
- A pretreatment missingness logistic regression model.
- Comparisons of missingness patterns across intervention conditions.

These analyses were exploratory and were not intended to establish that missing data were missing completely at random or missing at random.

## 8. Main Findings

### 8.1 Primary GEE Results

The primary exchangeable GEE model produced the following estimates:

| Treatment | Estimated Percentage Difference | p-value |
|---|---:|---:|
| Walking suggestion | +22.65% | .019 |
| Anti-sedentary suggestion | +7.35% | .434 |

Walking suggestions were associated with approximately 22.65% higher subsequent 30-minute step activity compared with the no-suggestion condition.

The anti-sedentary estimate was positive but was not statistically significant.

### 8.2 Sensitivity Analyses

The estimated associations were broadly consistent across the additional models.

| Model | Walking Estimate | Anti-Sedentary Estimate |
|---|---:|---:|
| Primary exchangeable GEE | +22.65% | +7.35% |
| Independence GEE | +22.55% | +8.25% |
| Zero-adjusted exchangeable GEE | +23.63% | +2.58% |

The walking association remained statistically significant across these analyses.

The anti-sedentary association remained statistically non-significant.

### 8.3 Interpretation

The findings suggest that decision points with walking suggestions were associated with higher subsequent step activity than decision points with no suggestions in this secondary analysis.

However, the results do not establish that the suggestions definitively caused an increase in physical activity.

The findings should be interpreted cautiously in light of the number of participants, missing observations, and analytical differences from the original HeartSteps study.

## 9. Reproducible Analysis and Project Structure

The GitHub repository contains the master analysis script, final result tables, session information, and this README file.

```text
HeartSteps-V1-Secondary-Analysis/
│
├── 04_HeartSteps_COMPLETE_MASTER_SCRIPT.R
├── 01_sample_flow.csv
├── 02_primary_model_effects.csv
├── 03_independence_model_effects.csv
├── 04_zero_adjusted_effects.csv
├── 05_missingness_by_treatment.csv
├── 06_post_missingness_odds_ratios.csv
├── 07_pre_missingness_odds_ratios.csv
├── 08_final_model_comparison.csv
├── 09_all_gee_model_coefficients.csv
├── sessionInfo.txt
└── README.md
```

### Local RStudio Working Directory

The local working directory used to conduct the analysis contains the original data files and the results folder.

```text
HeartSteps_Real_Data_Project/
│
├── data/
│   └── HeartStepsV1-main/
│       └── data_files/
│           ├── suggestions.csv
│           ├── users.csv
│           ├── gfsteps.csv
│           └── jbsteps.csv
│
├── results/
│   ├── final_submission_tables/
│   │   ├── 01_sample_flow.csv
│   │   ├── 02_primary_model_effects.csv
│   │   ├── 03_independence_model_effects.csv
│   │   ├── 04_zero_adjusted_effects.csv
│   │   ├── 05_missingness_by_treatment.csv
│   │   ├── 06_post_missingness_odds_ratios.csv
│   │   ├── 07_pre_missingness_odds_ratios.csv
│   │   ├── 08_final_model_comparison.csv
│   │   └── 09_all_gee_model_coefficients.csv
│   │
│   └── sessionInfo.txt
│
└── 04_HeartSteps_COMPLETE_MASTER_SCRIPT.R
```

### Reproducibility Information

The file `sessionInfo.txt` records the R session and package information used during the analysis.

The master script was tested after restarting R, and the expected nine output tables were verified.

To reproduce the analysis:

1. Obtain the original HeartSteps V1 data from its official repository.
2. Place the original data files in the expected data directory.
3. Open the master R script in RStudio.
4. Set the working directory to the project root if necessary.
5. Execute the script from the beginning.

The original participant-level data files are not included in this public repository.

## 10. Limitations

Several limitations should be considered when interpreting the results.

1. **Secondary analysis:** The project uses an existing dataset collected for the original HeartSteps study.

2. **Number of participants:** The final analysis includes 37 participants, which limits the generalisability of the findings.

3. **Repeated observations:** The dataset contains repeated decision points within participants. GEE was used to account for within-participant correlation.

4. **Missing data:** Complete-case analysis may introduce bias if the probability of missingness is related to observed or unobserved characteristics.

5. **Analytical differences:** The present exploratory GEE approach is not identical to the original study's weighted least-squares estimator.

6. **Study-day reconstruction:** Study-day eligibility was reconstructed using the available public dataset information and documented processing decisions.

7. **Treatment classification:** One available decision point had missing treatment subtype indicators and was retained as unclassified.

8. **Exploratory interpretation:** The findings should be considered exploratory associations rather than definitive causal evidence.

## 11. Research Skills Demonstrated

This project provided practical experience in:

- Working with real-world longitudinal health data.
- Cleaning and preparing repeated-measures datasets.
- Treatment classification and eligibility assessment.
- Reconstructing study timelines.
- Managing missing observations.
- Preparing log-transformed activity variables.
- Generalized Estimating Equations.
- Working correlation structures.
- Sensitivity analyses.
- Logistic regression for missingness assessment.
- Reproducible statistical programming in R.
- Exporting and documenting research results.

## 12. Project Purpose

This project was developed to strengthen practical research experience in quantitative psychology, digital health interventions, longitudinal data analysis, and reproducible statistical methods.

It demonstrates an independent secondary-data workflow using an existing mobile health intervention dataset.

The project aims to contribute to methodological understanding of how intervention suggestions can be evaluated using repeated observations in digital health research.

---

**Project type:** Independent secondary-data analysis

**Dataset:** HeartSteps V1

**Software:** R and RStudio

**Primary statistical method:** Generalized Estimating Equations

**Final analytical sample:** 5,321 observations from 37 participants

**Research area:** Digital health interventions, physical activity, longitudinal data analysis, and quantitative methods
