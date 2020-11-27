#' Author:
#' Subject:

# library(tidyverse)
library(magrittr)

# Import -----------------------------------------------------------------------

# autuados: "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"
# distribuídos: "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Distribuidos.xlsx"


# baixar o arquivo com os distribuídos

url_stf_distribuidos <- "http://www.stf.jus.br/arquivo/cms/publicacaoBOInternet/anexo/estatistica/ControleConcentradoGeral/Lista_Autuados.xlsx"

r_stf_distribuidos <- httr::GET(url_stf_distribuidos, httr::progress(),
                                httr::write_disk("TesteSTF.xlsx"), TRUE)

base_distribuidos <- readxl::read_excel("TesteSTF.xlsx", skip = 6,
                                        guess_max = 10000) %>%
  janitor::remove_empty(which = "cols") %>%
  janitor::clean_names() %>%
  dplyr::rename("autuacao" = data_autuacao,
                "distribuicao" = data_primeira_distribuicao,
                "polo_ativo" = partes_polos_ativos,
                "polo_passivo" = partes_polos_passivos)


# Tidy -------------------------------------------------------------------------

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

# análise exploratória
base %>%
  dplyr::group_by(polo_ativo) %>%
  dplyr::count() %>%
  dplyr::arrange(-n) %>% View()

base %>%
  dplyr::group_by(polo_passivo) %>%
  dplyr::count() %>%
  dplyr::arrange(-n) %>% View()

base %>%
  dplyr::group_by(ano) %>%
  dplyr::count() %>%
  ggplot2::ggplot() +
  ggplot2::geom_line(ggplot2::aes(y = n, x = ano))

base %>%
  dplyr::group_by(ano, mes, dia) %>%
  dplyr::count() %>%
  dplyr::arrange(-n)

base %>%
  dplyr::filter(ano == 2013, mes == 6, dia == 17) %>%
  View()

## categorizar polos
## assuntos mais frequentes

base %>%
  dplyr::group_by(assuntos) %>%
  dplyr::count() %>%
  dplyr::arrange(-n)

base %>%
  dplyr::group_by(ramo_direito_novo) %>%
  dplyr::count() %>%
  dplyr::arrange(-n)


# Visualize --------------------------------------------------------------------

# Model ------------------------------------------------------------------------

# Export -----------------------------------------------------------------------

# readr::write_rds(d, "")
