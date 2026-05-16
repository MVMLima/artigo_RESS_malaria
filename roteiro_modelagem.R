###############################################################################
#  Roteiro de Modelagem Preditiva para Séries Temporais
#  ----------------------------------------------------
#  Script generalizável para avaliação e comparação de modelos de previsão
#  em séries temporais com múltiplos horizontes de predição.
#
#  Referência:
#  Lima MVM, Laporta GZ. Avaliação de modelos de predição para ocorrência de
#  malária no estado do Amapá, 1997-2016. Epidemiol Serv Saude. 2021;30(1).
#  DOI: 10.1590/S1679-49742021000100007
#
#  Como usar:
#  1. Ajuste as variáveis na seção "CONFIGURAÇÃO" com os dados do seu projeto.
#  2. Execute o script por completo (Ctrl+A, Ctrl+Enter no RStudio).
#  3. Os resultados (acurácia + gráfico) serão gerados automaticamente.
###############################################################################

# ===========================================================================
# 1. INSTALAÇÃO E CARREGAMENTO DE PACOTES
# ===========================================================================
# Execute esta seção apenas na primeira vez para instalar os pacotes.
# Depois, mantenha apenas library() para carregá-los.

pacotes_necessarios <- c(
  "forecast", "TSA", "urca", "tseries", "ggplot2",
  "seasonal", "tsoutliers", "expsmooth", "fma", "nnfor"
)

pacotes_faltantes <- pacotes_necessarios[!(pacotes_necessarios %in% installed.packages()[,"Package"])]
if (length(pacotes_faltantes) > 0) {
  install.packages(pacotes_faltantes)
}

invisible(lapply(pacotes_necessarios, library, character.only = TRUE))

# ===========================================================================
# 2. CONFIGURAÇÃO (ALTERE ESTA SEÇÃO COM SEUS DADOS)
# ===========================================================================

# ---- 2a. Carregar seus dados ----
# Substitua pelo caminho do seu arquivo .RData, .csv, etc.
# Seu dataframe deve conter ao menos uma coluna numérica com a série temporal.
# Exemplo: load("meus_dados.RData")

load("Amapá.RData")                         # Altere para seu arquivo

# ---- 2b. Definir a coluna da série temporal ----
# Substitua "malaria$AP" pela sua coluna de interesse.
# Exemplo: dados$casos, dados$vendas, etc.

dados_brutos <- malaria$AP                  # Altere para seus dados

# ---- 2c. Definir frequência da série ----
# 12 = mensal, 4 = trimestral, 7 = diário, 52 = semanal, 1 = anual
frequencia <- 12

# ---- 2d. Definir data de início ----
# Formato: c(ano, mês/trimestre/dia)
data_inicio <- c(1997, 1)

# ---- 2e. Definir fim do período de treino ----
# Formato: c(ano, unidade). O restante será reservado para teste.
data_fim_treino <- c(2015, 12)

# ---- 2f. Definir horizontes de previsão ----
# Número de períodos à frente para prever.
horizontes <- c(12, 6, 3)

# ---- 2g. Definir transformação dos dados ----
# "log" = transformação logarítmica, "none" = sem transformação
transformacao <- "log"

# ---- 2h. Definir semente para reprodutibilidade ----
semente <- 123

# ---- 2i. Nome do arquivo de saída do gráfico ----
arquivo_saida <- "previsao_serie_temporal.png"

# ---- 2j. Configurações dos modelos ----
parametros <- list(
  nnetar_p = 12,           # Número de lags para rede neural
  nnetar_size = 25,        # Número de neurônios na camada oculta
  stl_window = 12,         # Janela sazonal para decomposição STL
  periodos_sazonais = 12   # Períodos sazonais para TBATS/BATS
)

# ===========================================================================
# 3. PREPARAÇÃO DAS SÉRIES TEMPORAIS
# ===========================================================================
cat("\n====================================\n")
cat("  PREPARANDO SÉRIES TEMPORAIS\n")
cat("====================================\n\n")

# Aplica transformação se solicitado
dados_transformados <- switch(
  transformacao,
  "log" = log(dados_brutos),
  "none" = dados_brutos,
  stop("transformacao deve ser 'log' ou 'none'")
)

# Listas para armazenar resultados de cada horizonte
todos_modelos <- list()
todas_previsoes <- list()
todas_acuracias <- list()
todos_testes <- list()

for (h in horizontes) {
  set.seed(semente)

  # Cria série temporal completa
  serie_completa <- ts(dados_transformados, start = data_inicio, frequency = frequencia)

  # Calcula data de início do período de teste
  n_total <- length(serie_completa)
  data_inicio_teste <- time(serie_completa)[n_total - h + 1]
  ano_teste <- floor(data_inicio_teste)
  mes_teste <- round((data_inicio_teste - ano_teste) * frequencia) + 1

  # Divide em treino e teste
  teste <- window(serie_completa, start = c(ano_teste, mes_teste))
  treino <- window(serie_completa, end = time(serie_completa)[n_total - h])

  todos_testes[[as.character(h)]] <- teste

  # ===========================================================================
  # 4. MODELAGEM
  # ===========================================================================
  cat("Ajustando modelos para horizonte h =", h, "...\n")

  modelos <- list(
    mod_arima  = auto.arima(treino, ic = "aicc", stepwise = FALSE),
    mod_exp    = ets(treino, ic = "aicc", restrict = FALSE),
    mod_neural = nnetar(treino, p = parametros$nnetar_p, size = parametros$nnetar_size),
    mod_tbats  = tbats(treino, ic = "aicc", seasonal.periods = parametros$periodos_sazonais),
    mod_bats   = bats(treino, ic = "aicc", seasonal.periods = parametros$periodos_sazonais),
    mod_stl    = stlm(treino, s.window = parametros$stl_window, ic = "aicc", robust = TRUE, method = "ets"),
    mod_sts    = StructTS(treino),
    mod_elm    = elm(treino),
    mod_mlp    = mlp(treino)
  )

  # Gera previsões para todos os modelos
  previsoes <- lapply(modelos, forecast, h)
  previsoes$naive <- naive(treino, h)

  # ===========================================================================
  # 5. AVALIAÇÃO DE ACURÁCIA (MASE)
  # ===========================================================================
  acuracia <- lapply(previsoes, function(f) {
    accuracy(f, teste)[2, , drop = FALSE]
  })
  acuracia <- Reduce(rbind, acuracia)
  row.names(acuracia) <- names(previsoes)
  acuracia <- acuracia[order(acuracia[, "MASE"]), ]

  todos_modelos[[as.character(h)]] <- modelos
  todas_previsoes[[as.character(h)]] <- previsoes
  todas_acuracias[[as.character(h)]] <- round(acuracia, 2)
}

