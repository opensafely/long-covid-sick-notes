################################################################
# This script:
# - Plots the HR and 95% CI of first fit notes 
#     estimated from models stratified by demographics
#
# Author: Andrea Schaffer
################################################################



library(haven)
library(tidyverse)
library(reshape2)
library(tools)
library(here)
library(fs)
library(RColorBrewer)
library(dplyr)
library(ggplot2)
library(PNWColors)
library(ggpubr)
library(here)

# For running locally
setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/long-covid-sick-notes")


# Function for create factor variables
fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}


##############################################
# Read in data
###############################################

# By age group
split <- read.csv(here::here("released", "cox_model_split_summary_all.csv")) %>%
  mutate(comparator = 
  fct_case_when(
    comparator == "2020_general_2019" ~ "COVID-19 2020 vs\ngeneral population 2019",
    comparator == "general_2020" ~  "COVID-19 2020 vs\ngeneral population 2020",
    comparator == "2021_general_2019" ~  "COVID-19 2021 vs\ngeneral population 2019",
    comparator == "general_2021" ~ "COVID-19 2021 vs\ngeneral population 2021",
    comparator == "2020_pneumonia" ~ "Hospitalised COVID-19 2020 vs\npneumonia 2019",
    comparator == "2021_pneumonia" ~  "Hospitalised COVID-19 2021 vs\npneumonia 2019"
  ),

  # Create variable for hospitalised vs not
    cat = 
      case_when(
        comparator %in% c("Hospitalised COVID-19 2020 vs\npneumonia 2019",
                          "Hospitalised COVID-19 2021 vs\npneumonia 2019") ~ "Hospitalised",
        TRUE ~ "Not hospitalised"),
    
    # Create variable for year
    year = 
      case_when(
        comparator %in% c("COVID-19 2020 vs\ngeneral population 2019",
                        "COVID-19 2020 vs\ngeneral population 2020",
                        "Hospitalised COVID-19 2020 vs\npneumonia 2019") ~ "2020",
        TRUE ~ "2021"),
    
    # Create variable for comparison type (historic vs contemporary)
    comp_type = 
      case_when(
        comparator %in% c("COVID-19 2020 vs\ngeneral population 2019",
                        "COVID-19 2021 vs\ngeneral population 2019") ~
              "COVID-19 cohort vs general population 2019",
        comparator %in% c(
          "Hospitalised COVID-19 2020 vs\npneumonia 2019",
          "Hospitalised COVID-19 2021 vs\npneumonia 2019") ~ 
              "Hospitalised COVID-19 vs pneumonia 2019",
      TRUE ~ "COVID-19 cohort vs contemporary general population"),
  
    month = 
      fct_case_when(
        month == 0 ~ "0-29 days",
        month == 30 ~ "30-89 days",
        month == 90 ~ "90-149 days",
        month == 150 ~ "150+ days"
      )
  )


#############################################
### Visualise results using forest plot
#############################################

# General cohorts, fully adjusted
split %>% 
ggplot(aes(y = hr, x = month, col = comp_type, group =comp_type, shape = comp_type)) +
  geom_errorbar(aes(ymax = uc, ymin = lc), 
                width = 0.05, col="gray50") +
  geom_point(size = 2) +
  geom_hline(aes(yintercept = 1), linetype = "longdash", col = "black") +
  scale_color_manual(values = pnw_palette("Bay", 3)) +
  scale_y_continuous(trans = "log2", breaks = c(.5,1,2,4),
                     limits = c(.5,6.5)) +
 # scale_shape_manual(values = c("circle", "square")) +
  ylab("HR (95% CI)") + xlab("Time since index date") +
  facet_wrap( ~ year, nrow = 2)+
#  coord_flip() +
  theme_bw()+
  theme(text = element_text(size = 9),
        legend.position = "right",
        axis.title.x = element_text(size = 8),
        strip.placement = "outside",
        panel.grid.major.y = element_line(color="gray90"),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.title = element_blank(),
        axis.text.x = element_text(angle= 45, hjust=1),
        strip.background = element_blank())

 
ggsave(here::here("manuscript", "plots", "split.png"),
       dpi= 300, height = 5, width = 6, units = "in")
