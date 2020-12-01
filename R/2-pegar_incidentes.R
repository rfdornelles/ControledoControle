library(magrittr)

# Import -----------------------------------------------------------------------

u_stf_listar <- "http://portal.stf.jus.br/processos/listarProcessos.asp"

classe <- "ADPF"
numero <- "760"

q_stf_listar <- list("classe" = classe,
                     "numeroProcesso" = numero)

r_stf_listar <- httr::GET(u_stf_listar,
                          query = q_stf_listar,
                          httr::write_disk("Teste_listar_ADPF.html", T))

# identificar o incidente, vou precisar pra tudo

incidente <- r_stf_listar$url %>%
  stringr::str_extract("[0-9]+$")

q_incidente <- list("incidente" = incidente)

###

library(magrittr)

stf_busca_incidente <- function (classe, numero, dorme = 0, prog) {

  if (!missing(prog)) prog()

  Sys.sleep(dorme)

  u_stf_listar <- "http://portal.stf.jus.br/processos/listarProcessos.asp"

  q_stf_listar <- list("classe" = classe,
                       "numeroProcesso" = numero)

  r_stf_listar <- httr::GET(u_stf_listar,
                            query = q_stf_listar)

  r_stf_listar$url %>%
    stringr::str_extract("[0-9]+$")

}

base_teste <- casos_interesse %>% head()

progressr::with_progress({

  p <- progressr::progressor(nrow(base_teste))

  base_teste %>%
    dplyr::mutate(incidente =
                    purrr::map2_chr(.x = classe, .y = numero,
                                    .f = stf_busca_incidente, dorme = 1, prog = p)) %>%
    dplyr::select(classe, numero, incidente)

})

