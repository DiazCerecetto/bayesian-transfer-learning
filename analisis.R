# Power prior Beta-Binomial: T tiene 6 éxitos en 20 y S tiene 100 observaciones.
# Para cada número de éxitos de S elegimos phi con grilla, Monte Carlo y DIC.
# Ejecutar desde la carpeta del repositorio: Rscript analisis.R

y_T <- 6
n_T <- 20
n_S <- 100
theta <- seq(0.01, 0.99, length.out = 99)  # grilla de theta
phis <- seq(0, 1, by = 0.1)                # pesos que probamos
fuentes <- 6:60                            # éxitos de S que probamos

# DIC calculado con los datos de T, para una fuente y_S y un peso phi
calcular_DIC <- function(y_S, phi) {
  posterior <- dbinom(y_T, n_T, theta) * dbinom(y_S, n_S, theta)^phi * dbeta(theta, 1, 1)
  set.seed(84735)
  muestra <- sample(theta, 10000, replace = TRUE, prob = posterior / sum(posterior))
  D <- -2 * dbinom(y_T, n_T, muestra, log = TRUE)
  D_media <- -2 * dbinom(y_T, n_T, mean(muestra), log = TRUE)
  2 * mean(D) - D_media
}

# DIC para cada phi (filas) y cada fuente (columnas); nos quedamos con el menor
DIC <- matrix(NA, nrow = length(phis), ncol = length(fuentes))
phi_elegido <- c()
DIC_minimo <- c()
for (j in 1:length(fuentes)) {
  for (i in 1:length(phis)) {
    DIC[i, j] <- calcular_DIC(fuentes[j], phis[i])
  }
  phi_elegido[j] <- phis[which.min(DIC[, j])]
  DIC_minimo[j] <- min(DIC[, j])
}

resultados <- data.frame(y_S = fuentes, phi = phi_elegido, DIC = round(DIC_minimo, 3))
print(resultados, row.names = FALSE)
capture.output(print(resultados, row.names = FALSE), file = "resultados/salida-power-prior.txt")

# Figura: phi elegido según S, y DIC según phi para cuatro fuentes
png("figuras/sensibilidad-fuente.png", width = 1400, height = 520, res = 150)
par(mfrow = c(1, 2))
plot(fuentes, phi_elegido, type = "s", lwd = 2,
     xlab = "Proporción de S (%)", ylab = expression(phi), main = "Peso elegido según S")
plot(phis, DIC[, fuentes == 18], type = "l", lwd = 2, col = 1, ylim = c(3.5, 9),
     xlab = expression(phi), ylab = "DIC", main = "DIC según el peso")
lines(phis, DIC[, fuentes == 30], lwd = 2, col = 2)
lines(phis, DIC[, fuentes == 44], lwd = 2, col = 3)
lines(phis, DIC[, fuentes == 60], lwd = 2, col = 4)
legend("right",c("S = 18%", "S = 30%", "S = 44%", "S = 60%"), col = 1:4, lwd = 2, bty = "n", cex = 0.8)
dev.off()
