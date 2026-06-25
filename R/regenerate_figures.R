# =====================================================================
# Regenerate manuscript figures with editor-requested revisions
#   - Panel labels A, B, C, D (not a), b), c), d))
#   - p-values never displayed as "p = 0" (use format_p(): "< 0.001",
#     three decimals when rounding to 0.00, otherwise two decimals)
#   - Consistent class / stage colours across all panels (Figs 6 & 7)
# Mirrors the figure chunks in docs/results.qmd. Loads cached models, so
# nothing is refitted. Run: Rscript R/regenerate_figures.R
# =====================================================================

source(here::here("R", "func.R"))
suppressMessages(pacman::p_load(tidyverse, metafor, orchaRd, latex2exp, here,
                                patchwork, magick, rphylopic, ggimage, ggplot2, plyr))

here    <- here::here       # avoid masking by other packages (e.g. plyr/lubridate)
summarise <- dplyr::summarise
mutate    <- dplyr::mutate
options(digits = 2)

# Compatibility shim: rphylopic (<= 1.5.0) GeomPhylopic$use_defaults predates the
# ggplot2 >= 4.0 use_defaults(default_aes, theme) signature, which otherwise errors
# when add_phylopic() layers are drawn. Restore the original behaviour with the new
# argument list. Remove once rphylopic is updated for ggplot2 4.0.
if (utils::packageVersion("ggplot2") >= "4.0.0") {
  GP <- getFromNamespace("GeomPhylopic", "rphylopic")
  GP$use_defaults <- function(self, data, params = list(), modifiers = ggplot2::aes(),
                              default_aes = NULL, theme = NULL, ...) {
    col_fill <- c("colour", "fill") %in% colnames(data) | c("colour", "fill") %in% names(params)
    data <- ggplot2::ggproto_parent(ggplot2::Geom, self)$use_defaults(data, params, modifiers, default_aes, theme)
    if (col_fill[1] && !col_fill[2]) { data$fill <- data$colour; data$colour <- NA }
    data
  }
}

# ---- helpers / palettes (identical to docs/results.qmd) --------------
format_p <- function(p){
  vapply(p, function(x){
    if (is.na(x)) return(NA_character_)
    if (x < 0.001) return("< 0.001")
    if (round(x, 2) == 0) return(paste0("= ", formatC(x, format = "f", digits = 3)))
    paste0("= ", formatC(x, format = "f", digits = 2))
  }, character(1))
}
class_cols <- c("Actinopterygii" = "#88CCEE", "Aves" = "#CC6677",
                "Mammalia"       = "#DDCC77", "Amphibia" = "#117733")
stage_cols <- c("Postnatal" = "#88CCEE", "Prenatal" = "#CC6677", "Both" = "#DDCC77")

# ---- data (identical to loadpacks chunk) -----------------------------
path  <- here("output", "data")
files <- list.files(here("output", "data"))
data_lists <- lapply(paste0(path, "/", files), function(x) read.csv(x))
names(data_lists) <- files
data_lists <- lapply(data_lists, function(x) mutate(x, depend = interaction(sample_depend, study)))
data_lists <- lapply(data_lists, function(x) x %>%
  mutate(inv_n = (n_t1 + n_t2) / (n_t1 * n_t2),
         sqrt_inv_n = sqrt(inv_n),
         ef_n = (4 * n_t1 * n_t2) / (n_t1 + n_t2)))
data <- plyr::ldply(data_lists)
nutri_data <- data_lists[[4]]

# ---- models ----------------------------------------------------------
m <- function(f) readRDS(here("output", "models", f))
MLMA_list               <- m("MLMA_list.rds")
MLMR_list_Measure       <- m("MLMR_list_Measure.rds")
MLMR_list_Measure_noint <- m("MLMR_list_Measure_noint.rds")
MLMR_list_preprost      <- m("MLMR_list_preprost.rds")
MLMR_list_preprost_noint<- m("MLMR_list_preprost_noint.rds")
MLMR_list_taxa          <- m("MLMR_list_taxa.rds")
MLMR_list_taxa_noint    <- m("MLMR_list_taxa_noint.rds")
delay_list              <- m("delay_list.rds")
nutri_type              <- m("nutri_type.rds")
nutri_up_down           <- m("nutri_up_down.rds")

