##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

## Funções auxiliares para baixar e importar a lista de processos de controle
# concentrado do STF

library(magrittr)

##### Função baixar_tabela_stf #####

## baixar o arquivo com os processo de controle concetrado autuados até
# a presente data
## essa planilha é gerada pelo próprio STF contendo todos os procesos de
# controle concentrado (ADPF, ADC, ADO e ADI) autuados até a data em que é
# gerado

baixar_tabela_stf <- function(naMarra = FALSE) {

# url do arquivo onde fica a planilha

  url_stf_autuados <- "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"


# certificar que a pasta onde ficará armazenada existe
  if(!fs::dir_exists("data-raw/planilha-stf")) {

    fs::dir_create("data-raw/planilha-stf")

  }

# criar arquivo temporário

  tmp <- fs::file_temp(ext = ".xlsx")

# fazer a requisição, salvando em disco e com barra de progresso
  r_stf_autuados <- httr::GET(url_stf_autuados,
                              httr::write_disk(tmp, overwrite = TRUE))

# verificar a data dos dados
data_arquivo <- readxl::read_xlsx(path = tmp, range = "B6", col_names = F) %>%
  stringr::str_extract("[0-9]{1,2}\\/[0-9]{2,2}\\/[0-9]{2,4}$") %>%
  lubridate::dmy()


# salvar o caminho do arquivo que acabamos de baixar
  arquivo_baixado <- paste0("data-raw/planilha-stf/ListaAutuados-",
                         data_arquivo, ".xlsx")

# testar se já existe esse dia, a princípio não sobrescrever

if(naMarra == FALSE & fs::file_exists(arquivo_baixado)) {
    message(paste("Arquivo referente ao dia", data_arquivo, "já existente. Para sobrescrever use naMarra = TRUE"))

    } else {

# se não existir ou se naMarra for TRUE, copiar o arquivo para pasta
  fs::file_copy(path = tmp, new_path = arquivo_baixado, overwrite = TRUE)

      }

}


##### Função ler_tabela_stf #####

## ler o arquivo baixado

ler_tabela_stf <- function(data = "mais_recente") {

  if(data == "mais_recente") {

    arquivo <- fs::dir_info("data-raw/planilha-stf/") %>%
      dplyr::select(path) %>%
      dplyr::mutate(
        path = stringr::str_extract(
          path, "[0-9]{4,4}\\-[0-9]{2,2}\\-[0-9]{2,2}")) %>%
      dplyr::arrange(desc(path)) %>%
      head(1)
  }


arquivo <- paste0("data-raw/planilha-stf/", data, ".xlsx")

if(!fs::file_exists(arquivo)) {
  warning(paste("Arquivo", arquivo, "não existe."))
  return(FALSE)
}


base_distribuidos <- readxl::read_excel(arquivo, skip = 6,
                                        guess_max = 10000)


base_distribuidos <- base_distribuidos %>%
  janitor::remove_empty(which = "cols") %>%
  janitor::clean_names() %>%
  dplyr::rename("autuacao" = data_autuacao,
                "distribuicao" = data_primeira_distribuicao,
                "polo_ativo" = partes_polos_ativos,
                "polo_passivo" = partes_polos_passivos)


base_distribuidos <- base_distribuidos %>%
  dplyr::select(-link_processo, -orgao_origem, -indicador_de_processo_em_tramitacao,
                -meio_processo) %>%
  dplyr::mutate(ano = lubridate::year(autuacao),
                mes = lubridate::month(autuacao),
                dia = lubridate::day(autuacao)) %>%
  tidyr::separate(col = assuntos,
                  into = c("assunto_principal", "assunto_secundario",
                           "assunto_outros"),
                  sep = "\\|",
                  remove = FALSE,
                  extra = "merge")

base_distribuidos

}

