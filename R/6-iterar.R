# definir handler da barra

progressr::handlers(list(
  progressr::handler_progress(
    format   = ":spin :current/:total (:message) [:bar] :percent in :elapsed ETA: :eta",
    width    = 60,
    complete = "+"
  ),
  progressr::handler_beepr(
    finish   = "wilhelm",
    update = 10L,
    initiate = 2L
  )
))


# baixar e ler arquivo com a lista

source('C:/Users/Conectas/Desktop/Dropbox/Meu R/Cursos/Curso-r/Web Scrap/Projetos/ControledoControle/R/1-baixar_lista_processos.R', encoding = 'UTF-8')

baixar_tabela_stf()

base_casos <- ler_tabela_stf()

# filtrar que casos quero

base_casos <- base_casos %>%
  dplyr::filter(ano >= 2018)


# pegar todos os incidentes

source('C:/Users/Conectas/Desktop/Dropbox/Meu R/Cursos/Curso-r/Web Scrap/Projetos/ControledoControle/R/2-pegar_incidentes.R', encoding = 'UTF-8')

progressr::with_progress({

  p <- progressr::progressor(nrow(base_casos))

  base_incidentes <- base_casos %>%
    dplyr::mutate(incidente =
            purrr::map2_chr(.x = classe, .y = numero,
                .f = stf_busca_incidente, prog = p)) %>%
    dplyr::select(classe, numero, incidente)

    })

# salvar resultado

readr::write_rds(base_incidentes, "data/BaseIncidentes.rds")

# ler resultado do arquivo salvo


# buscar dados dos processos (partes e andamentos)

# baixar petições iniciais

# base_incidentes <- readr::read_rds("data/base_incidentes.rds")
#
#
#
# progressr::with_progress({
#
#   p <- progressr::progressor(nrow(base_incidentes))
#
#   base_incidentes %>%
#     dplyr::pull(incidente) %>%
#     purrr::walk(., .f = ~{
#       purrr::safely(baixar_pet_inicial)(incidente = .x, prog = p)
#     })
#
# })


### checar qualidade

# tabela_erros <- fs::dir_info("data-raw/petinicial/") %>%
#   dplyr::filter(size == 0) %>%
#   dplyr::mutate(incidente = stringr::str_extract(path, "[0-9]+")) %>%
#   dplyr::select(incidente) %>%
#   dplyr::left_join(base_incidentes)

# ler petições iniciais

# salvar todos os resultados
