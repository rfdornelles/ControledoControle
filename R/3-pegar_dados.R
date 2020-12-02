##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)


## As funções aqui vão servir para baixar os dados das partes e os andamentos
# e para ler os arquivos baixados

# garantir que existem as pastas

fs::dir_create("data-raw/partes/")
fs::dir_create("data-raw/andamentos/")

#### baixar_dados_processo ####
# Função que recebe o número do incidente e baixa do STF as partes e os
# andamentos

# Já colocada de forma a facilitar a iteração

baixar_dados_processo <- function (incidente, dormir = 1, naMarra = F, prog) {

# barra de progresso, para quando for iterar
  if (!missing(prog)) {
    prog()
}

# sleep para não causar
  Sys.sleep(dormir)

# preparar a querry colocando o incidente

  q_incidente <- list("incidente" = incidente)

# urls que serão buscadas
  u_partes <- "http://portal.stf.jus.br/processos/abaPartes.asp"
  u_andamentos <- "http://portal.stf.jus.br/processos/abaAndamentos.asp"

 # nomes dos futuros arquivos
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


#### ler_aba_partes ####
# Função para ler a aba de partes e retornar um formato tidy
# Vai receber o incidente e retornar uma tibble para ser empilhada

ler_aba_partes <- function (incidente, dormir = 1, naMarra = F, prog) {

# barra de progresso, para quando for iterar
  if (!missing(prog)) {
    prog()
  }

# sleep para não causar
  Sys.sleep(dormir)


# caminho do possível arquivo
caminho_partes <- paste0("data-raw/partes/Partes-", incidente, ".html")

# verificar se existe o arquivo:

if(!fs::file_exists(caminho_partes)) {
  message(paste("Arquivo inexistente - Partes do incidente", incidente))
  return()
}

# leitura propriamente dita

# primeiro o "papel" que atua (passivo, ativo, adv, promotor, etc)

partes_tipo <- caminho_partes %>%
  xml2::read_html(encoding = "UTF-8") %>%
  xml2::xml_find_all("//div[@class='detalhe-parte']") %>%
  xml2::xml_text() %>%
  stringr::str_extract("(?>[A-Z]*)")

# nome propriamente dito
# num futuro pensar em separar OAB e agrupar advs e procuradores
# da mesma parte

partes_nomes <- caminho_partes %>%
  xml2::read_html(encoding = "UTF-8") %>%
  xml2::xml_find_all("//div[@class='nome-parte']") %>%
  xml2::xml_text() %>%
  stringr::str_replace_all("&nbsp", " ") %>%
  stringr::str_squish()


# retornar o tibble
tibble::tibble(tipo = partes_tipo,
               nome = partes_nomes)

}

# # partes
#
# u_partes <- "http://portal.stf.jus.br/processos/abaPartes.asp"
#
# r_partes <- httr::GET(url = u_partes,
#                       query = q_incidente)
#


#
# # andamentos
#
# u_andamentos <- "http://portal.stf.jus.br/processos/abaAndamentos.asp"
#
# r_andamentos <- httr::GET(url = u_andamentos,
#                           query = q_incidente)
#
#
# ####
#
#
#
#
# ### teste
#
# progressr::with_progress({
#
#   p <- progressr::progressor(nrow(base_incidentes))
#
#   base_incidentes %>%
#     dplyr::pull(incidente) %>%
#     purrr::walk(., .f = baixar_dados_processo, dormir = 1, prog = p)
#
# })