# =====================================================================
# Figure 4 - overall estimates per stressor
# =====================================================================
table <- lapply(data_lists, function(x) x %>% summarise(studies = n_distinct(study), spp = n_distinct(species_phylo), k = n()))
z <- list(data.frame(x = 1.2, y = 5), data.frame(x = 1.2, y = 5),
          data.frame(x = 1.2, y = 5), data.frame(x = 1.2, y = 5))
p_mlma <- sapply(MLMA_list, function(x) coef(summary(x))$pval)
plots <- mapply(function(x, y, z, p)
  orchard_plot(x, xlab = TeX("$SMD_{H}$"), group = "study", trunk.size = 1.2, branch.size = 2, k = FALSE, g = FALSE) +
    ylim(-8, 8) + scale_x_discrete(labels = "Overall") +
    theme_classic() + theme(legend.position = "top", axis.title = element_text(size = 18),
      plot.title = element_text(face = "bold", size = 16), axis.text = element_text(size = 12),
      plot.tag = element_text(size = 24)) +
    scale_color_manual(values = "black") + scale_fill_manual(values = "gray") +
    annotate("text", x = c(z$x), y = c(z$y), label = TeX(paste0("\\textit{k} = ", y$k, " (", y$studies, ")")), size = 5, hjust = 0) +
    annotate("text", x = c(z$x), y = c(z$y)-12, label = TeX(paste0("\\textit{p} ", format_p(p))), size = 5, hjust = 0),
  x = MLMA_list, y = table, z = z, p = p_mlma, SIMPLIFY = FALSE)
p_overall <- (plots[[1]] + ggtitle("Glucocorticoids") + plots[[2]] + ggtitle("Parental Care Deprivation")) /
             (plots[[3]] + ggtitle("Psychological Disturbance") + plots[[4]] + ggtitle("Nutritional imbalance")) +
             plot_annotation(tag_levels = "A")
ggsave(here("output", "figures", "fig4.png"), p_overall, width = 12.815686, height = 8.282353)
message("fig4 done")

# =====================================================================
# Figure 5 - functional trait category per stressor
# =====================================================================
measure_table <- lapply(data_lists, function(x) x %>% group_by(measurement_category) %>%
  summarise(studies = n_distinct(study), spp = n_distinct(species_phylo), k = n()))
z <- list(data.frame(x = c(1.2,2.2,3.2,4.2,5.2), y = rep(4,5)),
          data.frame(x = c(1.2,2.2,3.2,4.2),     y = rep(4,4)),
          data.frame(x = c(1.2,2.2,3.2,4.2),     y = rep(4,4)),
          data.frame(x = c(1.2,2.2,3.2,4.2,5.2), y = rep(4,5)))
p_measure_p <- lapply(MLMR_list_Measure_noint, function(x) x$pval)
plots <- mapply(function(x, y, z, p) orchard_plot(x, mod = "measurement_category", xlab = TeX("$SMD_{H}$"),
    group = "study", trunk.size = 1.2, branch.size = 2, k = FALSE, g = FALSE) + ylim(-8,8) +
    theme_classic() + theme(legend.position = "top", axis.title = element_text(size = 18),
      plot.title = element_text(face = "bold", size = 16), axis.text = element_text(size = 12),
      plot.tag = element_text(size = 24)) +
    annotate("text", x = c(z$x), y = c(z$y), label = TeX(paste0("\\textit{k} = ", y$k, " (", y$studies, ")")), size = 5, hjust = 0) +
    annotate("text", x = c(z$x), y = c(z$y)-12, label = TeX(paste0("\\textit{p} ", format_p(p))), size = 5, hjust = 0),
  x = MLMR_list_Measure, y = measure_table, z = z, p = p_measure_p, SIMPLIFY = FALSE)
