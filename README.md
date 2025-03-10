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
Effect_Size_ID	| Unique identifiers for individual effect sizes.