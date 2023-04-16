library(tidyverse)
library(haven)

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
