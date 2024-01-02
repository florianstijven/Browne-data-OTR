# In this script, we summarize the main results of the analysis of the original
# and aritficial Browne data in a single data set. 

# Size parameter for saving plots to disk.
single_width = 9
double_width = 14
single_height = 8.2
double_height = 12.8
res = 600

library(tidyverse)

# Combine the results from the original and artificial data into a single data
# set. We add a variable indicating the original or artificial data.
pooled_inference_aggregated_rules_tbl = bind_rows(
  readRDS(file = "OTR analyses/pooled_inference_aggregated_rules_tbl.rds") %>%
    mutate(data = "Original"),
  readRDS(file = "OTR analyses/pooled_inference_aggregated_rules_tbl_artificial.rds") %>%
    mutate(data = "Artificial", outcome = "cesd") %>%
    filter(update == 1)
)

# Build the plot.
pooled_inference_aggregated_rules_tbl %>%
  filter(aggregation %in% c("Circular Mean", "One-Size-Fits-All", "Rubin's Rules"),
         outcome == "cesd") %>%
  mutate(OTR_method = fct_recode(
    OTR_method,
    Sertraline = "One-Size-Fits-All (0)",
    "Sertraline + IPT" = "One-Size-Fits-All (1)",
    "Value Search Estimation" = "value search"
  )) %>%
  ggplot(aes(y = aggregation, x = pooled_estimated_value, color = OTR_method)) +
  geom_point(position = position_dodge(width = .3)) +
  geom_errorbarh(
    aes(
      xmin = pooled_estimated_value - 1.96 * sqrt(pooled_total_variance),
      xmax = pooled_estimated_value + 1.96 * sqrt(pooled_total_variance)
    ),
    height = 0.2,
    position = position_dodge(width = .3),
  ) +
  xlab(latex2exp::TeX("Pooled Estimated Value, \\bar{\\nu}(\\tilde{d})")) +
  ylab("Aggregation Method") +
  scale_color_discrete(name = "OTR method") +
  facet_grid(imputation~data) +
  theme(legend.position = "bottom", 
        legend.title = element_blank()) +
  guides(color = guide_legend(nrow = 2))
  
# Save figure.
ggsave(filename = "figures-manuscript/main-text/estimated-values-aggregated.png",
       device = "png",
       width = double_width,
       height = double_height,
       units = "cm",
       dpi = res)
