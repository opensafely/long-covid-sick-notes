################################################################
# This script:
# - Plots the percentage of people with diangoses in each 
#   category by cohort
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


### Read in data ### 

diag <- read_csv("C:/Users/aschaffer/OneDrive - Nexus365/Documents/Released outputs/long-covid-sick-notes/output/diag_by_cohort.csv") %>%
  mutate(pcent = as.numeric(ifelse(pcent == "[REDACTED]", NA, pcent)),
         lci = as.numeric(ifelse(lci == "[REDACTED]", NA, lci)),
         uci = as.numeric(ifelse(uci == "[REDACTED]", NA, uci)))


### Set labels ###

diag$diagnosis <- factor(diag$diagnosis, 
                         levels = c("None","Infectious Disease",
                                    "Respiratory Disorder","Mental Disorder",
                                    "Digestive Disorder",
                                    "Trauma","Musculoskeletal Disorder",
                                    "Cardio Disorder","Nervous Disorder",
                                    "Connective Tissue","Genitourinary Disorder",
                                    "Auditory Disorder","Skin Disorder",
                                    "Metabolic Disease","Endocrine Disorder",
                                    "Hematopoietic Disorder","Central Nervous System",
                                    "Visual Disorder","Neoplastic Disease",
                                    "Bloodcell Disorder","Pregnancy Complication",
                                    "Nutritional Disorder","Immune Disorder",
                                    "Poisoning","Congenital Disease",
                                    "Puerperium Disorder",
                                    "Labor Delivery Disorder",
                                    "Fetus Newborn Disorder"),
                         labels = c("None","Infectious Disease",
                                    "Respiratory","Mental Health",
                                    "Digestive",
                                    "Trauma","Musculoskeletal",
                                    "Cardiovascular","Nervous System",
                                    "Connective Tissue","Genitourinary",
                                    "Auditory","Skin",
                                    "Metabolic Disease","Endocrine",
                                    "Hematopoietic","Central Nervous System",
                                    "Visual","Neoplastic Disease",
                                    "Bloodcell","Pregnancy Complication",
                                    "Nutritional","Immune",
                                    "Poisoning","Congenital Disease",
                                    "Puerperium",
                                    "Labor Delivery",
                                    "Fetus Newborn"))

diag$cohort <- factor(diag$cohort, 
                      levels = c("COVID-19 2020","COVID-19 2021",
                                   "General population 2019",
                                   "General population 2020",
                                   "General population 2021",
                                   "COVID-19 hospitalised 2020",
                                   "COVID-19 hospitalised 2021",
                                   "Pneumonia 2019"),
                      labels = c("COVID-19 2020","COVID-19 2021",
                                  "General population 2019",
                                  "General population 2020",
                                  "General population 2021",
                                  "COVID-19 hospitalised 2020",
                                  "COVID-19 hospitalised 2021",
                                  "Pneumonia hospitalised 2019"))


### Bar chart to visualise results ####

ggplot(# Exclude diagnoses with very small counts
    subset(diag, !(diagnosis %in% c("None","Fetus Newborn","Puerperium",
                                 "Poisoning","Labor Delivery","Congenital Disease",
                                 "Nutritional","Visual","Pregnancy Complication",
                                 "Bloodcell","Immune","Auditory","Hematopoietic",
                                 "Metabolic Disease","Endocrine","Central Nervous System",
                                 "Genitourinary"))),
              aes(x = cohort)
  ) +
  
  # Bar chart with error bars
  geom_bar(aes(y = pcent, fill = cohort), stat = "identity") + 
  geom_errorbar(aes(ymin = lci, ymax = uci), width = 0.2, col = "gray50") +
  
  # Add asterisk to indicate redacted values
  geom_point(data = subset(diag, diagnosis == "Connective Tissue" & is.na(pcent)),
             aes(x = cohort, y = .1), shape = "*", size = 5, col = "gray30", show.legend = FALSE) +
  
  scale_fill_manual(values = brewer.pal(8, "Spectral")) +
  ylab("Percentage (%)") + xlab(NULL) +
  facet_wrap(~ diagnosis, scales = "free_y", ncol = 4) + 
  theme(axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(),
        legend.title = element_blank(),
        panel.background = element_rect(fill = "gray95"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        strip.background = element_blank(),
        text = element_text(size = 9))

# Save
ggsave("C:/Users/aschaffer/OneDrive - Nexus365/Documents/Released outputs/long-covid-sick-notes/Graphs/figure2.png", dpi = 300,
       height = 5.5, width = 10)