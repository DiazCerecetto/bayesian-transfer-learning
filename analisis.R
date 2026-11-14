# Un experimento Beta-Binomial: T=6/20, n_S=100 y proporcion de S variable.
# Aproximacion por grilla y Monte Carlo del Practico 2. Solo requiere R base.
# Ejecutar: Rscript analisis.R. Tambien se puede cargar con source().

evaluar_phi <- function(y_S, n_S, y_T, n_T, phi) {
  theta <- seq(0.01, 0.99, length.out = 99)
  pesos <- dbinom(y_T, n_T, theta) * dbinom(y_S, n_S, theta)^phi * dbeta(theta, 1, 1)
  probabilidades <- pesos / sum(pesos)
  set.seed(84735)
  muestra <- sample(theta, 10000, replace = TRUE, prob = probabilidades)
  media <- mean(muestra)
  devianza <- -2 * dbinom(y_T, n_T, muestra, log = TRUE)
  D_media <- -2 * dbinom(y_T, n_T, media, log = TRUE)
  data.frame(phi = phi, media_post = media, DIC = 2 * mean(devianza) - D_media)
}

perfil_fuente <- function(yS) {
  phis <- seq(0, 1, by = 0.1)
  do.call(rbind, lapply(phis, function(p) evaluar_phi(yS, 100, 6, 20, p)))
}

barrer_fuente <- function() {
  resumir <- function(yS) {
    p <- perfil_fuente(yS)
    i <- which.min(p$DIC)
    a <- 7 + p$phi[i] * yS
    b <- 15 + p$phi[i] * (100 - yS)
    data.frame(y_S = yS, n_S = 100, y_T = 6, n_T = 20,
      phi_MC = p$phi[i], DIC_MC = p$DIC[i],
      media_posterior = a / (a + b),
      IC95_inf = qbeta(0.025, a, b), IC95_sup = qbeta(0.975, a, b))
  }
  filas <- list(resumir(30))
  terminado <- c(FALSE, FALSE)
  for (distancia in 1:70) {
    for (lado in 1:2) {
      if (terminado[lado]) next
      yS <- 30 + c(1, -1)[lado] * distancia
      if (yS < 0 || yS > 100) stop("No se encontro un corte dentro de 0:100.")
      fila <- resumir(yS)
      filas[[length(filas) + 1]] <- fila
      # Incluimos una fuente lejana (60%) en el mismo barrido.
      terminado[lado] <- fila$phi_MC == 0 && (lado == 2 || yS >= 60)
    }
    if (all(terminado)) break
  }
  stopifnot(all(terminado))
  do.call(rbind, filas)
}

graficar_barrido <- function(resultados) {
  r <- resultados[order(resultados$y_S), ]
  plot(r$y_S, r$phi_MC, type = "s", ylim = c(0, 1.05),
    col = "#245B91", lwd = 2, xlab = "Proporcion de S (%)",
    ylab = expression(phi^"*"), main = "Peso elegido segun S")
  abline(v = 30, lty = 3, col = "#94a3b8")
}

graficar_perfiles <- function() {
  fuentes <- c(18, 30, 44, 60)
  phis <- seq(0, 1, by = 0.1)
  valores <- sapply(fuentes, function(yS) perfil_fuente(yS)$DIC)
  colores <- c("#245B91", "#1b9e77", "#bc6b20", "#9a59ae")
  matplot(phis, valores, type = "l", col = colores, lty = 1:4, lwd = 2,
    xlab = expression(phi), ylab = "DIC", main = "Valores del mismo barrido")
  for (i in seq_along(fuentes)) {
    j <- which.min(valores[, i])
    points(phis[j], valores[j, i], pch = 19, col = colores[i])
  }
  legend("topleft", paste0("S = ", fuentes, "%"), col = colores,
    lty = 1:4, lwd = 2, bty = "n", cex = 0.8)
}

