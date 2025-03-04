#### --------------------------------------------------  ####
# 1. Data Checking, processing and exploratory analysis
#### --------------------------------------------------  ####

	# Load the required libraries
		source(here("R", "func.R"))
		check_and_install("pacman")
		pacman::p_load(tidyverse, flextable, latex2exp, metafor, orchaRd, readxl, here, ggrepel, patchwork, rotl, ape, phytools, kutils)

	# Load the data
		data <- read_excel(here("data", "mito_meta_data_merged_03032025.xlsx"))

	# Check the data
		str(data)

	# Add observation-level column
		data <- data %>%
			mutate(observation = row_number())

	# Check mean-variance relationship
		control <- ggplot(data, aes(x = log(mean_t1), y = log(sd_t1))) +
			geom_point() +
			geom_smooth(method = "lm", se = TRUE) +
			geom_label_repel(aes(label = study), max.overlaps = 60, box.padding = 0.5, point.padding = 0.5, segment.color = "grey50") +
			labs(title = "Mean-variance relationship of control", x = "log Mean", y = " log Standard Deviation")

		trt <- ggplot(data, aes(x = log(mean_t2), y = log(sd_t2))) +
			geom_point() +
			geom_smooth(method = "lm", se = TRUE) +
			geom_label_repel(aes(label = study), max.overlaps = 60, box.padding = 0.5, point.padding = 0.5, segment.color = "grey50") +
			labs(title = "Mean-variance relationship of treatment", x = "log Mean", y = " log Standard Deviation")

	plot <- (control + my_theme() | trt + my_theme()) + plot_annotation(tag_levels = "A", tag_suffix = ")")
	ggsave(here("output", "fig_explore", "fig_ex1.png"), plot, width = 22.888889, height = 8.604938)

	# Check levels of categorical variables that are of major interest to make sure now spelling errors etc
	unique(data$envirn_type)
	unique(data$measurement_category) # Some issues here with gene expression. Probably just call "gene/protein expression"
	unique(data$tissue_sum) # Some issues here "BAT" == "brown adipose tissue (BAT)" == "bat"; "whole body" == "whole animal"; "whole blood" == "blood"; "skeletal muscle" == "muscle"; what is "wat"? Is that bat?


#### --------------------------------------------------  ####
# 2. Phylogeny
#### --------------------------------------------------  ####
	 
	 # From these data we will create a phylogeny which we can trim based on data subsets. Create species first
	 data <- data %>%
		 mutate(species_phylo = paste(genus, species, sep = "_"),
		 		species_phylo = ifelse(species_phylo == "Meleagris_gallopavo domesitcus", "Meleagris_gallopavo", species_phylo))

	# Few more fixes in data to match species in data and tree
	 data <- data %>%
		 mutate(species_phylo = ifelse(species_phylo == "Trachemys_scripta elegans", "Trachemys_scripta_elegans", 
		 								if_else(species_phylo == "Oncorhynchus_tschawyscha", "Oncorhynchus_tshawytscha", 
										if_else(species_phylo == "Tamiasciurus_hudonicus", "Tamiasciurus_hudsonicus",
										if_else(species_phylo == "Cortunix_japonica", "Coturnix_japonica", 
										if_else(species_phylo == "Symphysodon_aequifasciatus", "Symphysodon_aequifasciata",
										if_else(species_phylo %in% c("Dicentrarachus_labrax", "Dichentrarchus_labrax"), "Dicentrarchus_labrax", species_phylo)))))))

	 # Create a phylogeny. Looks like all species are matched and in the tree
	 tol_subtree  <- rotl::tnrs_match_names(unique(data$species_phylo))

	 # Create a phylogeny
	 tree <- rotl::tol_induced_subtree(tol_subtree$ott_id, label_format = "name")

	 # Check the tree. Some warnings
	 length(unique(data$species_phylo)); length(tree$tip.label) # lost two species, which ones
	
	 # Fix labels so they match the data
	 tree$tip.label <- gsub("_\\([^)]*\\)", "", tree$tip.label)

	 # Check the tree again
		tree_checks(data, tree, dataCol = "species_phylo")
	 
	 # Write final tree
	 write.tree(tree, here("output", "phylo", "phylo.tre"))
	write.table(tree$tip.label, here("output", "phylo", "phylo_species.txt"), row.names = FALSE, col.names = FALSE)

	 # Plot the tree
	 plot_tree <- ape::plot.phylo(tree, cex = 0.5, label.offset = 0.5, show.tip.label = TRUE, edge.width = 1, type = "fan", no.margin = TRUE)
	 ggsave(here("output", "phylo", "phylo.png"), plot_tree, width = 22.888889, height = 8.604938)

	 # Check the tree
	 tree_checks(data, tree, dataCol = "species_phylo")

	 # Prune the tree
	 tree <- tree_checks(data, tree, dataCol = "species_phylo", type = "prune")

	 # Check the tree
	 tree_checks(data, tree, dataCol = "species_phylo")

	 # Write final tree
	 write.tree(tree, here("output", "phylo", "phylo_pruned.tre"))
	 write.table(gsub("_", " ", tree$tip.label), here("output", "phylo", "phylo_pruned_species.txt"), row.names = FALSE, col.names = FALSE)

