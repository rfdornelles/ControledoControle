 ##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)

## Aqui vamos carregar os scripts de 1 a 5 em que tenho as funções que utilizei
# não vou chamar as funões de baixar pois as rodei em separado no script 6

## Agora o objetivo é resgatar a lista de incidentes e rodar as funções de
# leitura

# Após, salvar tudo em arquivos .rds para não perder tempo no futuro
# ATENÇÃO: os comandos para salvar estão com comentários para evitar serem
# sobrescritos por engano

# Feito tudo isso estarei em condições de realizar as análises

##### Carregar as funções que criei

source("R/1-baixar_lista_processos.R", encoding = "UTF-8")
source("R/2-pegar_incidentes.R", encoding = "UTF-8")
source("R/3-pegar_dados.R", encoding = "UTF-8")
source("R/4-baixar_peticiao_inicial.R", encoding = "UTF-8")
source("R/5-ler_pdf.R", encoding = "UTF-8")
source("R/6-iterar-baixar-dados.R", encoding = "UTF-8")

##### barra de progresso mais completa
progressr::handlers(list(
  progressr::handler_progress(
    format   = ":spin :current/:total (:message) [:bar] :percent in :elapsed ETA: :eta",
    width    = 60,
    complete = "+"
  )))


#### baixar os dados

# isso foi feito no passo 6 de iteração
# aqui vou trabalhar apenas com os arquivos salvos em disco

##### ler os dados

## listar todos os casos que baixei

lista_incidentes <- readr::read_rds("data/incidentes.rds")

## ler as partes

future::plan(future::multisession())

progressr::with_progress({

  p <- progressr::progressor(nrow(lista_incidentes))

  tabela_partes <- lista_incidentes %>%
    dplyr::pull(incidente) %>%
    furrr::future_map_dfr(
      purrr::possibly(~ler_aba_partes(incidente = .x, prog = p),
                      otherwise = NULL))

  })



## ler os andamentos

future::plan(future::multisession())

progressr::with_progress({

  p <- progressr::progressor(nrow(lista_incidentes))

  tabela_andamentos <- lista_incidentes %>%
    dplyr::pull(incidente) %>%
    furrr::future_map_dfr(
      purrr::possibly(~ler_aba_andamento(incidente = .x, prog = p),
                      otherwise = NULL))

})

## ler os pdfs

future::plan(future::multisession())

progressr::with_progress({

  p <- progressr::progressor(nrow(lista_incidentes))

  tabela_peticoes <- lista_incidentes %>%
    dplyr::pull(incidente) %>%
    furrr::future_map_dfr(
      purrr::possibly(~ler_pdf_inicial(incidente = .x,
                                       prog = p), otherwise = NULL)
    )

})

## procurar palavras-chave

future::plan(future::multisession())

progressr::with_progress({

  p <- progressr::progressor(nrow(tabela_peticoes))

  tabela_palavras_chave <- tabela_peticoes %>%
    dplyr::mutate(
      palavra = furrr::future_map_chr(.x = texto_inicial,
       .f =  purrr::possibly(
         ~retornar_palavras_frequentes(texto = ., prog = p),
         otherwise = NULL))
      ) %>%
    dplyr::select(-texto_inicial)
})


#### Salvar de forma aninhada

# separar os que não estão vazios
# é razoável supor que nenhuma petição ao STF terá menos de mil
# caracteres

tabela_palavras_chave_nest <- tabela_peticoes %>%
  dplyr::filter(stringr::str_length(texto_inicial) > 1000)

future::plan(future::multisession())

progressr::with_progress({

  p <- progressr::progressor(nrow(tabela_palavras_chave_nest))

  tabela_palavras_chave_nest <- tabela_palavras_chave_nest %>%
    dplyr::mutate(
      palavra = furrr::future_map(
        .x = texto_inicial,
        .f =  purrr::possibly(
          ~retornar_palavras_frequentes(texto = ., simplifica = F,
                                        prog = p),
          otherwise = NULL))
    ) %>%
    dplyr::select(-texto_inicial)
})



## salvar

 readr::write_rds(tabela_andamentos, "data/andamentos.rds")
 readr::write_rds(tabela_partes, "data/partes.rds")
 readr::write_rds(tabela_peticoes, "data/peticoes.rds", compress = "xz")
 readr::write_rds(tabela_palavras_chave, "data/palavras-chave.rds")
 readr::write_rds(tabela_palavras_chave_nest, "data/palavra-chave-nest.rds",
 compress = "xz")



