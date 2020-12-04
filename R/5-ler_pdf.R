##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)

## Criar função que lê a inicial já baixada e depois funções para olharmos
# as palavras chave de cada petição

ler_pdf_inicial <-  function (incidente, prog) {

# barra de progresso, se houver
  if (!missing(prog)) {
    prog()
  }

# criar o caminho do arquivo

caminho_pet <- paste0("data-raw/petinicial/PetInicial-", incidente, ".pdf")

  if(!file.exists(caminho_pet)) {
    return()
  }

# carregar pdf

  pdf_lido <- pdftools::pdf_text(caminho_pet)

# leitura e retornar tibble
  pdf_lido %>%
    stringr::str_c(collapse = "") %>%
    stringr::str_squish() %>%
    tibble::tibble("incidente" = incidente,
                   "texto_inicial" = .)
}

#### procurar palavras-chave
# referência: https://www.ufrgs.br/wiki-r/index.php?title=Frequ%C3%AAncia_das_palavras_e_nuvem_de_palavras

#### retornar_palavras_frequentes ####

# Função que retorna as X palavras mais frequentes na inicial
# útil para categorizar o assunto e criar wordclouds
# no futuro pode ajudar a fazer modelo de tópicos

retornar_palavras_frequentes <- function(texto, quantidade = 10,
                                         simplifica = TRUE, prog) {

  # barra de progresso, se houver
  if (!missing(prog)) {
    prog()
  }

  # limpar o texto

  texto_limpo <- texto %>%
    stringr::str_squish() %>% # Elimina espacos excedentes
    stringr::str_to_lower() %>% # Converte para minusculo
    abjutils::rm_accent() %>% # remover acentsos
    stringr::str_remove_all("[0-9]|º|§") %>%
    stringr::str_remove_all("\\b[a-z]{1,3}\\b") %>%  # palavras com 3 dígitos
    tm::removePunctuation() %>%
    tibble::tibble("texto" = .) # transforma em tbl

  # remover stopwords e tokenizar
  texto_limpo <- texto_limpo %>%
    tidytext::unnest_tokens(input = texto, output = "token") %>%
    dplyr::anti_join(., y = stopwords::stopwords("por") %>%
                       tibble::tibble("token" = .)) %>%
    dplyr::count(token, sort = T)


  # pra facilitar iteração retornar apenas as palavras
  if(simplifica) {

    texto_limpo %>%
      dplyr::slice_head(n = quantidade) %>%
      dplyr::pull(token) %>%
      stringr::str_c(collapse = ", ")

  } else {

    # retornar os termos no formato desejado
    texto_limpo %>%
      tidyr::nest(data = c(token, n))

  }

}





