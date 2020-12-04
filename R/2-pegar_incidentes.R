##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

## Função auxiliar para obter o número de incidente de cada caso que irei
# utilizar

library(magrittr)


stf_busca_incidente <- function (classe, numero, dorme = 0, prog) {

# se a barra de progresso for informada, chamar a função
  if (!missing(prog)) {
    prog()

  }

# dormir X segundos para não sobrecarregar o Tribunal
  Sys.sleep(dorme)

# url da busca de processos do STF
  u_stf_listar <- "http://portal.stf.jus.br/processos/listarProcessos.asp"

# query que busca classe e numero
  q_stf_listar <- list("classe" = classe,
                       "numeroProcesso" = numero)

# requisição. não vou salvar pois não me interessa manter esse arquivo
  r_stf_listar <- httr::GET(u_stf_listar,
                            query = q_stf_listar)


# vou buscar na resposta o URL para o qual fui redirecionado, ele conterá
# o numero do incidente na query
# retornar os números existentes ao final da expressão, que vai con

  r_stf_listar$url %>%
         stringr::str_extract("(?<=\\?incidente\\=)[0-9]+$")

}

