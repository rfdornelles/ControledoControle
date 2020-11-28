#' Author:
#' Subject:

# library(tidyverse)
library(magrittr)

### baixar lista de ações

caminho_planilha_STF <- "data-raw/PlanilhaSTF/STF-PlanilhaAutuados.xlsx"


baixar_planilha_concentrados <- function () {

  url_stf_distribuidos <- "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"

  r_stf_distribuidos <- httr::GET(url_stf_distribuidos,
                                  httr::progress(),
                                  httr::write_disk(caminho_planilha_STF,
                                                   overwrite = T))
 }

# saber qual versão da planilha de casos eu tenho


if (file.exists(caminho_planilha_STF)) {

    data_planilha_STF <- readxl::read_excel(
    path = caminho_planilha_STF,
    range = "B6", col_names = FALSE) %>%
    as.character() %>%
    stringr::str_extract(pattern = "[0-9]{2,2}\\/[0-9]{2,2}\\/[0-9]{2,4}") %>%
    lubridate::dmy()

} else {
  data_planilha_STF <- Sys.Date()
  baixar_planilha_concentrados()
}

if (data_planilha_STF < lubridate::ymd(Sys.Date())) {

  baixar_planilha_concentrados()
}


### filtrar as ativas ou apenas de 2020, ou apenas covid, sei la

base_distribuidos <- readxl::read_excel(caminho_planilha_STF, skip = 6,
                                        guess_max = 10000) %>%
  janitor::remove_empty(which = "cols") %>%
  janitor::clean_names() %>%
  dplyr::rename("autuacao" = data_autuacao,
                "distribuicao" = data_primeira_distribuicao,
                "polo_ativo" = partes_polos_ativos,
                "polo_passivo" = partes_polos_passivos) %>%
  # dplyr::filter(indicador_de_processo_em_tramitacao != "Não") %>%
  dplyr::select(-link_processo, -orgao_origem, -indicador_de_processo_em_tramitacao,
                -meio_processo) %>%
  dplyr::mutate(ano = lubridate::year(autuacao),
                mes = lubridate::month(autuacao),
                dia = lubridate::day(autuacao))

### selecionar os que me interessam

casos_interesse <- base_distribuidos %>%
  dplyr::filter(ano == 2020)

### função auxiliar para pegar o incidente

stf_busca_incidente <- function (classe, numero) {

u_stf_listar <- "http://portal.stf.jus.br/processos/listarProcessos.asp"

q_stf_listar <- list("classe" = classe,
                       "numeroProcesso" = numero)

r_stf_listar <- httr::GET(u_stf_listar,
                            query = q_stf_listar)

r_stf_listar$url %>%
    stringr::str_extract("[0-9]+$")

}

### iterar para buscar incidentes

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

progressr::with_progress({

  p <- progressr::progressor(nrow(casos_interesse))

base_incidentes <- casos_interesse %>%
    dplyr::mutate(incidente =
                    purrr::map2_chr(.x = classe, .y = numero,
                                    .f = stf_busca_incidente, dorme = 1, prog = p)) %>%
    dplyr::select(classe, numero, incidente)

})

### salvar incidentes

#readr::write_rds(base_incidentes, file = "data/base_incidentes.rds")

base_incidentes <- readr::read_rds(file = "data/base_incidentes.rds")

### função para obter os dados dos processos



### iterar com a lista dos filtrados

### função para baixar as petições iniciais

### iterar as iniciais

### controle de erros

### barra de processos

### log
