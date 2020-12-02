##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)

## Criar função que lê a inicial já baixada e depois funções para olharmos
# as palavras chave de cada petição

ler_pdf_inicial <-  function (incidente, dormir = 1, prog) {

# barra de progresso, se houver
  if (!missing(prog)) {
    prog()
  }

# criar o caminho do arquivo

caminho_pet <- paste0("data-raw/petinicial/PetInicial-", incidente, ".pdf")

  if(!file.exists(caminho_pet)) {
    return()
  }

# sleep para não causar
Sys.sleep(dormir)

  pdf_lido <- pdftools::pdf_text(caminho_pet)

  pdf_lido %>%
    stringr::str_c(collapse = "") %>%
    stringr::str_squish()
}

#### procurar palavras-chave
# referência: https://www.ufrgs.br/wiki-r/index.php?title=Frequ%C3%AAncia_das_palavras_e_nuvem_de_palavras

# estabelece as stopwords
palavras_comuns <- c("art", "lei", "stf", "corte", "pgr", "º",
                     "rj", "min", "ministro", "ministra", "tcm",
                    "nao", "federal") %>%
  tibble::tibble("word" = .) %>%
  dplyr::full_join(., tidytext::get_stopwords("pt"))


#### retornar_palavras_frequentes ####

# Função que retorna as X palavras mais frequentes na inicial
# útil para categorizar o assunto e criar wordclouds
# no futuro pode ajudar a fazer modelo de tópicos

retornar_palavras_frequentes <- function(texto, quantidade = 10,
                                         simplifica = TRUE) {

  # limpar o texto

  texto_limpo <-  texto %>%
    abjutils::rm_accent() %>% # remover acentsos
    stringr::str_squish() %>% # Elimina espacos excedentes
    stringr::str_to_lower() %>% # Converte para minusculo
    tibble::tibble("texto" = .) # transforma em tbl

  texto_limpo <- texto_limpo %>%
    tidytext::unnest_tokens(input = texto, output = "token") %>%
    dplyr::anti_join(., y = palavras_comuns,
                     by = c("token" = "word")) %>%
    dplyr::count(token, sort = T) %>%
    dplyr::slice_head(n = quantidade)

  # pra facilitar iteração retornar apenas as palavras
  if(!simplifica) {

    texto_limpo <- texto_limpo %>%
      dplyr::pull(token)

  }

# retornar os termos no formato desejado
  texto_limpo

}







