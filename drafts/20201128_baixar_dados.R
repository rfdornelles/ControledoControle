#' Author:
#' Subject:

# library(tidyverse)
library(magrittr)

baixar_dados_processo <- function (incidente, dormir = 0, naMarra = F, prog) {

  # barra de progresso
  if (!missing(prog)) prog()

  # sleep para não causar
  Sys.sleep(dormir)

  # preparar a querry

  q_incidente <- list("incidente" = incidente)

  # urls que serão buscadas
  u_partes <- "http://portal.stf.jus.br/processos/abaPartes.asp"
  u_andamentos <- "http://portal.stf.jus.br/processos/abaAndamentos.asp"

  # futuros arquivos
  caminho_partes <- paste0("data-raw/partes/Partes-", incidente, ".html")

  caminho_andamentos <- paste0("data-raw/andamentos/Andamentos-", incidente,
                               ".html")

# baixar partes se não existir e se não precisar forçar

  if(!file.exists(caminho_partes) | naMarra) {
   httr::GET(url = u_partes, query = q_incidente,
             httr::write_disk(caminho_partes, overwrite = TRUE))
 }

# baixar andamentos se não existir e se não precisar forçar
  if(!file.exists(caminho_andamentos) | naMarra) {
  httr::GET(url = u_andamentos, query = q_incidente,
            httr::write_disk(caminho_andamentos, overwrite = TRUE))

}

}


### teste

progressr::with_progress({

  p <- progressr::progressor(nrow(base_incidentes))

base_incidentes %>%
  dplyr::pull(incidente) %>%
  purrr::walk(., .f = baixar_dados_processo, dormir = 1, prog = p)

})
