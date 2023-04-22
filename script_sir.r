library(tidyverse)
library(haven)
library(survey)
library(ggplot2)

# Limpiar el ambiente

rm(list = ls())

# Datos

load("datos.RData")

# Functiones auxiliares

is_nbi_missing <- function(x) x %in% c(8, 9)
is_nbi_var <- function() starts_with("NBI_")
mutate_nbi <- function(x) zap_labels(x) %>% if_else(is_nbi_missing(.), 0, .)
select_nbi <- function(x) select(x, is_nbi_var(), -NBI_CANTIDAD)
has_xo <- function(x) if_else(x$HOGCE09 == 0, 1, 0)
has_nbi <- function(x) if_else(x$NBI_TOTAL >= 4, 1, 0)

# Preprocesamiento
data <- rio_branco %>%
  mutate(across(is_nbi_var(), ~ mutate_nbi(.))) %>%
  mutate(NBI_TOTAL = rowSums(select_nbi(.)), XO = has_xo(.)) %>%
  mutate(NBI = has_nbi(.)) %>%
  filter(!duplicated(ID_VIVIENDA)) %>%
  select(NBI, XO)

# Estimación de NBI mediante el diseño SIR con HT
set.seed(0)

n_simulations <- 1000

simulate_t_pi_sir <- function(sample_size) {
  replicate(n_simulations, {
    s <- sample(data$NBI, sample_size, replace = TRUE)
    p <- 1 - (1 - 1 / nrow(data))^sample_size
    sum(s / p)
  })
}


sample_sizes <- c(150, 600, 1000)

t_pi_sir <- data.frame(
  lapply(sample_sizes, simulate_t_pi_sir)
)
colnames(t_pi_sir) <- paste0("n_", sample_sizes)


empirical_distribution <- function(n) {
  var <- paste("n", n, sep = "_")
  binwidth <- 3.5 * sd(t_pi_sir[[var]]) / (n^(1 / 3))
  ggplot(t_pi_sir, aes(x = !!sym(var), y = after_stat(density))) +
    geom_histogram(binwidth = binwidth, color = "black", fill = "white") +
    geom_density(alpha = 0.2, fill = "blue") +
    labs(x = "Data", y = "Density") +
    theme_classic()

  ggsave(
    paste("t_pi_sir_", var, ".png", sep = ""),
    width = 10, height = 10, dpi = 300
  )
}


for (n in sample_sizes) empirical_distribution(n)
