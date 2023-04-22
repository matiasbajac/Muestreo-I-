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

# Funciones para estimación del total poblacional
# usando diseño SIR y estimador HT
set.seed(0)

sample_sir <- function(sampling_frame, sample_size) {
  sample(sampling_frame, sample_size, replace = TRUE)
}

simulate_t_pi_sir <- function(sampling_frame, sample_size) {
  n_simulations <- 5000

  replicate(n_simulations, {
    s <- sample_sir(sampling_frame, sample_size)
    p <- 1 - (1 - 1 / length(sampling_frame))^sample_size
    sum(s / p)
  })
}

empirical_distribution_sir <- function(sampling_frame, sample_size, prefix) {
  # Simular
  t <- data.frame(t_pi = simulate_t_pi_sir(sampling_frame, sample_size))

  # Regla de Scott para el ancho de los bins
  binwidth <- 3.5 * sd(t$t_pi) / (sample_size^(1 / 3))

  # Graficar Histograma + Curva de densidad
  ggplot(t, aes(x = t_pi, y = after_stat(density))) +
    geom_histogram(binwidth = binwidth, color = "black", fill = "white") +
    geom_density(alpha = 0.2, fill = "blue") +
    geom_vline(
      aes(xintercept = sum(sampling_frame)),
      color = "red",
      size = 1.5
    ) +
    labs(x = "Data", y = "Density") +
    theme_classic()

  # Guardar gráfico
  ggsave(
    paste0(prefix, "t_pi_sir_n_", sample_size, ".png"),
    width = 10, height = 10, dpi = 300
  )
}

sample_sizes <- c(150, 600, 1000)


# Estimación de la distribución empírica del estimador HT
# para la variable NBI

for (sample_size in sample_sizes) {
  empirical_distribution_sir(data$NBI, sample_size, prefix = "nbi_")
}

# Cálculo de Deff para el SIR

v_si_t_pi <- function(sampling_frame, sample) {
  pop_size <- length(sampling_frame)
  sample_size <- length(sample)

  ((pop_size^2) / sample_size) * (1 - sample_size / pop_size) * var(sample)
}

v_sir_t_pi <- function(sampling_frame, sample) {
  pop_size <- length(sampling_frame)
  sample_size <- length(sample)

  # Probabilidades de inclusión SIR y variación
  pi_k <- 1 - (1 - 1 / pop_size)^sample_size
  pi_kl <- 1 - 2 * (1 - 1 / pop_size)^sample_size + (1 - 2 / pop_size)^sample_size
  delta_kl <- pi_kl - pi_k^2
  delta_kk <- pi_k - pi_k^2

  # Doble suma de la característica cuando k != l
  sum_y_kl <- outer(sample, sample)
  diag(sum_y_kl) <- 0
  sum_y_kl <- sum(sum_y_kl)

  # Doble suma de la característica cuando k = l
  sum_y_k <- sum(sample)

  # Suma simple del cálculo de la varianza
  sum_k <- delta_kk / pi_k^3 * sum_y_k

  # Suma doble del cálculo de la varianza
  sum_kl <- delta_kl / (pi_kl * pi_k^2) * sum_y_kl

  # Varianza del estimador HT
  sum_k + sum_kl
}

deff_sir_t_pi <- function(sampling_frame, sample) {
  v_sir_t_pi(sampling_frame, sample) / v_si_t_pi(sampling_frame, sample)
}