#### --------------------------------------------------  ####
# 3. Effect size calculations
#### --------------------------------------------------  ####

	## Let's calculate the effect size. We are still a little uncertain on what to use, but for now, lets use standardised mean difference. Note here that the direction is REALLY important. We are creating a SMD where the mean of mean_t2 is subtracted from mean_t1. What this means is that 'positive' effects indicate the the mean of treatment 1 is GREATER than the mean of treatment 2. Same applies to the direction of the overall meta-analytic mean from models. 
		
		data <-  metafor::escalc(measure = "SMDH", m1i = mean_t1, m2i = mean_t2, 
											sd1i = sd_t1, sd2i = sd_t2, 
											n1i = n_t1 , n2i = n_t2, 
						data = data, var.names = c("SMDH", "v_SMDH"))

	# Log Response Ratio is quite intuitive to interpret but can only be used with ratio scale data which will not be useful for some measures.  
		data <-  metafor::escalc(measure = "ROM", m1i = mean_t1, m2i = mean_t2, 
											sd1i = sd_t1, sd2i = sd_t2, 
											n1i = n_t1 , n2i = n_t2, 
						data = data, var.names = c("ROM", "v_ROM"))

#### --------------------------------------------------  ####
# 4. Data subsets
#### --------------------------------------------------  ####

	# Subset the temperature stress data and remove columns that we don't seem to need
	temp_stress <- data %>%
				filter(envirn_type == "temp")  %>% select(!c(Notes, CORT_values_available, CI95_t2, se_t2, CI95_t1, se_t1, num_tissues_types, admin, type, control_multiple_comparisons, measurement_methods))
	sum_temp_stress <- temp_stress  %>% summarise(k = n(), spp = n_distinct(species_phylo), studies = n_distinct(study))

	# Subset the nutrition stress data and remove columns that we don't seem to need
	nutri_stress <- data %>%
				filter(envirn_type == "nutrition")  %>% select(!c(Notes, CORT_values_available, CI95_t2, se_t2, CI95_t1, se_t1, num_tissues_types, admin, type, control_multiple_comparisons, measurement_methods))
	sum_nutri_stress <- nutri_stress  %>% summarise(k = n(), spp = n_distinct(species_phylo), studies = n_distinct(study))

	# Subset the CORT stress data and remove columns that we don't seem to need
	cort_stress <- data %>%
				filter(envirn_type == "cort")  %>% select(!c(Notes, CI95_t2, se_t2, CI95_t1, se_t1, num_tissues_types, admin, type, control_multiple_comparisons, measurement_methods))
	sum_cort_stress <- cort_stress  %>% summarise(k = n(), spp = n_distinct(species_phylo), studies = n_distinct(study))

	# Subset the deprivation stress data and remove columns that we don't seem to need
	deprive_stress <- data %>%
				filter(envirn_type == "care deprivation")  %>% select(!c(Notes, CI95_t2, se_t2, CI95_t1, se_t1, num_tissues_types, admin, type, control_multiple_comparisons, measurement_methods))
	sum_deprive_stress <- deprive_stress  %>% summarise(k = n(), spp = n_distinct(species_phylo), studies = n_distinct(study))

	# Subset the disturbance stress data and remove columns that we don't seem to need
	disturb_stress <- data %>%
				filter(envirn_type == "disturbance")  %>% select(!c(Notes, CI95_t2, se_t2, CI95_t1, se_t1, num_tissues_types, admin, type, control_multiple_comparisons, measurement_methods))
	sum_disturb_stress <- disturb_stress  %>% summarise(k = n(), spp = n_distinct(species_phylo), studies = n_distinct(study))

	# Summary table of all teh data subsets
	summary_table <- rbind(sum_temp_stress, sum_nutri_stress, sum_cort_stress, sum_deprive_stress, sum_disturb_stress)
	summary_table <- summary_table %>% mutate(envirn_type = c("Temperature", "Nutrition", "CORT", "Care Deprivation", "Disturbance"))  %>% select(envirn_type, everything())