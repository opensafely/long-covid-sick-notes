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


# For running locally
setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/Released outputs/long-covid-sick-notes/")


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
age <- read.csv(here::here("output", "cox_model_summary_age_group.csv")) %>%
  mutate(category = 
          fct_case_when(
              category == 1 ~ "18-24 y",
              category == 2 ~ "25-34 y",
              category == 3 ~ "35-44 y",
              category == 4 ~ "45-54 y",
              category == 5 ~ "55-64 y"))

# By region (9)
region <- read.csv(here::here("output", "cox_model_summary_region_9.csv")) %>%
  mutate(category = 
           fct_case_when(
              category == 1 ~ "East Midlands",
              category == 2 ~ "East",
              category == 3 ~ "London",
              category == 4 ~ "North East",
              category == 5 ~ "North West",    
              category == 6 ~ "South East",
              category == 7 ~ "South West",
              category == 8 ~ "West Midlands",
              category == 9 ~ "Yorkshire & The Humber"))

# By ethnicity (6 categories)
ethnicity <- read.csv(here::here("output", "cox_model_summary_ethnicity.csv")) %>%
  mutate(category = 
           fct_case_when(
              category == 1 ~ "White",
              category == 3 ~ "Asian or Asian British",
              category == 4 ~ "Black",
              category == 2 ~ "Mixed",
              category == 5 ~ "Other",    
              category == 6 ~ "Unknown"))

# By sex
sex <-  read.csv(here::here("output", "cox_model_summary_male.csv")) %>%
  mutate(category = 
           fct_case_when(
              category == 0 ~ "Female",
              category == 1 ~ "Male")) 

# By IMD quintile
imd <- read.csv(here::here("output", "cox_model_summary_imd.csv")) %>%
  mutate(category = 
           fct_case_when(
              category == 1 ~ "1 (most deprived)",
              category == 2 ~ "2",
              category == 3 ~ "3",
              category == 4 ~ "4",
              category == 5 ~ "5 (least deprived)"))


##########################################################
# Combine into one file and create necessary variables
##########################################################

all <- rbind(age, ethnicity, region, imd, sex) %>%
  mutate(
    
    # Relabel comparator 
    comparator = 
      fct_case_when(
        comparator == "2020_general_2019" ~ "COVID-19 2020 vs\ngeneral population 2019",
        comparator == "general_2020" ~  "COVID-19 2020 vs\ngeneral population 2020",
        comparator == "2021_general_2019" ~  "COVID-19 2021 vs\ngeneral population 2019",
        comparator == "general_2021" ~ "COVID-19 2021 vs\ngeneral population 2021",
        comparator == "2020_pneumonia" ~ "Hospitalised COVID-19 2020 vs\npneumonia 2019",
        comparator == "2021_pneumonia" ~  "Hospitalised COVID-19 2021 vs\npneumonia 2019"
      ),
    
    # Relabel variable names
    var = 
      fct_case_when(
        var == "age_group" ~ "Age group",
        var == "male" ~ "Sex",
        var == "ethnicity" ~ "Ethnicity",
        var == "imd" ~ "IMD quintile",
        var == "region_9" ~ "Region"
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
                        "COVID-19 2021 vs\ngeneral population 2019",
                        "Hospitalised COVID-19 2020 vs\npneumonia 2019",
                        "Hospitalised COVID-19 2021 vs\npneumonia 2019") ~
              "COVID-19 cohort vs\n general population 2019",
        comparator %in% c(
          "Hospitalised COVID-19 2020 vs\npneumonia 2019",
          "Hospitalised COVID-19 2021 vs\npneumonia 2019") ~ 
              "Hospitalised COVID-19 vs pneumonia 2019",
      TRUE ~ "COVID-19 cohort vs\n contemporary general population")
  )

# Set category order for plotting
all$category <- factor(all$category, levels = c("55-64 y","45-54 y","35-44 y","25-34 y","18-24 y",
                                                "Female","Male",
                                                "Unknown","Other","Mixed","Black","Asian or Asian British",
                                                "White","5 (least deprived)","4","3","2","1 (most deprived)",
                                                "Yorkshire & The Humber",
                                                "West Midlands","South West","South East",
                                                "North West","North East","London","East Midlands",
                                                "East"))


#############################################
### Visualise results using forest plot
#############################################

# General cohorts, fully adjusted
all %>% subset(cat == "Not hospitalised" & adjustment != "crude") %>%
ggplot(aes(x = hr, y = category, col = year, group = year, shape = year)) +
  geom_errorbar(aes(xmax = uc, xmin = lc), 
                position = position_dodge(width = .6), 
                width = 0.5, col="gray50") +
  geom_point(position = position_dodge(width = .6)) +
  geom_vline(aes(xintercept = 1), linetype = "longdash", col = "black") +
  scale_color_manual(values = pnw_palette("Bay", 2)) +
  scale_shape_manual(values = c("circle", "square")) +
  xlab("HR (95% CI)") + ylab(NULL) +
  facet_grid(var ~ comp_type, scales = "free_y", space = "free",switch= "y")+
  theme_bw()+
  theme(text = element_text(size = 9),
        legend.position = "right",
        legend.title = element_text(size = 8),
        axis.title.x = element_text(size = 8),
        strip.placement = "outside",
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_line(color="gray90"),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_text(angle= 45, hjust=1),
        strip.background = element_blank()) +
   guides(col = guide_legend(title = "COVID-19 cohort"),
          shape = guide_legend(title = "COVID-19 cohort"))
 
ggsave(here::here("Graphs", "figure1.png"),
       dpi= 300, height = 6, width = 6.5, units = "in")

 
# Hospitalised cohorts
all %>% 
  subset(cat == "Hospitalised" & adjustment != "crude") %>%
  mutate(comp_type = "") %>%
ggplot(aes(x = hr, y = category, col = year, group = year, shape = year)) +
  geom_errorbar(aes(xmax = uc, xmin = lc), 
                position = position_dodge(width = .6), 
                width = 0.5, col="gray50") +
  geom_point(position = position_dodge(width = .6)) +
  geom_vline(aes(xintercept = 1), linetype = "longdash", col = "black") +
  scale_x_continuous(trans = "log2", breaks = c(0.5, 0.75, 1, 1.5), 
                     limits = c(0.35, 1.51)) +
  scale_color_manual(values = pnw_palette("Bay", 2)) +
  scale_shape_manual(values = c("circle", "square")) +
  xlab("HR (95% CI)") + ylab(NULL) +
  facet_grid(var ~ comp_type, scales = "free_y", space = "free",switch= "y")+
  theme_bw()+
  theme(text = element_text(size = 9),
        legend.position = "right",
        legend.title = element_text(size = 8),
        axis.title.x = element_text(size = 8),
        strip.placement = "outside",
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_line(color="gray90"),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_text(angle= 45, hjust=1),
        strip.background = element_blank()) +
  guides(col = guide_legend(title = "COVID-19 cohort"),
         shape = guide_legend(title = "COVID-19 cohort"))

ggsave(here::here("Graphs", "supp_figure1.png"),
       dpi= 300, height = 6, width = 5, units = "in")