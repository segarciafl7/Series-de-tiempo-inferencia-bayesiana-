# ===============================
# 0️⃣ Paquetes
# ===============================
library(tidyverse)
library(readr)
library(stringr)
library(xts)
library(CausalImpact)

# ===============================
# 1️⃣ Leer CSV correctamente
# ===============================
datos_raw <- read.csv(
  "C:/Users/phain/Downloads/Datos históricos de Ecopetrol (EC)1.csv",
  sep = ";",
  dec = ",",
  stringsAsFactors = FALSE,
  header = TRUE
)

# Quitar la primera fila de nombres repetidos 
datos_raw <- datos_raw[-1, ]

# ===============================
# 2️⃣ Funciones para extraer precios
# ===============================
extraer_precio_ecopetrol <- function(col) {
  str_extract(col, '\\d{1,3}(?:\\.\\d{3})*,\\d+') %>%
    str_remove_all("\\.") %>%
    str_replace(",", ".") %>%
    as.numeric()
}

extraer_precio_brent_syp <- function(col) {
  str_extract(col, '\\d+,\\d+') %>%
    str_replace(",", ".") %>%
    as.numeric()
}

extraer_precio_exxon <- function(col) {
  str_extract(col, '\\d+\\.\\d+') %>%
    as.numeric()
}

# ===============================
# 3️⃣ Crear tibble con precios
# ===============================
ci_data <- tibble(
  Fecha     = str_extract(datos_raw$ecopetrol, "\\d{2}\\.\\d{2}\\.\\d{4}") %>%
    as.Date(format = "%d.%m.%Y"),
  Ecopetrol = extraer_precio_ecopetrol(datos_raw$ecopetrol),
  Brent     = extraer_precio_brent_syp(datos_raw$brent),
  SYP       = extraer_precio_brent_syp(datos_raw$syp),
  Exxon     = extraer_precio_exxon(datos_raw$exxon)
)

# ===============================
# 4️⃣ Ordenar por fecha
# ===============================
ci_data <- ci_data %>% arrange(Fecha)
head(ci_data)
tail(ci_data)

# ===============================
# 5️⃣ Convertir a xts
# ===============================
ci_ts <- xts(
  ci_data %>% select(Ecopetrol, Brent, SYP, Exxon),
  order.by = ci_data$Fecha
)
# ===============================
# 6️⃣ Definir periodos pre y post evento
# ===============================
pre.period <- as.Date(c("2018-02-01", "2022-07-31"))
post.period <- as.Date(c("2022-08-01", "2025-08-01"))

# ===============================
# 7️⃣ Ejecutar CausalImpact
# ===============================
impact <- CausalImpact(
  data = ci_ts,
  pre.period = pre.period,
  post.period = post.period,
  model.args = list(niter = 50000)
)

# ===============================
# 8️⃣ Resumen y gráfica
# ===============================
summary(impact)          # Resumen numérico
plot(impact)             # Gráficas del impacto
summary(impact, "report") # Reporte en texto

#la idea es realizar un grafico un poco mas agradable visualmente
library(ggplot2)
library(dplyr)
library(tidyr)

# Extraer resultados del modelo `impact` (debe estar definido)
ci_plot <- data.frame(
  Fecha = index(impact$series),
  Actual = impact$series$response,
  Predicted = impact$series$point.pred,
  Lower = impact$series$point.pred.lower,
  Upper = impact$series$point.pred.upper
)

# Transformar a formato largo para ggplot2
ci_plot_long <- ci_plot %>%
  pivot_longer(cols = c("Actual", "Predicted"), 
               names_to = "Serie", 
               values_to = "Precio")

# Renombrar para que sea más claro en la leyenda
ci_plot_long$Serie <- recode(ci_plot_long$Serie,
                             "Actual" = "Precio Observado",
                             "Predicted" = "Predicción Contrafactual")

# Gráfico principal
ggplot(ci_plot_long, aes(x = Fecha, y = Precio, color = Serie)) +
  # Líneas principales
  geom_line(size = 1.1) +
  
  # Intervalo de credibilidad
  geom_ribbon(data = ci_plot,
              aes(x = Fecha, ymin = Lower, ymax = Upper),
              fill = "steelblue", alpha = 0.2, inherit.aes = FALSE) +
  
  # Línea vertical en el inicio de la intervención
  geom_vline(xintercept = as.numeric(as.Date("2022-08-01")),
             linetype = "dashed", color = "gray30", size = 0.8, alpha = 0.7) +
  
  # Etiquetas
  labs(
    title = "Ecopetrol: Precio Real vs Predicción Contrafactual",
    subtitle = "Análisis con CausalImpact (2018–2025)",
    x = "Fecha",
    y = "Precio (COP)",
    color = ""
  ) +
  
  # Tema limpio
  theme_minimal() +
  
  # Colores personalizados
  scale_color_manual(values = c(
    "Precio Observado" = "darkred",
    "Predicción Contrafactual" = "steelblue"
  )) +
  
  # Ajustes visuales
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "#2C3E50"),
    plot.subtitle = element_text(size = 12, color = "gray40"),
    legend.position = "top",
    legend.title = element_blank(),
    axis.title = element_text(size = 12),
    panel.grid.minor = element_blank()
  ) +
  
  # Opcional: formato de ejes
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::comma)

# ===============================
# 5.1️⃣ Revisar correlaciones generales
# ===============================

# Seleccionar solo las variables numéricas
vars_numeric <- ci_data %>% select(Ecopetrol, Brent, SYP, Exxon)

# Matriz de correlación
cor_matrix <- cor(vars_numeric, use = "complete.obs")
print(cor_matrix)

# Opcional: visualización gráfica de la correlación
library(corrplot)  # si no lo tienes, instalar con install.packages("corrplot")
corrplot::corrplot(cor_matrix, method = "color", 
                   addCoef.col = "black", # muestra los valores
                   number.cex = 0.8,
                   tl.cex = 0.9, tl.col = "black",
                   title = "Correlación entre covariables",
                   mar=c(0,0,1,0))
# ===============================
# 5.2️⃣ Correlación solo en periodo pre-evento
# ===============================

# Definir el periodo pre-evento
pre_start <- as.Date("2018-02-01")
pre_end   <- as.Date("2022-07-31")

# Filtrar ci_data para el periodo pre-evento
ci_pre <- ci_data %>% filter(Fecha >= pre_start & Fecha <= pre_end)

# Seleccionar solo variables numéricas
vars_numeric_pre <- ci_pre %>% select(Ecopetrol, Brent, SYP, Exxon)

# Matriz de correlación en el periodo pre-evento
cor_matrix_pre <- cor(vars_numeric_pre, use = "complete.obs")
print(cor_matrix_pre)

# Opcional: visualización con corrplot
library(corrplot)  # instalar si no lo tienes
corrplot::corrplot(cor_matrix_pre, method = "color", 
                   addCoef.col = "black", number.cex = 0.8,
                   tl.cex = 0.9, tl.col = "black",
                   title = "Correlación entre covariables (pre-evento)",
                   mar=c(0,0,1,0))

bsts_model <- impact$model$bsts.model
class(bsts_model)

bsts_model$coefficients   # ahora sí debería tener la información de las covariables

library(coda)

mcmc_samples <- as.mcmc(bsts_model$coefficients)

par(mar=c(4,4,2,1))  # bottom, left, top, right
plot(mcmc_samples)



geweke.diag(mcmc_samples)
