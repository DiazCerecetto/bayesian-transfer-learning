# Bayesian Transfer Learning

Trabajo final de Inferencia II, 2026 — Florencia Cosentino y Miguelángel Díaz.
Ejemplo Beta–Binomial de transferencia de información mediante *power priors*,
basado en la sección 6 de [Bon et al. (2023), *Being Bayesian in the 2020s*](https://doi.org/10.1098/rsta.2022.0156).

## Consultar la entrega

- [Explorador interactivo](https://diazcerecetto.github.io/bayesian-transfer-learning/): variar la fuente S y el peso φ.
- [Informe PDF publicado](https://diazcerecetto.github.io/bayesian-transfer-learning/informe.pdf).
- [Copia del PDF en el repositorio](informe.pdf).
- [Código R](analisis.R) y [resultados CSV](resultados/sensibilidad-fuente.csv).

## Archivos del repositorio

```text
analisis.R                              # Único script: modelo y generación de salidas
informe/
  informe.tex                           # Fuente del informe
figuras/
  sensibilidad-fuente.png                # Figura incluida en el informe
resultados/
  sensibilidad-fuente.csv                # Barrido completo, medias e intervalos
  tabla-sensibilidad-fuente.tex           # Tabla generada e incluida por el informe
  salida-power-prior.txt                 # Resultados numéricos incluidos en el anexo
informe.pdf                             # Copia final para descargar
index.html                              # Explorador autónomo, con CSS y JS incluidos
.github/workflows/publicar.yml           # Compilación y publicación en GitHub Pages
.gitignore                              # Excluye auxiliares, respaldos y archivos temporales
```

Se versionan el fuente LaTeX y todos sus archivos de entrada, junto con el PDF y
el HTML listos para consultar. La salida numérica `.txt` se conserva porque el
anexo la incluye directamente. Los archivos `.log`, `.aux`, `.out`, `.xdv`,
`.fls` y `.fdb_latexmk` son auxiliares de compilación y quedan ignorados, al igual
que `build/` y `_site/`. La tipografía usa Latin Modern, incluida en TeX Live.

## Reproducir

Requisitos: R base (Actions usa R 4.5.3), XeLaTeX, latexmk y los paquetes de
LaTeX del preámbulo. En Ubuntu se instalan con:

```bash
sudo apt-get install latexmk texlive-xetex texlive-lang-spanish texlive-latex-extra lmodern
```

Desde la raíz del repositorio:

```bash
Rscript analisis.R
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=build informe/informe.tex
```

El primer comando regenera el CSV, la salida numérica, la tabla y la figura, y
actualiza en `index.html` los pesos elegidos. El segundo genera
`build/informe.pdf`; copiar ese archivo a `informe.pdf` antes de subir cambios en
la entrega (`cp build/informe.pdf informe.pdf` en Bash, o
`Copy-Item build/informe.pdf informe.pdf` en PowerShell).

El script también puede ejecutarse indicando su ruta desde otra carpeta. Al
cargarlo con `source("analisis.R")` solo se definen las funciones; se pueden
usar `perfil_fuente()`, `barrer_fuente()` o `generar_entrega()` por separado.
El explorador se abre localmente con `index.html`, sin servidor ni paquetes.

## Experimento y lectura de resultados

Se fija T = 6/20, n_S = 100 y previa Beta(1,1). El barrido parte de y_S = 30,
sigue 31, 29, 32, 28, …, y abarca los 55 valores de 6 a 60.
Para cada fuente se prueban φ = 0, 0.1, …, 1. La posterior se aproxima con
99 valores de θ entre 0.01 y 0.99 y 10 000 muestras, con semilla 84735.
El DIC usa exclusivamente la verosimilitud del objetivo T.

Al mover S, el explorador aplica el φ de menor DIC calculado en R. La barra de
φ permite probar otros pesos. Las curvas, las medias y los intervalos creíbles
centrales del 95 % se obtienen de la posterior Beta exacta condicionada a ese
peso; no incorporan la incertidumbre de su selección.

En esta configuración los primeros pesos nulos aparecen en S = 6 % por abajo
y S = 54 % por arriba. Estos cortes dependen de la grilla, los tamaños y el
ruido de Monte Carlo; no son umbrales generales de transferencia.

## Publicación automática

El workflow [Compilar y publicar informe](.github/workflows/publicar.yml) se
ejecuta con cada push a `main` y también se puede iniciar desde **Actions → Run
workflow**. Regenera las salidas con R, compila el PDF desde el `.tex` y publica
el explorador, el PDF recién compilado, el código R y el CSV en GitHub Pages.
Las pull requests ejecutan la compilación para validar los cambios.

En **Settings → Pages → Build and deployment**, la fuente debe ser **GitHub
Actions**. La publicación utiliza el `GITHUB_TOKEN` automático y el entorno
`github-pages`, siguiendo el [workflow de GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).
El PDF público se recompila en cada ejecución; la copia versionada se actualiza
al preparar una nueva entrega.
