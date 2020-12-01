library(magrittr)

lista_arquivos <- fs::dir_info(path = "data-raw/petinicial/") %>%
  dplyr::pull(path)


# pdf_lido <-

lista_arquivos[1:2,] %>%
  dplyr::mutate(
    pdf = purrr::map_dfr(.x = value, .f = pdftools::pdf_text)
  )

## função pra ler o pdf


ler_pdf_inicial <- function (caminho) {

  pdf_lido <- pdftools::pdf_text(caminho)

  pdf_lido %>%
    stringr::str_c(collapse = "") %>%
    stringr::str_squish() %>%
    stringr::str_remove_all(stopwords::stopwords(language = "pt"))

}
