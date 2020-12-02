##### criar as funções
tictoc::tic()
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
    purrr::map_df(ler_pdf_inicial, prog = p) %>%
    dplyr::mutate(palavras_chave = retornar_palavras_frequentes(texto_inicial,))

})


## salvar

readr::write_rds(tabela_andamentos, "data/andamentos.rds")
readr::write_rds(tabela_partes, "data/partes.rds")
readr::write_rds(tabela_peticoes, "data/peticoes.rds")
tictoc::toc()
