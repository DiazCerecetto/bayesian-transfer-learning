# y_T ~ Bin(n_T, theta),   y_S ~ Bin(n_S, theta),   theta ~ Beta(1, 1)
# p(theta) oc f_T(y_T | theta) * f_S(y_S | theta)^phi * pi(theta)

# Parte 1: datos y grillas
y_T <- 6
n_T <- 20
n_S <- 100
theta <- seq(0.01, 0.99, length.out = 99)  # theta = 0.01, 0.02, ..., 0.99
phis <- seq(0, 1, by = 0.1)                # phi = 0, 0.1, ..., 1
fuentes <- 6:60                            # y_S = 6, 7, ..., 60

# Parte 2:
# Para cada phi y cada fuente se calcula el DIC
#   D(theta) = -2 log f_T(y_T | theta)
#   DIC = 2 * promedio de D(theta) en la muestra - D(promedio de la muestra)
DIC <- matrix(NA, nrow = length(phis), ncol = length(fuentes))
for (j in 1:length(fuentes)) {
  for (i in 1:length(phis)) {
    y_S <- fuentes[j]
    phi <- phis[i]
    # Posterior en la grilla de theta y muestras de Monte Carlo
    posterior <- dbinom(y_T, n_T, theta) * dbinom(y_S, n_S, theta)^phi * dbeta(theta, 1, 1)
    set.seed(84735)
    muestra <- sample(theta, 10000, replace = TRUE, prob = posterior / sum(posterior))
    # DIC calculado solo con los datos de T
    D <- -2 * dbinom(y_T, n_T, muestra, log = TRUE)
    D_media <- -2 * dbinom(y_T, n_T, mean(muestra), log = TRUE)
    DIC[i, j] <- 2 * mean(D) - D_media
  }
}

# Parte 3: phi elegido para cada fuente
#   La columna j de DIC tiene DIC(phi) para phi = 0, 0.1, ..., 1 y y_S = fuentes[j].
#   phi elegido = el phi con menor DIC en esa columna.
phi_elegido <- c()
DIC_minimo <- c()
for (j in 1:length(fuentes)) {
  phi_elegido[j] <- phis[which.min(DIC[, j])]
  DIC_minimo[j] <- min(DIC[, j])
}
resultados <- data.frame(y_S = fuentes, phi = phi_elegido, DIC = round(DIC_minimo, 3))
print(resultados, row.names = FALSE)
capture.output(print(resultados, row.names = FALSE), file = "resultados/salida-power-prior.txt")

# Parte 4: figura con el phi elegido según S y el DIC según phi para cuatro fuentes
png("figuras/sensibilidad-fuente.png", width = 1400, height = 520, res = 150)
par(mfrow = c(1, 2))
plot(fuentes, phi_elegido, type = "s", lwd = 2,
     xlab = "Proporción de S (%)", ylab = expression(phi), main = "Peso elegido según S")
plot(phis, DIC[, fuentes == 18], type = "l", lwd = 2, col = 1, ylim = c(3.5, 9),
     xlab = expression(phi), ylab = "DIC", main = "DIC según el peso")
lines(phis, DIC[, fuentes == 30], lwd = 2, col = 2)
lines(phis, DIC[, fuentes == 44], lwd = 2, col = 3)
lines(phis, DIC[, fuentes == 60], lwd = 2, col = 4)
legend("right", c("S = 18%", "S = 30%", "S = 44%", "S = 60%"), col = 1:4, lwd = 2, bty = "n", cex = 0.8)
dev.off()
