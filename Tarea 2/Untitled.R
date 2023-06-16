library(haven)
library(tidyverse)
library(sampling)
library(here)


marco_cerro_largo <- read_sav("Tarea 2/Marco_2011_con_barrio_y_Sec_po_savl.sav") %>% 
  # obtenemos el departamento de Cerro Largo y descartamos las zonas censales rurales
  filter(dpto == "04" & codloc != 4900) %>% 
  # modificamos las variables indicadoras de localidad para que el conurbano de Melo figure como parte de la capital
  mutate(
    codloc = case_when(
      codloc == 4987 ~ 4220,
      codloc == 4983 ~ 4220,
      codloc == 4825 ~ 4220,
      TRUE ~ codloc
    ),
    nomloc = case_when(
      nomloc == "BARRIO LA VINCHUCA" ~ "MELO",
      nomloc == "BARRIO LOPEZ BENITEZ" ~ "MELO",
      nomloc == "HIPODROMO" ~ "MELO",
      TRUE ~ nomloc
    )
  ) %>% 
  transmute(pob = P_TOT,
            viviendas = V_TOT,
            localidades = nomloc)


# etapa 1

set.seed(123)

marco_etapa_1 <- marco_cerro_largo %>% 
  group_by(localidades) %>% 
  # calculamos la cantidad  de viviendas y zonas censales por localidad
  summarise(n_viv = sum(viviendas), n_z = n()) %>%  
  # quitamos a Melo y Rio Branco del marco de la primera etapa, ya que pasarán directamente a la segunda
  # creamos los estratos en función de la cantidad de viviendas
  mutate(estrato = cut(n_viv, breaks = c(0, 150, 5000,15000, Inf), right = FALSE)) %>%
  arrange(estrato)

n_1 <- 7 # tamaño de muestra total de la primera etapa

estratos <- marco_etapa_1 %>% 
  group_by(estrato) %>%  # calculamos la cantidad de localidades por estrato
  summarise(n_loc = n(), N_z = sum(n_z), N_viv = sum(n_viv)) %>% 
  mutate(mh = case_when(row_number() == 1 ~ 2,
                        row_number() == 2 ~ 3,
                        row_number() == 3 ~ 1,
                        row_number() == 4 ~ 1,
                        TRUE ~ 1),
         n_pad = round(1000*N_viv/sum(N_viv)))


disenio_1 <-  strata(marco_etapa_1, stratanames = "estrato", size = estratos$mh)

muestra_1 <- getdata(marco_etapa_1, disenio_1) %>% 
  select(localidades, n_viv, n_z, estrato)


# niveles de error y confianza dentro de cada zona
error <- 0.05
alpha <- 0.1
# bind_rows(muestra_1, loc_grandes) %>%

marco_etapa_2 <- muestra_1 %>%
  left_join(estratos[c("estrato", "n_pad")], by = "estrato") %>% 
  group_by(estrato) %>%  
  mutate(n_pad = round(n_pad*n_viv/sum(n_viv)),
         N_i = round(n_viv/n_z),
         r = round((((n_viv/n_z))/4)*qnorm(1-alpha/2)**2/((n_viv/n_z)*error**2 + (qnorm(1-alpha/2)**2)/4)),
         n_zs = round(n_pad/r),
         n_pad_of = n_zs *r) %>% 
  arrange(localidades)

marco_etapa_2_zonas <- marco_cerro_largo %>% 
  filter(localidades %in% marco_etapa_2$localidades) %>% 
  arrange(localidades)
  
disenio_2 <- strata(marco_etapa_2_zonas, strataname = "localidades", size = marco_etapa_2$n_zs)

muestra_2 <- getdata(marco_etapa_2_zonas, disenio_2) %>% 
  select(localidades, n_viv, n_z, estrato)

### usando multistage

marco_cerro_largo <- read_sav("Tarea 2/Marco_2011_con_barrio_y_Sec_po_savl.sav") %>% 
  # obtenemos el departamento de Cerro Largo y descartamos las zonas censales rurales
  filter(dpto == "04" & codloc != 4900) %>% 
  # modificamos las variables indicadoras de localidad para que el conurbano de Melo figure como parte de la capital
  mutate(
    codloc = case_when(
      codloc == 4987 ~ 4220,
      codloc == 4983 ~ 4220,
      codloc == 4825 ~ 4220,
      TRUE ~ codloc
    ),
    nomloc = case_when(
      nomloc == "BARRIO LA VINCHUCA" ~ "MELO",
      nomloc == "BARRIO LOPEZ BENITEZ" ~ "MELO",
      nomloc == "HIPODROMO" ~ "MELO",
      TRUE ~ nomloc
    )) %>% 
  select(codcomp, nomloc, V_TOT) %>% 
  group_by(nomloc) %>% 
  mutate(N_viv = sum(V_TOT),
         N_z = n(),
         estrato = cut(N_viv, breaks = c(0, 150, 5000,15000, Inf), labels = c("3_2", "3_1", "2", "1"), right = FALSE)) %>% 
  ungroup(nomloc) %>% 
  group_by(estrato) %>% 
  mutate(N_viv_e = sum(N_viv), 
         N_z_e = sum(N_z),
         n_l = case_when(estrato == "1" ~1,
                         estrato == "2" ~1,
                         estrato == "3_1" ~3,
                         estrato == "3_2" ~2,),
         n_pad = )
  
  
  
  

# V_TOT = ifelse(V_TOT < 10, 10, V_TOT) %>% 