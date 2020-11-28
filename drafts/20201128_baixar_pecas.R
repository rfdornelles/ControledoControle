#' Author:
#' Subject:

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
  xml2::xml_find_first("//a[contains(text(), 'inicial')]") %>%
  xml2::xml_attr("href")

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
    interval = 2.0
  )
))

progressr::with_progress({

  p <- progressr::progressor(nrow(base_incidentes))

  base_incidentes %>%
    dplyr::pull(incidente) %>%
    purrr::walk(., .f = ~{
      purrr::possibly(baixar_pet_inicial, NULL)(incidente = .x, prog = p)
  })

})



