# =====================================================================
# Build the Supporting Information data file:
#   Sheet 1 "data"     - the full analysis dataset (1 row = 1 effect size)
#   Sheet 2 "metadata" - data dictionary describing every column
# Output: output/SI_dataset_for_submission.xlsx
# Run: Rscript R/build_SI_dataset.R
# =====================================================================

suppressMessages({library(tidyverse); library(here); library(openxlsx)})

# Write numbers with an explicit format that has NO thousands separator, so no
# spreadsheet app (Excel/Numbers) adds grouping commas (e.g. "2,020" for a year).
# "0.############" shows integers with no decimals and reals to full needed
# precision, never a comma. Stored values remain exact doubles.
options(openxlsx.numFmt = "0.############")

# ---- assemble the analysis dataset (the data underlying all results) ----
path  <- here::here("output", "data")
files <- list.files(path)
dl <- lapply(file.path(path, files), read.csv); names(dl) <- files
d  <- plyr::ldply(dl)
lab <- c(cort_stress.csv = "Glucocorticoids", deprive_stress.csv = "Parental care deprivation",
         disturb_stress.csv = "Psychological disturbance", nutri_stress.csv = "Nutritional imbalance")
d <- d %>% mutate(stressor_category = lab[.id], .before = 1) %>% select(-.id)

# ---- data dictionary -------------------------------------------------
desc <- c(
  stressor_category           = "Developmental stressor category for this effect size (Glucocorticoids, Parental care deprivation, Psychological disturbance, or Nutritional imbalance); corresponds to the four analysed datasets.",
  exclude_missing_info        = "Data-processing flag; rows retained for analysis after screening for the information required to compute an effect size (1 = retained).",
  study                       = "Unique study identifier (e.g. s1, s3). Multiple effect sizes can come from the same study.",
  author                      = "First-author surname of the source publication.",
  year                        = "Year the source publication appeared.",
  class                       = "Taxonomic class (Aves, Mammalia, Actinopterygii, Amphibia).",
  order                       = "Taxonomic order.",
  family                      = "Taxonomic family.",
  genus                       = "Genus.",
  species                     = "Specific epithet (species name).",
  common_name                 = "Common name of the study species.",
  prenatal_dev_time           = "Length of the prenatal developmental period (days).",
  postnatal_dev_time          = "Length of the postnatal developmental period, hatching/birth to sexual maturity (days).",
  age_sexual_maturity         = "Age at sexual maturity (days).",
  life_expectancy             = "Species life expectancy (days).",
  unit_dev_time               = "Time unit for the developmental-time fields (days).",
  stage                       = "Developmental stage when the stressor was applied (prenatal, postnatal, or both).",
  sex                         = "Sex of the study animals (male, female, or both).",
  prenatal_trt_start          = "Day prenatal treatment began (0 = conception).",
  prenatal_trt_end            = "Day prenatal treatment ended.",
  prenatal_dur                = "Duration of prenatal treatment (inclusive of start and end days).",
  prenatal_unit               = "Time unit for the prenatal treatment fields.",
  post_natal_trt_start        = "Day postnatal treatment began (0 = day of birth or hatching).",
  postnatal_trt_end           = "Day postnatal treatment ended.",
  dur_trt_postnatal           = "Duration of postnatal treatment (inclusive of start and end days).",
  postnatal_unit              = "Time unit for the postnatal treatment fields (days or hours).",
  total_trt_duration          = "Total treatment duration (prenatal + postnatal).",
  total_trt_unit              = "Time unit for total treatment duration.",
  relative_prenatal_start     = "Prenatal treatment start standardised to the prenatal developmental period (proportion of development).",
  relative_prenatal_end       = "Prenatal treatment end standardised to the prenatal developmental period.",
  relative_prenatal_duration  = "Prenatal treatment duration standardised to the prenatal developmental period.",
  relative_postnatal_start    = "Postnatal treatment start standardised to the time from birth/hatch to sexual maturity.",
  relative_postnatal_end      = "Postnatal treatment end standardised to the time from birth/hatch to sexual maturity.",
  relative_postnatal_duration = "Postnatal treatment duration standardised to the time from birth/hatch to sexual maturity.",
  relative_total_duration     = "Total treatment duration standardised to developmental time.",
  prenatal_measure_delay      = "Time from the end of the prenatal treatment to when mitochondrial traits were measured (days).",
  postnatal_measure_delay     = "Time from the end of the postnatal treatment to when mitochondrial traits were measured (days).",
  measure_delay_units         = "Time unit for the measurement-delay fields (days).",
  relative_treatment_delay    = "Measurement delay standardised to developmental time.",
  envirn_type                 = "Type of developmental manipulation (cort, care deprivation, disturbance, nutrition).",
  nutrition_sum               = "For nutrition studies only: whether nutrients were restricted (undernutrition) or in excess (overnutrition); NA otherwise.",
  nutrition_type              = "For nutrition studies only: nutrient manipulated (protein, fat, carbohydrate, or total food); NA otherwise.",
  fasting_period              = "Time animals were fasted before tissue harvest (unknown/NA where not reported).",
  fasting_period_units        = "Unit for the fasting period (hours or days).",
  tissue_sum                  = "Broad biological-matrix category from which the trait was measured (e.g. liver, muscle, brain, plasma/serum, erythrocyte).",
  tissue                      = "Specific tissue or sample used (e.g. tail muscle, a named brain region).",
  mito_preparation            = "Mitochondrial preparation method (homogenate, isolated, permeabilized cells, histochemistry).",
  mito_ambiguity              = "Whether the direction of the mitochondrial measure relative to function was ambiguous (ambiguous / not-ambiguous).",
  mito_efficiency_dir         = "Flag for mitochondrial-efficiency measures whose sign was reversed (1) versus not (0) when aligning effect-size direction.",
  respiration_category        = "Sub-category of respiration measures (basal, leak, total oxphos, ets, mitochondrial efficiency).",
  antioxidant_category        = "Sub-category of antioxidant measures (general, enzymatic, non-enzymatic).",
  oxidative_damage_category   = "Sub-category of oxidative-damage measures (general, lipids, proteins, dna).",
  measurement_category        = "Functional mitochondrial trait category used as a moderator in analyses (antioxidant, metabolic capacity, oxidative damage, oxidative stress, respiration).",
  measure_listed              = "Measurement as named by the original authors (e.g. OXPHOS, Leak, ROM, FCR).",
  descrp_measure              = "Free-text description of the measured variable, with detail from the source.",
  units...57                  = "Units of the measured outcome variable.",
  ref                         = "Location within the source from which the data were extracted (e.g. table2, figure4, data).",
  t1                          = "Treatment (stressor) group label.",
  t2                          = "Control / comparison group label.",
  dose                        = "Treatment dose where applicable (units in the following column).",
  units...63                  = "Units of the treatment dose.",
  mean_t1                     = "Mean of the outcome variable in the treatment group.",
  sd_t1                       = "Standard deviation of the outcome in the treatment group (SE converted to SD where necessary).",
  n_t1                        = "Sample size of the treatment group.",
  mean_t2                     = "Mean of the outcome variable in the control group.",
  sd_t2                       = "Standard deviation of the outcome in the control group (SE converted to SD where necessary).",
  n_t2                        = "Sample size of the control group.",
  sample_depend               = "Identifier grouping rows measured on the SAME sample of animals (rows sharing a value share a sample).",
  CORT_values_available       = "Whether corticosterone/glucocorticoid values were also reported for the manipulation (yes/no).",
  observation                 = "Unique observation (row) identifier, used as the observation-level random effect to estimate residual variance.",
  species_phylo               = "Species name used to match the phylogeny tip labels.",
  species_phylo2              = "Species name used for the (non-phylogenetic) species-level random effect.",
  SMDH                        = "Standardised mean difference assuming heteroscedastic variances (Bonett 2008, 2009), direction-corrected so that positive values indicate higher mitochondrial respiratory function. This is the effect size analysed.",
  v_SMDH                      = "Sampling variance of SMDH."
)

