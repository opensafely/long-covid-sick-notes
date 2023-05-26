################################################################
# This script:
# - Plots the crude rates of first fit notes by demographics
#     and year
#
# Author: Andrea Schaffer
################################################################


setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/Released outputs/long-covid-sick-notes/output")

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


### Read in data and calculate 95%CIs

calc_rates <- function(dat){
  read_csv(here::here(dat)) %>%
    mutate(lc = rate - 1.96 * sqrt( (rate * (1 - rate)) / personTime),
           uc = rate + 1.96 * sqrt( (rate * (1 - rate)) / personTime),
           
           lc_ppm = 100 * (lc * 365.25 / 12),
           uc_ppm = 100 * (uc * 365.25 / 12)) 
}

gen20 <-  calc_rates("rates_summary_matched_2020.csv")
gen19 <- calc_rates("rates_summary_matched_2019.csv")
gen21 <- calc_rates("rates_summary_matched_2021.csv")
cov20 <-  calc_rates("rates_summary_covid_2020.csv")
cov21 <- calc_rates("rates_summary_covid_2021.csv")
covh21 <- calc_rates("rates_summary_hosp_covid_2021.csv") %>%
  mutate(group = "covid_hosp_2021")
covh20 <- calc_rates("rates_summary_hosp_covid_2020.csv") %>%
  mutate(group = "covid_hosp_2020")
pneumo19 <- calc_rates("rates_summary_hosp_pneumonia_2019.csv")
   
                 
### Combine all cohorts
all <- rbind(cov20,cov21,gen20,gen19,gen21,covh21,covh20,pneumo19) %>%
  subset(variable %in% c("age_group","male","ethnicity","region_9","imd")) %>%
  select(group, rate_ppm, lc_ppm, uc_ppm, variable, category)


### Set labels
all$group <- factor(all$group, levels = c("covid_2020","covid_2021","matched_2019","matched_2020","matched_2021",
                                          "covid_hosp_2020","covid_hosp_2021","pneumonia_2019"),
                         labels = c("COVID-19 2020","COVID-19 2021","General population 2019",
                                    "General population 2020","General population 2021",
                                    "Hospitalised COVID-19 2020","Hospitalised COVID-19 2021",
                                    "Hospitalised pneumonia 2019"))

all$variable <- factor(all$variable, levels = c("age_group","male","ethnicity","imd","region_9"),
                       labels = c("Age group","Sex","Ethnicity","IMD quintile","Region"))

all$category <- factor(all$category, levels = c("55-64 y","45-54 y","35-44 y","25-34 y","18-24 y",
                                                "Female","Male",
                                                "Unknown","Other","Mixed","Black","Asian or Asian British",
                                                "White","5 (least deprived)","4","3","2","1 (most deprived)",
                                                "Yorkshire and The Humber",
                                                "West Midlands","South West","South East",
                                                "North West","North East","London","East Midlands",
                                                "East"),
                       labels = c("55-64 y","45-54 y","35-44 y","25-34 y","18-24 y",
                                  "Female","Male",
                                  "Not stated","Other","Mixed","Black","Asian or British Asian",
                                  "White","5 (least deprived)","4","3","2","1 (most deprived)",
                                  "Yorkshire and\nThe Humber",
                                  "West Midlands","South West","South East",
                                  "North West","North East","London","East Midlands",
                                  "East"))


# Create variable for grouping (general vs hospitalised) and year 
all <- all %>% mutate(cat = 
                        case_when(
                          group %in% c("COVID-19 2020","COVID-19 2021") ~ "COVID-19 cohorts",
                          group %in% c("Hospitalised COVID-19 2020","Hospitalised COVID-19 2021") ~ "Hospitalised COVID-19 cohorts",
                          group %in% c("Hospitalised pneumonia 2019") ~ "Hospitalised pneumonia cohort",
                          TRUE ~ "General population cohorts"),
                      year = 
                        case_when(
                          group %in% c("COVID-19 2020","General population 2020","Hospitalised COVID-19 2020") ~ "2020",
                          group %in% c("General population 2019","Hospitalised pneumonia 2019") ~ "2019",
                          TRUE ~  "2021"))


### Visualise results using forest plot

# General cohorts
a <- ggplot(
        subset(all, !(group %in% c("Hospitalised COVID-19 2020","Hospitalised COVID-19 2021",
                                  "Hospitalised pneumonia 2019"))
              & !(category %in% c("0",NA))), aes(x=rate_ppm, y=category, col = year)
        ) +
  geom_errorbar(aes(xmax = uc_ppm, xmin = lc_ppm, group = year), 
                position = position_dodge(width = .5), width = 0.5, col="gray50") +
  geom_point(position = position_dodge(width = .5)) +
  scale_color_manual(values = c("#edd746","#0f85a0", "#dd4124"))+
  xlab("Rate per 100 person-months, 95% CI") + ylab(NULL) +
  facet_grid(variable ~ cat, scales = "free_y", space = "free",switch= "y")+
  theme_bw()+
  theme(text = element_text(size = 9),
        legend.title = element_blank(),
        legend.position = "right",
        strip.placement = "outside",
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_line(color="gray85"),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_text(angle= 45,hjust=1),
        axis.title.x = element_text(size = 8),
        strip.background = element_blank())


# Hospitalised cohorts
b <- ggplot(
        subset(all, (group %in% c("Hospitalised COVID-19 2020","Hospitalised COVID-19 2021",
                                  "Hospitalised pneumonia 2019"))
              & !(category %in% c("0",NA))), aes(x=rate_ppm, y=category, col = year)
        ) +
  geom_errorbar(aes(xmax = uc_ppm, xmin = lc_ppm, group=year), 
                position = position_dodge(width = .5), width = 0.5, col="gray50") +
  geom_point(position = position_dodge(width=.5)) +
  scale_color_manual(values = c("#edd746","#0f85a0", "#dd4124"))+
  #scale_x_continuous(lim= c(0,7)) +
  xlab("Rate per 100 person-months, 95% CI") + ylab(NULL) +
  facet_grid(variable ~ cat, scales = "free_y", space = "free", switch= "y")+
  theme_bw()+
  theme(text = element_text(size = 9),
        legend.title = element_blank(),
        legend.position = "right",
        strip.placement = "outside",
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major.x = element_line(color="gray85"),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_text(angle= 45,hjust=1),
        axis.title.x = element_text(size = 8),
        strip.background = element_blank())


# Combine plots and save

ggarrange(a, b, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom", labels = c("a","b")) +  
  bgcolor("White")  

ggsave("C:/Users/aschaffer/OneDrive - Nexus365/Documents/Released outputs/long-covid-sick-notes/Graphs/figure1.png", dpi= 300, height = 6, width = 9, units = "in")

