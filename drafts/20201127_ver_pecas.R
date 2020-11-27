#' Author:
#' Subject:

# library(tidyverse)
library(magrittr)


# Import -----------------------------------------------------------------------

incidente <- "6049993"

url_pecas <- "http://redir.stf.jus.br/estfvisualizadorpub/jsp/consultarprocessoeletronico/ConsultarProcessoEletronico.jsf"

query_pecas <- list("seqobjetoincidente" = incidente)

r_pecas <- httr::GET(url = url_pecas,
                     query = query_pecas,
                     httr::write_disk("Teste-pegar-peca.html"),
                     httr::progress())

httr::BROWSE("Teste-pegar-peca.html")

r_pecas %>%
  xml2::read_html() %>%
  xml2::xml_find_first("//table[@cellpadding = '0' and @cellspacing = '0' and @width = '205px']") %>%
  rvest::html_table(fill = TRUE)

## testar ler peça

link_petinicial <- r_pecas %>%
  xml2::read_html() %>%
  xml2::xml_find_first("//a[contains(text(), 'inicial')]") %>%
  xml2::xml_attr("href")


r_petinicial <- httr::GET(url = link_petinicial,
                          httr::write_disk("teste-inicial.pdf"),
                          httr::progress())

# Tidy -------------------------------------------------------------------------

# Visualize --------------------------------------------------------------------

# Model ------------------------------------------------------------------------

# Export -----------------------------------------------------------------------

# readr::write_rds(d, "")
