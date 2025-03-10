# mito_meta_stress
How developmental stress programs mitochondrial function

## 1. How to use this repository?

Users can download a zip file of the entire repository by clicking on the green `code` tab at the top of the page and then clicking `Download ZIP`. Alternatively, the repo can be downloaded from [Zenodo](). Users who already have a GitHub account can `fork` the repository.

The main file for users to click on when they are first navigating is the :page_facing_up: `mito_meta_stress.Rproj` file which will open the folder and set the working directory to the root of the downloaded folder. This will provide access to the code and data through R. Note that we use `Quarto` to provide a reproducible results where our text, code and figures are integrated together. This allows users to identify what specific objects are being used to render the quantitative information provided in the manuscript (more details below).

## 2. Project Organization and Workflow

The key file in this repository for reproducing the results is the :page_facing_up: `results.qmd` file within the :open_file_folder: `docs` folder. This file can be rendered in `R` with `Quarto` to reproduce the results section and supplement. Code chunks within the file provide the code used to reproduce figures and analyses along with supporting statements within the text. Note that inline code chunks use specific objects which are then rendered.

The :page_facing_up: `results.qmd` file makes use of files within a number of folders that are identified in the code chunks. There are a number of important folders in the repository. 
* :open_file_folder: `data` The `data` folder contains all the raw data used in files.  Note that there are intermediary data files here that were used throughout the processing. There are really only two main files to worry about. For more details see **3. Data** below.
* :open_file_folder: `output/figs/` Folder contains all the figures for the paper that are read and included in the paper. See more details below (**4. Figures**).
* :open_file_folder: `R` The R folder contains three files that are used to clean and process data to prepare it for use in the :page_facing_up: `results.qmd` file. Note that readers do not need to open and run these files, but they are simply here to document the workflow and code used to clean up data to be used. 

## 3. Data

There are two data folders: 1) :open_file_folder: `data` and 2) :open_file_folder: `output/data/`. The `data/` folders contains the raw data, whereas the `output/data/` folder contains the processed data that is used in the `results.qmd` file. 

The processed data is created by running the `R` files in the `R` folder. The processed data is then used in the `results.qmd` file to generate the figures and analyses. These data files all contain the same columns aside form a few processed columns that are added in the processing steps and exported with the data subsets. The columns are as follows:

| Column Name | Description |
------------- | ------------
study	| Unique study identifier
ref	| First author last name
year	| Year the publication was published
class	| Class of organism
family	| Family of organism
genus	| Genus of organism
species	| Binomial species name of organism. 
common_name	| common name of organism
stage	| when conditions were applied during development (i.e., pre or postnatal)
sex	| the sex of the study animals (i.e., male, female, or both)
prenatal_trt_start	| when prenatal treatment was initiated where 0 = conception
prenatal_trt_end	| when prenatal treatment terminates 
prenatal_dur	| the amount of time prenatal treatment was administered, if listed as conception to day 14 the assumption is that the time frame is inclusive and this number would be 15 
prenatal_unit	| unit of time of prental treatment 
post_natal_trt_start	| Day 0 equals day of birth or egg lay. If a treatment starts when nestlings are two days old then this value should be 3 (day 0, 1, and 2)
postnatal_trt_end	| when prenatal treatment terminates 
dur_trt_postnatal	| the amount of time postnatal treatment was administered, if listed as birth to day 14 the assumption is that the time frame is inclusive and this number would be 15 
postnatal_unit	| unit of time of postnatal treatment 
total_trt_duration	| the amount of time all treatments were administered, if prenatal duration = 20 and postnatal = 20 days then this number is 40
total_trt_unit	| unit of time of total treatments 
prenatal_measure_delay	| The time from the end of the prenatal treatment to when the measurements were collected. So, if treatment ends at birth and mito was measured at 100 days following birth this number should be 100
postnatal_measure_delay	| The time from the end of the postnatal treatment to when the measurements were collected. If treatment ends at 15 days and mito was measured at 100 days then this number should be 85
measure_delay_units	| unit of time of delay 
envirn_type	| Type of developmental environment manipulation. Categorical. Categories include: "temp", "nutrition",'brood"
nutrition_sum	| If the developmental manipulation is nutrition, is it overnutrition or undernutrition; if not nutrition then NA
nutrition_type	| If the developmental manipulation is nutrition, was fat, protein, or total food manipulated; if not nutrition then NA
admin	| how the treatment was delivered
fasting_period	| time animals were fasted before tissues were harvested; if listed as 'overnight' 12 hours used; NA indicates the information is not available
fasting_period_unit	| the unit of time animals were fasted before tissues were harvested
num_tissue_types	| the number of tissue types for which we can extract effects sizes; potentially multiple tissues were harvested, but if only one was used to measure mito parameters then this variable is scored as '1'; different sections of tissue count as different tissue types (e.g., different neural regions) 
tissue_sum	| category of tissue type
tissue	| specific type of tissue used (e.g., section of brain)
dir_effect	| direction of effect (positive or negative) of the cause or consequences of high metabolic rate whereas positive values indicate high and negative values indicate low
measure_sum	| broad category of what the mito measurement indicates about mito bioenergetics
measure_listed	| what the authors listed that was measured 
descrp_measure	| description of what was measured with details from author
units	| Units of outcome variable
t1	| Treatment 1 name. This could be temperature, nurtition, control etc
t2	| Treatment 2 name. This could be temperature, nurtition, control etc
trt_units	| Units of the treatment manopulation. If a temperature manipulation then this is in degrees Celcius. If brood size, this woul dbe the change in brood size
mean_t1	| Mean value of treatment 1
sd_t1	| Standard deviation of treatment 1. If provided in standard error convert from SE to SD using SD = sqrt(N)*SE
n_t1	| Sample size in treatment 1. 
se_t1	| standard error in treatment 1, calculated as SD/sqrt(n)
CI95_t1	| confidence interval of mean in treatment 1, se calculated from this as = (mean+upper CI95) - (mean-lower CI95)/3.92 
mean_t2	| Mean value of treatment 2
sd_t2	| Standard deviation of treatment 2. If provided in standard error convert from SE to SD using SD = sqrt(N)*SE
n_t2	| Sample size in treatment 2. 
se_t2	| standard error in treatment 2, calculated as SD/sqrt(n)
CI95_t2	| confidence interval of mean in treatment 2, se calculated from this as = (mean+upper CI95) - (mean-lower CI95)/3.92 
sample_dependent	| A classifier that identified if different rows in the dataset are traits measured on the SAME SAMPLE of animals. If the same sample then they share the same number
type	| classification of means, e.g., raw or least squares
CORT_values_available	| yes' if there are data on CORT levels in response to a manipulation. For example, if a study chased fish as a disturbance and measure the effect of this treatment on CORT in addition to mito parameters then this is a 'yes;' if there are no CORT values = "NA"
notes	| anything that may be important