# ===========================================================================
# 6. RESULTADOS
# ===========================================================================
cat("\n====================================\n")
cat("  RESULTADOS DE ACURÁCIA (MASE)\n")
cat("====================================\n")

for (h in horizons) {
  cat("\n--- Horizonte de previsão: h =", h, "---\n")
  print(todas_acuracias[[as.character(h)]])
}

# Identifica os melhores modelos por horizonte
cat("\n====================================\n")
cat("  MELHORES MODELOS POR HORIZONTE\n")
cat("====================================\n\n")

for (h in horizons) {
  melhor <- rownames(todas_acuracias[[as.character(h)]])[1]
  mase_valor <- todas_acuracias[[as.character(h)]][1, "MASE"]
  cat(sprintf("h = %2d  |  Melhor modelo: %-10s  |  MASE = %.2f\n", h, melhor, mase_valor))
}

# ===========================================================================
# 7. GRÁFICO DE PREVISÕES
# ===========================================================================

# Define rótulos dos modelos para legenda
rotulos_modelos <- c(
  "mod_arima" = "ARIMA", "mod_exp" = "ETS", "mod_neural" = "NNETAR",
  "mod_tbats" = "TBATS", "mod_bats" = "BATS", "mod_stl" = "STLM",
  "mod_sts" = "StructTS", "mod_elm" = "ELM", "mod_mlp" = "MLP",
  "naive" = "Naive"
)

# Cores e estilos de linha
n_modelos <- 10
cores <- gray(seq(0, 1, length.out = n_modelos + 1))
estilos <- c(2, 3, 4, 5, 6, 7, 8, 9, 10, 11)

# Função auxiliar: extrai fitted + previsão para um modelo
extrair_serie_ajustada <- function(previsao, modelo_nome) {
  c(previsao[["fitted"]], previsao[["mean"]])
}

# Identifica dados reais (últimos registros)
serie_real <- ts(dados_transformados, start = data_inicio, frequency = frequencia)
ultimo_indice <- length(dados_transformados)

cat("\nGerando gráfico de previsões em:", arquivo_saida, "\n")

png(arquivo_saida, units = "mm", height = 170, width = 170, res = 600)
par(mar = c(4, 4, 2.2, 0.1))
par(mfrow = c(2, 2))

# Obtém o ano final para os rótulos do eixo X
ano_final <- floor(time(serie_real)[ultimo_indice])
titulo_eixo <- sprintf("%d (mês)", ano_final)

letras_paineis <- c("A", "B", "C")

# Painéis para cada horizonte
for (i in seq_along(horizontes)) {
  h <- horizontes[i]
  previsoes_h <- todas_previsoes[[as.character(h)]]

  # Índices do período de teste
  idx_inicio_teste <- ultimo_indice - h + 1
  idx_teste <- idx_inicio_teste:ultimo_indice
  st <- 1:h

  # Limites do eixo Y
  y_min <- min(serie_real[idx_teste]) - 0.5
  y_max <- max(serie_real[idx_teste]) + 0.5

  # Plot dos dados reais
  plot(st, serie_real[idx_teste],
       type = "l", lwd = 2,
       ylim = c(y_min, y_max),
       ylab = if (i %% 2 == 1 || i == length(horizontes)) "Valores (log-n)" else "",
       xlab = titulo_eixo,
       main = letras_paineis[i])

  # Sobrepor previsões de cada modelo
  nomes_modelos <- names(previsoes_h)
  for (j in seq_along(nomes_modelos)) {
    modelo_nome <- nomes_modelos[j]
    serie_ajustada <- extrair_serie_ajustada(previsoes_h, modelo_nome)
    pontos_previstos <- serie_ajustada[idx_teste]
    if (length(pontos_previstos) == h) {
      points(st, pontos_previstos,
             type = "l", lwd = 2,
             col = cores[j], lty = estilos[j])
    }
  }
}

# Painel da legenda
plot(1:12, rep(0, 12), type = "n", axes = FALSE, ann = FALSE)
nomes_legenda <- names(todas_previsoes[[as.character(horizontes[1])]])
rotulos_legenda <- rotulos_modelos[nomes_legenda]
legend(1, 0,
       legend = c("Real", rotulos_legenda),
       lty = c(1, estilos[seq_along(nomes_legenda)]),
       col = c(1, cores[seq_along(nomes_legenda)]),
       lwd = 2, bty = "n")

cat("Gráfico salvo com sucesso!\n\n")

dev.off()

cat("========================================\n")
cat("  ANÁLISE CONCLUÍDA COM SUCESSO!\n")
cat("========================================\n")
