# library(tidyverse)
library(magrittr)

base_incidentes <- readr::read_rds("data/base_incidentes.rds")

baixar_pet_inicial <- function (incidente, dormir = 1, naMarra = F, prog) {

  # barra de progresso
  if (!missing(prog)) prog()

  # caminho do arquivo

  caminho_pet <- paste0("data-raw/petinicial/", incidente, ".pdf")

  if(file.exists(caminho_pet) & naMarra == F) {
    return(NULL)
  }

  # sleep para não causar
  Sys.sleep(dormir)

  # preparar a querry

  query_pecas <- list("seqobjetoincidente" = incidente)

  # url do visualizador

  url_pecas <- "http://redir.stf.jus.br/estfvisualizadorpub/jsp/consultarprocessoeletronico/ConsultarProcessoEletronico.jsf"

  # fazer a busca pelo link da inicial

  link_petinicial <- httr::GET(url = url_pecas,
                               query = query_pecas) %>%
    xml2::read_html() %>%
    xml2::xml_find_first("//a[contains(text(), 'nicial')]") %>%
    xml2::xml_attr("href")

  # em caso de erro, pegar o primeiro item

  if(is.na(link_petinicial)) {

    link_petinicial <- httr::GET(url = url_pecas,
                                 query = query_pecas) %>%
      xml2::read_html() %>%
      xml2::xml_find_first("//a[@onclick = 'atribuirLink(this);']") %>%
      xml2::xml_attr("href")

    warning(paste("O incidente", incidente, "retornou erro e buscamos a primeira petição"))
  }

  # baixar petição inicial

  httr::GET(url = link_petinicial,
            httr::write_disk(caminho_pet, T))

}

progressr::handlers(list(
  progressr::handler_progress(
    format   = ":spin :current/:total (:message) [:bar] :percent in :elapsed ETA: :eta",
    width    = 60,
    complete = "+"
  ),
  progressr::handler_beepr(
    finish   = "wilhelm",
    update = 10L,
    initiate = 2L
  )
))

progressr::with_progress({

  p <- progressr::progressor(nrow(base_incidentes))

  base_incidentes %>%
    dplyr::pull(incidente) %>%
    purrr::walk(., .f = ~{
      purrr::safely(baixar_pet_inicial)(incidente = .x, prog = p)
    })

})


### checar qualidade

tabela_erros <- fs::dir_info("data-raw/petinicial/") %>%
  dplyr::filter(size == 0) %>%
  dplyr::mutate(incidente = stringr::str_extract(path, "[0-9]+")) %>%
  dplyr::select(incidente) %>%
  dplyr::left_join(base_incidentes)