generar_entrega <- function(directorio = ".") {
  directorio <- normalizePath(directorio, mustWork = TRUE)
  anterior <- setwd(directorio)
  on.exit(setwd(anterior), add = TRUE)
  dir.create("resultados", showWarnings = FALSE)
  dir.create("figuras", showWarnings = FALSE)
  resultados <- barrer_fuente()
  stopifnot(!anyDuplicated(resultados$y_S),
    all(is.finite(as.matrix(resultados))),
    all(resultados$IC95_inf < resultados$IC95_sup))
  write.csv(resultados, "resultados/sensibilidad-fuente.csv", row.names = FALSE)

  salida <- capture.output({
    cat("Experimento: T=6/20, n_S=100; se varia y_S.\n")
    cat("Previa Beta(1,1); phi=0:1 con paso 0.1; 99 puntos de theta.\n")
    cat("Monte Carlo: 10000 muestras; semilla 84735.\n\n")
    print(round(resultados[, c("y_S", "phi_MC", "DIC_MC")], 3), row.names = FALSE)
    cortes <- c(max(resultados$y_S[resultados$y_S < 30 & resultados$phi_MC == 0]),
                min(resultados$y_S[resultados$y_S > 30 & resultados$phi_MC == 0]))
    cat("phi_MC: primer phi=0 por debajo en ", cortes[1],
      "% y por arriba en ", cortes[2], "%\n", sep = "")
  })
  writeLines(salida, "resultados/salida-power-prior.txt", useBytes = TRUE)

  seleccion <- c(6, 7, 18, 28, 29, 30, 31, 32, 44, 54, 60)
  tabla_seleccion <- resultados[match(seleccion, resultados$y_S), ]
  stopifnot(!anyNA(tabla_seleccion))
  row_end <- strrep(intToUtf8(92), 2)
  filas <- sprintf("%d & %.1f %s", tabla_seleccion$y_S,
    tabla_seleccion$phi_MC, row_end)
  tabla <- c("\\begin{table}[H]", "\\centering", "\\small",
    "\\begin{tabular}{@{}cc@{}}", "\\toprule",
    paste0("\\textbf{Fuente (\\%)} & $\\phi^*$ ", row_end),
    "\\midrule", filas, "\\bottomrule", "\\end{tabular}",
    "\\caption{Peso elegido por grilla y Monte Carlo para algunos valores del barrido.}",
    "\\label{tab:sensibilidad}", "\\end{table}")
  writeLines(tabla, "resultados/tabla-sensibilidad-fuente.tex", useBytes = TRUE)

  png("figuras/sensibilidad-fuente.png", width = 1400, height = 520, res = 150)
  tryCatch({
    par(mfrow = c(1, 2), mar = c(4.3, 4.5, 2.8, 1.1),
      mgp = c(2.8, 0.8, 0), las = 1)
    graficar_barrido(resultados)
    graficar_perfiles()
  }, finally = dev.off())

  # El HTML recibe los mismos pesos que el CSV, sin recalcular el DIC en JavaScript.
  r <- resultados[order(resultados$y_S), ]
  valores <- paste(sprintf("[%d,%.1f]", r$y_S, r$phi_MC), collapse = ",")
  html <- rawToChar(readBin("index.html", "raw", n = file.info("index.html")$size))
  Encoding(html) <- "bytes"
  inicio <- "/* SENSITIVITY_START */"
  fin <- "/* SENSITIVITY_END */"
  stopifnot(length(gregexpr(inicio, html, fixed = TRUE, useBytes = TRUE)[[1]]) == 1L,
    length(gregexpr(fin, html, fixed = TRUE, useBytes = TRUE)[[1]]) == 1L)
  a <- regexpr(inicio, html, fixed = TRUE, useBytes = TRUE)[1]
  b <- regexpr(fin, html, fixed = TRUE, useBytes = TRUE)[1]
  stopifnot(a > 0, b > a)
  b <- b + nchar(fin) - 1
  html <- paste0(substr(html, 1, a - 1), inicio,
    "\n  const sensitivity = [", valores, "];\n  ", fin,
    substr(html, b + 1, nchar(html, type = "bytes")))
  writeBin(charToRaw(html), "index.html")
  cat(paste(salida, collapse = "\n"), "\n")
  invisible(resultados)
}

if (sys.nframe() == 0L) {
  argumento <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  directorio <- dirname(normalizePath(sub("^--file=", "", argumento[1])))
  generar_entrega(directorio)
}
