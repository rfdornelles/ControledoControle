##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)

## Aqui vamos carregar os scripts de 1 a 5 em que tenho as funções que utilizei
# não vou chamar as funões de baixar pois as rodei em separado no script 6

## Agora o objetivo é resgatar a lista de incidentes e rodar as funções de
# leitura

# Após, salvar tudo em arquivos .rds para não perder tempo no futuro

# Feito tudo isso estarei em condições de realizar as análises

##### criar as funções

source("R/1-baixar_lista_processos.R")
source("R/2-pegar_incidentes.R")
source("R/3-pegar_dados.R")
source("R/4-baixar_peticiao_inicial.R")
source("R/5-ler_pdf.R")

#### baixar os dados

# baixar de 2016 até 2020

##### ler os dados

## listar todos os casos que baixei
lista_incidentes <- dplyr::full_join(
  readr::read_rds("data/BaseIncidentes.rds"),
  readr::read_rds("data/BaseIncidentes2016.rds"))


## ler as partes
progressr::with_progress({

  p <- progressr::progressor(nrow(lista_incidentes))

  tabela_partes <- lista_incidentes %>%
    dplyr::pull(incidente) %>%
    purrr::map_df(ler_aba_partes, prog = p)

})


## ler os andamentos

progressr::with_progress({

  p <- progressr::progressor(nrow(lista_incidentes))

  tabela_andamentos <- lista_incidentes %>%
    dplyr::pull(incidente) %>%
    purrr::map_df(ler_aba_andamento, prog = p)

})

## ler os pdfs

progressr::with_progress({

  p <- progressr::progressor(nrow(lista_incidentes))

  tabela_peticoes <- lista_incidentes %>%
    dplyr::pull(incidente) %>%
    purrr::map_df(
      purrr::possibly(~ler_pdf_inicial(incidente = .x,
                                       prog = p), otherwise = NULL)
    )

})

## procurar palavras-chave

tabela_palavras_chave <- tabela_peticoes %>%
  dplyr::rowwise() %>%
  dplyr::mutate(palavra = retornar_palavras_frequentes(texto_inicial)) %>%
  dplyr::select(-texto_inicial)

## salvar

readr::write_rds(tabela_andamentos, "data/andamentos.rds")
readr::write_rds(tabela_partes, "data/partes.rds")
readr::write_rds(tabela_peticoes, "data/peticoes.rds", compress = "gz")
readr::write_rds(tabela_palavras_chave, "data/palavras-chave.rds")

