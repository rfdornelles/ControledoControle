#' Author:
#' Subject:

# library(tidyverse)
library(magrittr)

# Import -----------------------------------------------------------------------

u_stf_listar <- "http://portal.stf.jus.br/processos/listarProcessos.asp"

classe <- "ADPF"
numero <- "760"

q_stf_listar <- list("classe" = classe,
                     "numeroProcesso" = numero)

r_stf_listar <- httr::GET(u_stf_listar,
                          query = q_stf_listar,
                          httr::write_disk("Teste_listar_ADPF.html"))

# identificar o incidente, vou precisar pra tudo

incidente <- r_stf_listar$url %>%
  stringr::str_extract("[0-9]+$")

q_incidente <- list("incidente" = incidente)

# partes

u_partes <- "http://portal.stf.jus.br/processos/abaPartes.asp"

r_partes <- httr::GET(url = u_partes,
                      query = q_incidente)

partes_tipo <- r_partes %>%
  xml2::read_html() %>%
  xml2::xml_find_all("//div[@class='detalhe-parte']") %>%
  xml2::xml_text() %>%
  stringr::str_extract("(?>[A-Z]*)")

partes_nomes <- r_partes %>%
  xml2::read_html() %>%
  xml2::xml_find_all("//div[@class='nome-parte']") %>%
  xml2::xml_text() %>%
  stringr::str_replace_all("&nbsp", " ") %>%
  stringr::str_squish()


partes <- tibble::tibble(tipo = partes_tipo,
                        nome = partes_nomes)


# andamentos

u_andamentos <- "http://portal.stf.jus.br/processos/abaAndamentos.asp"

r_andamentos <- httr::GET(url = u_andamentos,
                          query = q_incidente)

## ver peças



# Tidy -------------------------------------------------------------------------

# Visualize --------------------------------------------------------------------

# Model ------------------------------------------------------------------------

# Export -----------------------------------------------------------------------

# readr::write_rds(d, "")
