install.packages("maps")
library(ggplot2)
library(sf)

cl <- st_read("Tarea 2/mapas vectoriales 2011/ine_depto.shp")[cl$DEPTO == 4, ]
cl <- st_set_crs(cl, 32721)

marco_etapa_1 <- marco_etapa_1 %>% 
  mutate(LOCALIDAD = case_when(
    localidades == "ÐANGAPIRE" ~ "ÑANGAPIRE",
    localidades == "BAÐADO DE MEDINA" ~ "BAÑADO DE MEDINA",
    localidades == "CASERIO LAS CAÐAS" ~ "LAS CAÑAS",
    localidades == "GETULIO VARGAS" ~ "VARGAS",
    localidades == "LAGO MERIN" ~ "LAGUNA MERIN",
    TRUE ~ localidades
  ))

localidades_cl <- st_read("Tarea 2/paislocalidades_shp/PaisLocalidades.shp")[localidades_cl$CODDEPTO == "E", ]
localidades_cl_centroid <- st_centroid(localidades_cl) %>% 
  inner_join(marco_etapa_1, by = "LOCALIDAD") %>% 
  mutate(viv_lev = case_when(n_viv > 20000 ~ "Melo",
                             n_viv > 5000 & n_viv < 20000 ~ "Rio Branco",
                             n_viv >= 150 & n_viv < 5000 ~ "150 - 1384 viviendas",
                             n_viv < 150 ~ "menos de 150 viviendas"),
         viv_lev = factor(viv_lev, levels = c("Melo", "Rio Branco", "150 - 1384 viviendas", "menos de 150 viviendas")))

ggplot() +
  geom_sf(data = cl, color = "black", fill = "#cef2da") +
  geom_sf(data = localidades_cl_centroid, aes(color = viv_lev), size = 5) +
  scale_fill_gradientn(colours = rev(grDevices::heat.colors(10)), name = NULL) +
  labs(title = "Localidades de Cerro Largo") +
  scale_color_manual("", values=c("#b30000", "#e34a33", "#fc8d59", "#fdcc7a")) +
  theme(panel.background = element_rect("white"), axis.text = element_blank(), axis.ticks = element_blank())

ggplot() +
  geom_sf(data = cl, color = "black", fill = "#cef2da") +
  geom_sf(data = localidades_cl_centroid, aes(size = n_viv), color = "#b30000") +
  scale_fill_gradientn(colours = rev(grDevices::heat.colors(10)), name = NULL) +
  scale_size("Cantidad de viviendas") +
  labs(title = "Localidades de Cerro Largo") +
  theme(panel.background = element_rect("white"), axis.text = element_blank(), axis.ticks = element_blank())

ggplot() +
  geom_sf(data = cl, color = "black", fill = "#cef2da") +
  geom_sf(data = localidades_cl_centroid, aes(size = n_viv, color = viv_lev)) +
  scale_fill_gradientn(colours = rev(grDevices::heat.colors(10)), name = NULL) +
  scale_size("Cantidad de viviendas") +
  scale_color_manual("", values=c("#b30000", "#e34a33", "#fc8d59", "#fdcc7a")) +
  labs(title = "Localidades de Cerro Largo") +
  theme(panel.background = element_rect("white"), axis.text = element_blank(), axis.ticks = element_blank())

 