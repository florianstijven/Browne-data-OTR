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

# Build the plot for CESD only.
pooled_inference_aggregated_rules_tbl %>%
  filter(
    aggregation %in% c("Circular Mean", "One-Size-Fits-All", "Rubin's Rules"),
    outcome == "cesd"
  ) %>%
  mutate(
    OTR_method = fct_recode(
      OTR_method,
      Sertraline = "One-Size-Fits-All (0)",
      "Sertraline + IPT" = "One-Size-Fits-All (1)",
      "Value Search Estimation" = "value search"
    ),
    aggregation = fct_recode(aggregation,
                             "Spherical Mean" = "Circular Mean"),
    data = forcats::fct_recode(data, "Original Data" = "Original", "Modified Data" = "Artificial"),
    data = forcats::fct_relevel(data, "Original Data", "Modified Data"),
    aggregation = forcats::fct_relevel(aggregation, "Spherical Mean", "Rubin's Rules", "One-Size-Fits-All")
  ) %>%
  ggplot(aes(y = imputation, x = pooled_estimated_value, color = OTR_method)) +
  geom_point(position = position_dodge(width = .3)) +
  geom_errorbarh(
    aes(
      xmin = pooled_estimated_value - 1.96 * sqrt(pooled_total_variance),
      xmax = pooled_estimated_value + 1.96 * sqrt(pooled_total_variance)
    ),
    height = 0.2,
    position = position_dodge(width = .3),
  ) +
  xlab(latex2exp::TeX("Pooled Estimated Value, \\bar{\\hat{\\nu}}(\\tilde{d})")) +
  ylab("Imputation Method") +
  scale_color_discrete(name = "OTR method") +
  facet_grid(aggregation~data) +
  theme(legend.position = "bottom", 
        legend.title = element_blank()) +
  guides(color = guide_legend(nrow = 2))
  
# Save figure.
ggsave(filename = "figures-manuscript/main-text/estimated-values-aggregated.pdf",
       device = "pdf",
       width = double_width,
       height = double_height,
       units = "cm",
       dpi = res)

# Build the plot for all outcome variables.
pooled_inference_aggregated_rules_tbl %>%
  filter(imputation == "Per Arm", aggregation != "majority vote", is.na(update)) %>%
  mutate(OTR_method = fct_recode(
    OTR_method,
    Sertraline = "One-Size-Fits-All (0)",
    "Sertraline + IPT" = "One-Size-Fits-All (1)",
    "Value Search Estimation" = "value search"
  ),
  aggregation = fct_recode(aggregation,
                           "Spherical Mean" = "Circular Mean"),
  aggregation = fct_relevel(aggregation, c("One-Size-Fits-All", "Rubin's Rules", "Spherical Mean")),
  outcome = factor(outcome, c("cesd", "madrs", "vas", "sas", "famfun"))) %>%
  ggplot(aes(y = aggregation, x = pooled_estimated_value, color = OTR_method)) +
  geom_point(aes(fill = OTR_method), position = position_dodge(width = .3)) +
  geom_errorbarh(
    aes(
      xmin = pooled_estimated_value - 1.96 * sqrt(pooled_total_variance),
      xmax = pooled_estimated_value + 1.96 * sqrt(pooled_total_variance)
    ),
    height = 0.2,
    position = position_dodge(width = .3),
  ) +
  xlab(latex2exp::TeX("Pooled Estimated Value, \\bar{\\hat{\\nu}}(\\tilde{d})")) +
  ylab(NULL) +
  scale_color_discrete(name = "OTR method") +
  scale_fill_discrete(name = "OTR method") +
  facet_grid(~ outcome, scales = "free") +
  theme(
    axis.text.y = element_text(
      angle = 90,
      vjust = 1,
      hjust = 0.5
    ),
    legend.position = "bottom",
    legend.title = element_blank()
  ) +
  guides(color = guide_legend(nrow = 2))

ggsave(filename = "figures-manuscript/supplementary-information/results-various-aggregation-methods-all-outcomes.pdf",
       device = "pdf",
       width = double_width,
       height = double_height,
       units = "cm",
       dpi = res)
