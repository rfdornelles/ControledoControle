##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)

# criar a pasta
fs::dir_create("data-raw/petinicial/")


## Função para baixar a petição inicial - um arquivo em PDF - para cada
# incidente

baixar_pet_inicial <- function (incidente, dormir = 0, naMarra = F, prog) {

# barra de progresso, se houver
if (!missing(prog)) {
    prog()
}

# criar o caminho do arquivo e já pular se existir

caminho_pet <- paste0("data-raw/petinicial/PetInicial-", incidente, ".pdf")

  if(file.exists(caminho_pet) & naMarra == F) {
    return()
  }

# sleep para não causar
  Sys.sleep(dormir)

# preparar a querry

 query_pecas <- list("seqobjetoincidente" = incidente)

# url do visualizador de documentos do STF

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

    message(paste("O incidente", incidente, "retornou erro e buscamos a primeira petição"))
  }

# baixar petição inicial propriamente dita

  httr::GET(url = link_petinicial,
            httr::write_disk(caminho_pet, overwrite = T),
            httr::progress())

}