# Order the dictionary to match the data columns and verify completeness.
stopifnot(setequal(names(desc), names(d)))
meta <- tibble(Column = names(d), Description = unname(desc[names(d)]))

about <- tibble(
  Field = c("Title", "Description", "Unit of observation", "Number of effect sizes",
            "Stressor datasets", "Key effect-size columns", "Source code / archive"),
  Value = c(
    "Supporting data for the meta-analysis of developmental stressors on mitochondrial respiratory function",
    "Complete dataset underlying all analyses and figures. Each row is one effect size.",
    "One row = one effect size (standardised mean difference between a treatment and control group).",
    paste0(nrow(d), " effect sizes from ", dplyr::n_distinct(d$study), " studies and ",
           dplyr::n_distinct(d$species_phylo), " species."),
    paste(paste0(names(table(d$stressor_category)), " (k=", as.integer(table(d$stressor_category)), ")"), collapse = "; "),
    "SMDH (effect size) and v_SMDH (its sampling variance); see the metadata sheet for all columns.",
    "GitHub repository accompanying the manuscript (see Data Availability statement)."
  )
)

# ---- write workbook --------------------------------------------------
wb <- createWorkbook()
hdr <- createStyle(textDecoration = "bold")

addWorksheet(wb, "data")
# Write missing values as an explicit "NA" rather than blank cells.
writeData(wb, "data", d, headerStyle = hdr, keepNA = TRUE, na.string = "NA")
freezePane(wb, "data", firstRow = TRUE)
setColWidths(wb, "data", cols = 1:ncol(d), widths = "auto")

addWorksheet(wb, "metadata")
writeData(wb, "metadata", about, headerStyle = hdr)
writeData(wb, "metadata", meta, startRow = nrow(about) + 3, headerStyle = hdr)
setColWidths(wb, "metadata", cols = 1:2, widths = c(28, 120))
freezePane(wb, "metadata", firstActiveRow = nrow(about) + 4)

out <- here::here("output", "SI_dataset_for_submission.xlsx")
saveWorkbook(wb, out, overwrite = TRUE)
cat("Wrote", out, "with sheets:", paste(names(wb), collapse = ", "), "\n")
cat("data:", nrow(d), "rows x", ncol(d), "cols | metadata:", nrow(meta), "column definitions\n")
