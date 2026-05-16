# Avaliação de modelos de predição para ocorrência de malária no estado do Amapá, 1997-2016

> Evaluation of prediction models for the occurrence of malaria in the state of Amapá, Brazil, 1997-2016: an ecological study

Repositório com dados e scripts do artigo original publicado em **Epidemiologia e Serviços de Saúde**, vol. 30, n. 1, 2021.

**DOI:** [10.1590/S1679-49742021000100007](https://doi.org/10.1590/S1679-49742021000100007)

**Autores:** Marcos Venicius Malveira de Lima, Gabriel Zorello Laporta

---

## Resumo

Estudo ecológico de séries temporais que avaliou a capacidade preditiva de modelos estatísticos e de aprendizado de máquina para prever casos mensais de malária autóctone no estado do Amapá. Foram testados 9 modelos mais o modelo ingênuo como linha de base, em três horizontes de previsão (3, 6 e 12 meses). O desempenho foi avaliado pelo MASE (*Mean Absolute Scaled Error*).

## Estrutura do repositório

```
├── Amapá.RData          # Base de dados com casos mensais de malária (1997-2016)
├── script.R             # Script de análise original
├── Script Malaria Final Modelos + Gráficos.R   # Script final para publicação
├── pt.pdf               # Artigo publicado (português)
├── en.pdf               # Artigo publicado (inglês)
└── README.md
```

## Requisitos

O script requer **R** com os seguintes pacotes:

```r
install.packages(c("forecast", "TSA", "urca", "tseries", "ggplot2",
                   "seasonal", "tsoutliers", "expsmooth", "fma", "nnfor"))
```

## Como executar

1. Clone o repositório:
   ```bash
   git clone https://github.com/MVMLima/artigo_RESS_malaria.git
   ```
2. Abra `script.R` ou `Script Malaria Final Modelos + Gráficos.R` no R/RStudio.
3. Ajuste os caminhos de `setwd()` e `load()` para apontar para a pasta do repositório.
4. Execute o script.

## Modelos testados

| Modelo | Função R | Tipo |
|---|---|---|
| ARIMA | `auto.arima()` | Estatístico |
| ETS | `ets()` | Estatístico |
| NNETAR | `nnetar()` | Rede neural |
| TBATS | `tbats()` | Estatístico |
| BATS | `bats()` | Estatístico |
| STLM | `stlm()` | Estatístico |
| StructTS | `StructTS()` | Estatístico |
| ELM | `elm()` | Rede neural |
| MLP | `mlp()` | Rede neural |
| Naive | `naive()` | Baseline |

## Principais resultados

- O modelo **ARIMA** apresentou o melhor desempenho geral em todos os horizontes de previsão.
- Erros absolutos < 2% na escala logarítmica.
- Erros relativos 3,4 a 5,8 vezes menores que o modelo nulo (*naive*).
- Modelos determinísticos (ARIMA, ETS) superaram os modelos estocásticos (redes neurais).

## Fonte dos dados

Casos de malária autóctone notificados no Amapá, provenientes do **SISMAL** (1997-2003) e **SIVEP-Malária** (2003-2016), sistemas de vigilância do Ministério da Saúde do Brasil.

## Como citar

Lima MVM, Laporta GZ. Avaliação de modelos de predição para ocorrência de malária no estado do Amapá, 1997-2016: um estudo ecológico. *Epidemiol Serv Saude*. 2021;30(1):e2020080. doi:10.1590/S1679-49742021000100007.

## Licença

Este projeto está disponível para fins acadêmicos e de pesquisa.