p_measure <- (plots[[1]] + ggtitle("Glucocorticoids") + plots[[2]] + ggtitle("Parental care deprivation")) /
             (plots[[3]] + ggtitle("Psychological disturbance") + plots[[4]] + ggtitle("Nutritional imbalance")) +
             plot_annotation(tag_levels = "A")
ggsave(here("output", "figures", "fig5.png"), p_measure, width = 14.74510, height = 10.37647)
message("fig5 done")

# =====================================================================
# Figure 6 - taxonomic class per stressor (consistent class colours)
# =====================================================================
uuid_mammal <- get_uuid(name = "Mus_musculus");          mammal <- get_phylopic(uuid = uuid_mammal)
uuid_bird   <- get_uuid(name = "Taeniopygia_guttata");   bird   <- get_phylopic(uuid = uuid_bird)
uuid_amphib <- get_uuid(name = "Triturus");              amphib <- get_phylopic(uuid = uuid_amphib)
uuid_fish   <- get_uuid(name = "Dicentrarchus_labrax");  fish   <- get_phylopic(uuid = uuid_fish)

taxa_table <- lapply(data_lists, function(x) x %>% group_by(class) %>%
  summarise(studies = n_distinct(study), spp = n_distinct(species_phylo), k = n()))
z <- list(data.frame(x = c(1.2,2.2,3.2), y = rep(4,3)),
          data.frame(x = c(1.2,2.2,3.2), y = rep(4,3)),
          data.frame(x = c(1.2,2.2,3.2,4.2), y = rep(4,4)))
w <- list(data.frame(x = c(1.2,2.2,3.2)-0.5, y = rep(4,3)),
          data.frame(x = c(1.2,2.2,3.2)-0.5, y = rep(4,3)),
          data.frame(x = c(1.2,2.2,3.2,4.2)-0.5, y = rep(4,4)))
p_taxa_p <- lapply(MLMR_list_taxa_noint[c(1,3,4)], function(x) x$pval)
plots <- mapply(function(x, y, z, w, p) {orchard_plot(x, mod = "class", xlab = TeX("$SMD_{H}$"),
    group = "study", trunk.size = 1.2, branch.size = 2, g = FALSE, k = FALSE) + ylim(-8,8) +
    scale_fill_manual(values = class_cols) + scale_colour_manual(values = class_cols) +
    theme_classic() + theme(legend.position = "top", axis.title = element_text(size = 18),
      plot.title = element_text(face = "bold", size = 16), axis.text = element_text(size = 12),
      plot.tag = element_text(size = 24)) +
    annotate("text", x = c(z$x), y = c(z$y), label = TeX(paste0("\\textit{k} = ", y$k, " (", y$studies, ")")), size = 5, hjust = 0) +
    annotate("text", x = c(w$x), y = c(w$y), label = TeX(paste0("\\textit{p} ", format_p(p))), size = 5, hjust = 0)},
  x = MLMR_list_taxa[c(1,3,4)], y = taxa_table[c(1,3,4)], z = z, w = w, p = p_taxa_p, SIMPLIFY = FALSE)
ann1 <- function() list(add_phylopic(img = mammal, x = 3.3, y = -5, height = 0.45),
                        add_phylopic(img = bird,   x = 2.3, y = -5, height = 0.45),
                        add_phylopic(img = fish,   x = 1.3, y = -5, height = 0.35))
ann2 <- function() list(add_phylopic(img = mammal, x = 4.3, y = -5, height = 0.45),
                        add_phylopic(img = bird,   x = 3.3, y = -5, height = 0.45),
                        add_phylopic(img = amphib, x = 2.3, y = -5, height = 0.35),
                        add_phylopic(img = fish,   x = 1.3, y = -5, height = 0.35))
