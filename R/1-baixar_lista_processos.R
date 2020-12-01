library(magrittr)

# autuados: "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"
# distribuídos: "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Distribuidos.xlsx"


# baixar o arquivo com os distribuídos

url_stf_distribuidos <- "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"

r_stf_distribuidos <- httr::GET(url_stf_distribuidos,
                                httr::progress(),
                                httr::write_disk("TesteSTF.xlsx",
                                                 overwrite = T))


# Tidy -------------------------------------------------------------------------

base_distribuidos <- readxl::read_excel("TesteSTF.xlsx", skip = 6,
                                        guess_max = 10000) %>%
  janitor::remove_empty(which = "cols") %>%
  janitor::clean_names() %>%
  dplyr::rename("autuacao" = data_autuacao,
                "distribuicao" = data_primeira_distribuicao,
                "polo_ativo" = partes_polos_ativos,
                "polo_passivo" = partes_polos_passivos)

base <- base_distribuidos %>%
  # dplyr::filter(indicador_de_processo_em_tramitacao != "Não") %>%
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
