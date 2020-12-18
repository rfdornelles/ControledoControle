

#' Baixar tabelas STF
#'
#' @param naMarra se TRUE, sobrescreve arquivo baixado. Por padr\u00e3o, \u00e9 FALSE.
#'
#' @return caminho para o arquivo baixado
#' @export
#'
baixar_tabela_stf <- function(naMarra = FALSE) {

  # url do arquivo onde fica a planilha
  url_stf_autuados <- "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"

  # certificar que a pasta onde ficar\u00e1 armazenada existe
  if(!fs::dir_exists("data-raw/planilha-stf")) {
    fs::dir_create("data-raw/planilha-stf")
  }

  # criar arquivo tempor\u00e1rio
  tmp <- fs::file_temp(ext = ".xlsx")

  # fazer a requisi\u00e7\u00e3o, salvando em disco e com barra de progresso
  r_stf_autuados <- httr::GET(url_stf_autuados,
                              httr::write_disk(tmp, overwrite = TRUE))

  # verificar a data dos dados
  data_arquivo <- readxl::read_xlsx(path = tmp, range = "B6", col_names = F) %>%
    stringr::str_extract("[0-9]{1,2}\\/[0-9]{2,2}\\/[0-9]{2,4}$") %>%
    lubridate::dmy()

  # salvar o caminho do arquivo que acabamos de baixar
  arquivo_baixado <- paste0("data-raw/planilha-stf/ListaAutuados-",
                            data_arquivo, ".xlsx")

  # testar se j\u00e1 existe esse dia, a princ\u00edpio n\u00e3o sobrescrever

  if(naMarra == FALSE & fs::file_exists(arquivo_baixado)) {
    message(paste("Arquivo referente ao dia", data_arquivo, "j\u00e1 existente. Para sobrescrever use naMarra = TRUE"))

  } else {

    # se n\u00e3o existir ou se naMarra for TRUE, copiar o arquivo para pasta
    fs::file_copy(path = tmp, new_path = arquivo_baixado, overwrite = TRUE)
  }

  return(arquivo_baixado)
}


#' Ler tabela STF
#'
#' @param data data em formato AAAA-MM-DD. Por padr\u00e3o, \u00e9 "mais_recente".
#'
#' @return tibble com processos distribu\u00eddos
#' @export
#'
ler_tabela_stf <- function(data = "mais_recente") {

  # verificar qual \u00e9 o arquivo mais novo
  if(data == "mais_recente") {

    data <- fs::dir_info("data-raw/planilha-stf/",
                         regexp = "[.]xlsx$") %>%
      dplyr::select(path) %>%
      dplyr::mutate(
        path = stringr::str_extract(
          path, "[0-9]{4,4}\\-[0-9]{2,2}\\-[0-9]{2,2}")) %>%
      dplyr::arrange(dplyr::desc(path)) %>%
      utils::head(1)
  }

  # montar o arquivo mais recente
  arquivo <- paste0("data-raw/planilha-stf/ListaAutuados-", data, ".xlsx")

  # verificar se o arquivo existe
  if(!fs::file_exists(arquivo)) {
    warning(paste("Arquivo", arquivo, "n\u00e3o existe."))
    return(FALSE)
  }

  # ler o arquivo
  base_distribuidos <- readxl::read_excel(arquivo, skip = 6,
                                          guess_max = 10000)

  # limpar nomes e tirar colunas in\u00fateis

  base_distribuidos <- base_distribuidos %>%
    janitor::remove_empty(which = "cols") %>%
    janitor::clean_names() %>%
    dplyr::rename("autuacao" = data_autuacao,
                  "distribuicao" = data_primeira_distribuicao,
                  "polo_ativo" = partes_polos_ativos,
                  "polo_passivo" = partes_polos_passivos,
                  "tramitando" = indicador_de_processo_em_tramitacao)

  # continuar a limpeza das colunas tirando as colunas in\u00fateis e
  # fazer a separa\u00e7\u00e3o da data e dos assuntos
  # Isso tornar\u00e1 mais f\u00e1cil a manipula\u00e7\u00e3o

  base_distribuidos <- base_distribuidos %>%
    dplyr::select(-link_processo, -orgao_origem,
                  -meio_processo, -data_do_ultimo_andamento,
                  -ultimo_andamento) %>%
    dplyr::mutate(ano = lubridate::year(autuacao),
                  mes = lubridate::month(autuacao),
                  dia = lubridate::day(autuacao)) %>%
    tidyr::separate(col = assuntos,
                    into = c("assunto_principal", "assunto_secundario",
                             "assunto_outros"),
                    sep = "\\|",
                    remove = FALSE,
                    extra = "merge")

  # retornar a base para uso em outra fun\u00e7\u00e3o
  base_distribuidos
}