p_taxa <- (plots[[1]] + ann1() + ggtitle("Glucocorticoids") + plots[[2]] + ann1() + ggtitle("Psychological disturbance") +
           plots[[3]] + ann2() + ggtitle("Nutritional imbalance")) + plot_annotation(tag_levels = "A")
ggsave(here("output", "figures", "fig6.png"), p_taxa, width = 16.854902, height = 6.078431)
message("fig6 done")

# =====================================================================
# Figure 7 - stage of manipulation per stressor (consistent stage colours)
# =====================================================================
prepost_table <- lapply(data_lists, function(x) x %>% group_by(stage) %>%
  summarise(studies = n_distinct(study), spp = n_distinct(species_phylo), k = n()))
z <- list(data.frame(x = c(1.2,2.2), y = rep(4,2)),
          data.frame(x = c(1.2,2.2), y = rep(4,2)),
          data.frame(x = c(1.2,2.2,3.2), y = rep(4,3)))
w <- list(data.frame(x = c(1.2,2.2), y = rep(4,2)-12),
          data.frame(x = c(1.2,2.2), y = rep(4,2)-12),
          data.frame(x = c(1.2,2.2,3.2), y = rep(4,3)-12))
p_prepost_p <- lapply(MLMR_list_preprost_noint[c(1,3,4)], function(x) x$pval)
plots <- mapply(function(x, y, z, w, p) {orchard_plot(x, mod = "stage", xlab = TeX("$SMD_{H}$"),
    group = "study", trunk.size = 1.2, branch.size = 2, k = FALSE, g = FALSE, weights = "prop") + ylim(-8,8) +
    scale_fill_manual(values = stage_cols) + scale_colour_manual(values = stage_cols) +
    theme_classic() + theme(legend.position = "top", axis.title = element_text(size = 18),
      plot.title = element_text(face = "bold", size = 16), axis.text = element_text(size = 12),
      plot.tag = element_text(size = 24)) +
    annotate("text", x = c(z$x), y = c(z$y), label = TeX(paste0("\\textit{k} = ", y$k, " (", y$studies, ")")), size = 5, hjust = 0) +
    annotate("text", x = c(w$x), y = c(w$y), label = TeX(paste0("\\textit{p} ", format_p(p))), size = 5, hjust = 0)},
  x = MLMR_list_preprost[c(1,3,4)], y = prepost_table[c(1,3,4)], z = z, w = w, p = p_prepost_p, SIMPLIFY = FALSE)
p_prepost <- (plots[[1]] + ggtitle("Glucocorticoids") + plots[[2]] + ggtitle("Psychological disturbance") +
              plots[[3]] + ggtitle("Nutritional imbalance")) + plot_annotation(tag_levels = "A")
ggsave(here("output", "figures", "fig7.png"), p_prepost, width = 16.572549, height = 5.968627)
message("fig7 done")

# =====================================================================
# Delay bubble plots (supplementary)
# =====================================================================
plots <- lapply(delay_list, function(x) bubble_plot(x, mod = "delay", ylab = TeX("$SMD_{H}$"),
    xlab = "Measurement Delay (days)", group = "study") +
    theme_classic() + theme(legend.position = "top", axis.title = element_text(size = 18),
      plot.title = element_text(face = "bold", size = 16), axis.text = element_text(size = 12),
      plot.tag = element_text(size = 24)))
delay <- (plots[[1]] + ggtitle("Glucocorticoids") + plots[[2]] + ggtitle("Parental care deprivation") +
          plots[[3]] + ggtitle("Psychological disturbance") + plots[[4]] + ggtitle("Nutrition")) +
          plot_annotation(tag_levels = "A")
ggsave(here("output", "figures", "fig_delay.png"), delay, width = 8.703704, height = 8.679012)
message("fig_delay done")

