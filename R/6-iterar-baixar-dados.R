##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

library(magrittr)

## Aqui vou chamar e iterar as funções de baixar dados de todos os processos

## Vou salvar uma lista de incidentes com os dados básicos(ação/numero) com o
# respectivo incidente (que é a forma como o STF guarda as informações)

## Vou requisitar do STF e salvar em disco:
# - os números de incidente
# - os dados de partes (salvar em .html)
# - os andamentos (salvar em .html)
# - a petição inicial de cada processo (salvar em .pdf)


### definir handler da barra

progressr::handlers(list(
  progressr::handler_progress(
    format   = ":spin :current/:total (:message) [:bar] :percent in :elapsed ETA: :eta",
    width    = 60,
    complete = "+"
  )))

######## Etapa 1 - pegar todos os incidentes ########

### baixar e ler arquivo com a lista de casos que tenho

source('R/1-baixar_lista_processos.R', encoding = 'UTF-8')

# baixar a tabela dos casos do STF
baixar_tabela_stf()

# ler a tabela, salvando apenas classe e número (o resto não preciso agora)
base_casos <- ler_tabela_stf() %>%
  dplyr::filter(ano < 2021) %>%  # acrescentar limite até 2020
  dplyr::select(classe, numero)

### verificar os incidentes que já tenho e remover os antigos
# a ideia é ficar só com os novos

if(fs::file_exists("data/incidentes.rds")) {

  base_casos <- base_casos %>%
    dplyr::anti_join(readr::read_rds("data/incidentes.rds"))
}

### carregar funções pra ler o incidente
source('R/2-pegar_incidentes.R', encoding = 'UTF-8')

###  verificar se tenho novos casos
# se não, não faz nada e apenas carrega a base já disponível em disco

if(nrow(base_casos) >= 1) {

  future::plan(future::multisession())

  progressr::with_progress({

    p <- progressr::progressor(nrow(base_casos))

    novos_incidentes <- base_casos %>%
      dplyr::mutate(incidente =
                      furrr::future_map2_chr(.x = classe, .y = numero,
                                             .f = stf_busca_incidente, prog = p)) %>%
      dplyr::select(classe, numero, incidente)

  })


### salvar resultado dos incidentes com os novos
  base_incidentes <- readr::read_rds("data/incidentes.rds") %>%
    dplyr::bind_rows(novos_incidentes)

  readr::write_rds(base_incidentes, "data/incidentes.rds")

} else {

  # se não tiver novos, apenas ler a base que tenho
  base_incidentes <- readr::read_rds("data/incidentes.rds")
}

###### Etapa 2: Baixar partes e andamentos #####

### carregar as funções
# obs: ela "pula" os arquivos já lidos, por isso não há problemas
# em rodar de novo para a base inteira

source(file = "R/3-pegar_dados.R", encoding = "UTF-8")

# preparar paralelo
future::plan(future::multisession())

# barra de progresso
progressr::with_progress({

  p <- progressr::progressor(nrow(base_incidentes))

### rodar a função pra baixar tudo

  furrr::future_walk(
    .x =base_incidentes$incidente,
    .f = ~{
      purrr::safely(baixar_dados_processo)(incidente = .x, prog = p)
    })

})


#### Baixar petições iniciais #####

# carregar funções
source(file = "R/4-baixar_peticiao_inicial.R", encoding = "UTF-8")

# preparar paralelo
future::plan(future::multisession())

# barra de progresso

progressr::with_progress({

  p <- progressr::progressor(nrow(base_incidentes))

  purrr::walk(base_incidentes$incidente, .f = ~{
    purrr::safely(baixar_pet_inicial)(incidente = .x, prog = p)
  })

})


