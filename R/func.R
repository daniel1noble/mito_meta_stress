#### -------------------------------------------- ####
#             Functions for analysis
#### -------------------------------------------- ####

# Function to check and install a package
# pkg: package name
check_and_install <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  } else {
    message(paste(pkg, "is already installed."))
  }
}

# Plot themes
my_theme  <- function() {
		list(theme_classic(),
			 theme(axis.text.x = element_text(size = 12),
				   axis.text.y = element_text(size = 12),
				  axis.title.x = element_text(size = 16),
				  axis.title.y = element_text(size = 16),
				      plot.tag = element_text(size = 20)))
	}