# =====================================================================
# Figure 8 - nutrition: under/over and nutrition type
# =====================================================================
nutri_table  <- nutri_data %>% group_by(nutrition_type) %>% summarise(studies = n_distinct(study), spp = n_distinct(species_phylo), k = n())
nutri_table2 <- nutri_data %>% group_by(nutrition_sum)  %>% summarise(studies = n_distinct(study), spp = n_distinct(species_phylo), k = n())
p_nutri  <- nutri_type$pval
p_nutri2 <- nutri_up_down$pval
p_up_down <- orchard_plot(nutri_up_down, mod = "nutrition_sum", xlab = TeX("$SMD_{H}$"), group = "study",
    trunk.size = 1.2, branch.size = 2, k = FALSE, g = FALSE) + ylim(-8,8) + theme_classic() +
  theme(legend.position = "top", axis.title = element_text(size = 18), plot.title = element_text(face = "bold", size = 16),
    axis.text = element_text(size = 12), plot.tag = element_text(size = 24)) +
  annotate("text", y = c(rep(5,2)),    x = c(1.20,2.20), label = TeX(paste0("\\textit{k} = ", nutri_table2$k, " (", nutri_table2$studies, ")")), size = 5, hjust = 0) +
  annotate("text", y = c(rep(5,2))-12, x = c(1.20,2.20), label = TeX(paste0("\\textit{p} ", format_p(p_nutri2))), size = 5, hjust = 0)
p_type <- orchard_plot(nutri_type, mod = "nutrition_type", xlab = TeX("$SMD_{H}$"), group = "study",
    trunk.size = 1.2, branch.size = 2, k = FALSE, g = FALSE) + ylim(-8,8) + theme_classic() +
  theme(legend.position = "top", axis.title = element_text(size = 18), plot.title = element_text(face = "bold", size = 16),
    axis.text = element_text(size = 12), plot.tag = element_text(size = 24)) +
  annotate("text", y = c(rep(5,4)),    x = c(1.20,2.20,3.20,4.20), label = TeX(paste0("\\textit{k} = ", nutri_table$k, " (", nutri_table$studies, ")")), size = 5, hjust = 0) +
  annotate("text", y = c(rep(5,4))-12, x = c(1.20,2.20,3.20,4.20), label = TeX(paste0("\\textit{p} ", format_p(p_nutri))), size = 5, hjust = 0)
p_nutr <- p_up_down + p_type + plot_annotation(title = "Nutritional imbalance", tag_levels = "A",
    theme = theme(plot.title = element_text(face = "bold", size = 20), plot.tag = element_text(size = 24)))
ggsave(here("output", "figures", "fig8.png"), p_nutr, width = 14.031372, height = 6.345098)
message("fig8 done")

# =====================================================================
# Figure S1 - funnel plots
# =====================================================================
plots <- lapply(data_lists, function(x) ggplot(x, aes(x = SMDH, y = 1/sqrt(v_SMDH))) + geom_point() +
  labs(x = TeX("$SMD_{H}$"), y = "Precision (1 / SE)") + theme_classic() +
  theme(axis.title = element_text(size = 18), plot.title = element_text(face = "bold", size = 16),
    axis.text = element_text(size = 12), plot.tag = element_text(size = 24)) +
  geom_vline(xintercept = 0, linetype = "dashed"))
# plots[[1:4]] follow data_lists order: cort, deprive (parental care), disturb, nutri.
funnels <- plots[[1]] + ggtitle("Glucocorticoids") + plots[[2]] + ggtitle("Parental care deprivation") +
  plots[[3]] + ggtitle("Psychological disturbance") + plots[[4]] + ggtitle("Nutritional imbalance") + plot_annotation(tag_levels = "A")
ggsave(here("output", "figures", "fig_funnel.png"), funnels, width = 7.756863, height = 6.415686)
message("fig_funnel done")

message("All figures regenerated.")
