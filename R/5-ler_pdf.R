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

  pdf_lido <- pdf_lido %>%
    stringr::str_c(collapse = "") %>%
    stringr::str_squish()

}

#### procurar palavras-chave
# referência: https://www.ufrgs.br/wiki-r/index.php?title=Frequ%C3%AAncia_das_palavras_e_nuvem_de_palavras
