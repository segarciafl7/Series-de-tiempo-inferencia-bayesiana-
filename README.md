# Series-de-tiempo-inferencia-bayesiana-
# 📈 Análisis del Impacto Causal en el Precio de las Acciones de Ecopetrol  

## 📌 Descripción
Este proyecto aplica el modelo **CausalImpact** (Google, 2015) para evaluar el efecto de un evento a partir de agosto de 2022 en el precio de las acciones de **Ecopetrol (EC)**.  
Se utilizan series de tiempo de **Ecopetrol**, junto con covariables externas como el precio del **crudo Brent**, el índice **S&P 500 (SYP)** y las acciones de **ExxonMobil**, con el fin de construir un contrafactual y estimar el impacto.

---

## ⚙️ Tecnologías utilizadas
- **R**: tidyverse, xts, CausalImpact, corrplot, coda  
- **Visualización**: ggplot2  
- **Método estadístico**: Bayesian Structural Time Series (BSTS)  

---

## 📊 Flujo de trabajo
1. **Carga y limpieza de datos** (lectura de CSV con precios históricos).  
2. **Transformación a serie temporal (`xts`)** para modelado.  
3. **Definición de periodos**:  
   - Pre-evento: 2018-02-01 a 2022-07-31  
   - Post-evento: 2022-08-01 a 2025-08-01  
4. **Ajuste del modelo BSTS y CausalImpact** con 50,000 iteraciones MCMC.  
5. **Visualización personalizada** con `ggplot2` (precio observado vs. contrafactual).  
6. **Análisis de correlaciones** entre Ecopetrol y covariables en el periodo pre-evento.  
7. **Diagnóstico de convergencia MCMC** con `coda`.  

---

## ✅ Resultados principales
- El modelo logra un buen ajuste en el periodo pre-evento, validando el uso de Brent y Exxon como covariables externas.  
- Se observa un **impacto acumulado positivo/negativo** en el precio de Ecopetrol posterior al evento (extraído de `summary(impact)`).  
- El intervalo de credibilidad muestra la incertidumbre de la estimación, con un efecto sostenido en el tiempo.  

> ⚠️ Nota: Los valores exactos del impacto pueden reproducirse ejecutando el script.  

---

## 📈 Visualización principal
Ejemplo de gráfico mejorado con ggplot2:  

- Línea roja: Precio observado de Ecopetrol.  
- Línea azul: Predicción contrafactual (sin intervención).  
- Banda azul: Intervalo de credibilidad (95%).  
- Línea gris punteada: Inicio del evento (ago-2022).  

---

## 🚀 Cómo usar
```bash
# 1. Clonar repositorio
git clone https://github.com/usuario/ecopetrol-causalimpact.git

# 2. Abrir R o RStudio

# 3. Instalar dependencias
install.packages(c("tidyverse", "xts", "CausalImpact", "corrplot", "coda"))

# 4. Ejecutar script principal
source("scripts/analisis_ecopetrol.R")
