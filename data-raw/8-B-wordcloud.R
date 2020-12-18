##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

#### Script auxiliar ####
## Cria nuvens de palavras para a parte final do relatório


library(dplyr)

source("R/5-ler_pdf.R", encoding = "UTF-8")
## nuvem de palavras

# função que desenha a nuvem
desenhar_nuvem <- function(texto, qnt = 40, corMin = "#abbf8f",
                           corMax = "#07e31d", angular = 0) {

# receber o texto já "tratado" com a função
  set.seed(837)

# angular = 0, não faz angulação
# angular = 1, faz a angulação

  texto %>%
    mutate(angle = angular * (90 * sample(c(0, 1), n(), replace = TRUE,
                               prob = c(80, 20)))) %>%
    head(qnt) %>%
    ggplot2::ggplot(ggplot2::aes(label = token, size = n,
                                 color = n, angle = angle)) +
    ggwordcloud::geom_text_wordcloud(rm_outside = TRUE) +
    ggplot2::scale_size_area(max_size = 15,
                             trans = ggwordcloud::power_trans(1/.7)) +
    ggplot2::theme_minimal() +
    ggplot2::scale_color_gradient(low = corMin, high = corMax)

}


####### wordcloud corona petições
## definir uma tibble com stopwords que identifiquei

stopwords <- tibble("token" =
                      c("federal", "estado", "artigo", "direito", "sobre",
                        "constituicao", "publico", "inconstitucionalidade",
                        "acao", "tribunal", "poder", "brasil", "pode",
                        "documento", "republica", "uniao", "publica",
                        "httpportalautenticacaoautenticardocumento",
                        "digitalmente", "inciso", "valor", "processo",
                        "ordem", "justica", "constitucional", "conselho",
                        "presidente", "assinado", "direta", "procuradoriageral",
                        "assinatura", "verificar", "token", "barros",
                        "ministerio", "acesse", "forma", "estadual", "monteiro", "rodrigo",
                        "janot", "complementar", "nacional", "chave",
                        "brasilia", "partido", "tambem", "ainda",
                        "medida", "direitos", "numero", "presente",
                        "termos", "caput", "endereco", "conforme",
                        "servico", "servicos", "sera", "caso", "fundamental",
                        "arguicao", "descumprimento", "preceito", "julgamento",
                        "meio", "fundamentais", "artigos", "ministro", "outro",
                        "supremo", "geral", "governo", "governador", "qualquer",
                        "ponto", "paragrafo", "unico", "antonio", "norma",
                        "httptransparenciavalidacaodocumento", "paulo",
                        "todos", "todas", "sendo", "acoes", "outros", "outras",
                        "assim", "desta", "deste", "brasileira", "brasileiro",
                        "brasileiros", "brasileiras", "chaves", "eletronico",
                        "institui", "procuradorgeral"
                      ))

# pesquisar quais nos temas se relacionam com a pandemia
# vou juntar todas as colunas que podem ter assunto classificado pelo STF
# e vou ler quyis se relacionam com os termos típicos da pandemia

base_tema_pandemia <- base_partes_categorizada %>%
  filter(ano == 2020) %>%
  select(-autuacao, -distribuicao, -polo_ativo, -polo_passivo, -dia) %>%
  tidyr::unite(assuntos, assunto_principal, assunto_secundario,
               assunto_outros, ramo_direito_novo, legislacao, sep = "") %>%
  mutate(assuntos = str_squish(assuntos),
         assuntos = str_to_lower(assuntos),
         assuntos = abjutils::rm_accent(assuntos)) %>%
  # criar coluna T/F se o tema do corona é tratado naquela causa
  mutate(corona = if_else(str_detect(assuntos, "covid*|coronavirus|pandemia"),
                          TRUE, FALSE))

# vou buscar as palavras chave (já classificadas) de todas as ações do ano 2020

base_textos_pandemia <- base_tema_pandemia %>%
  left_join(readr::read_rds("data/palavra-chave-nest.rds")) %>%
  select(-nome, -assuntos, -mes, -tramitando, -ano, - relator, -incidente,
         -numero)

## separar em duas variáveis as palavras que estão nas ações sobre
# corona e sobre outros temas

peticoes_corona <- base_textos_pandemia %>%
  select(-categoria) %>%
  filter(corona)  %>%
  tidyr::unnest() %>%
  tidyr::unnest() %>%
  select(token, n) %>%
  anti_join(stopwords) %>%
  group_by(token) %>%
  summarise(n = sum(n)) %>%
  arrange(-n)

peticoes_nao <- base_textos_pandemia %>%
  select(-categoria) %>%
  filter(!corona)  %>%
  tidyr::unnest() %>%
  tidyr::unnest() %>%
  select(token, n) %>%
  anti_join(stopwords) %>%
  group_by(token) %>%
  summarise(n = sum(n)) %>%
  arrange(-n)

#####
# nuvem das peças
nuvem_peticoes_corona <- peticoes_corona %>%
  desenhar_nuvem(40, corMin = "#8f6060", corMax = "#ff0000", 1) +
  theme_minimal() +
  labs(subtitle = "Casos relativos à COVID")


nuvem_peticoes_nao <- peticoes_nao %>%
  desenhar_nuvem(40, corMin = "#798e91" , corMax = "#00ddff", 1) +
  theme_minimal() +
  labs(subtitle = "Casos relativos a outros temas")


#### nuvem por categoria de requerente

# criar uma base geral relacionando tokens com categoria de proponente
base_textos_nuvem_categoria <- readr::read_rds("data/palavra-chave-nest.rds") %>%
  tidyr::unnest() %>%
  tidyr::unnest() %>%
  left_join(base_partes_categorizada %>%
              select(incidente, categoria) %>%
              unique()) %>%
  select(-incidente) %>%
  anti_join(stopwords)

## função pra chamar várias vezes, uma pra cada categoria
nuvem_categoria <- function(categoria, corMin, corMax) {

# lembrar de usar {{ }}... fiquei horas tentando achar o erro

  base_textos_nuvem_categoria  %>%
    filter(categoria == {{categoria}}) %>%
    group_by(token) %>%
    summarise(n = sum(n)) %>%
    arrange(-n) %>%
    head(100) %>%
    desenhar_nuvem(corMin = corMin, corMax = corMax, angular = 1) +
    labs(title = categoria)
}

## criar as nuvens para cada uma delas
nuvem_osc <- nuvem_categoria("OSC", "#4b6145", "#5eeb34")

nuvem_oab <- nuvem_categoria("OAB", "#634343", "#e80e0e")

nuvem_presidente <- nuvem_categoria("Presidente da República", "#d1a562","#ff9900")

nuvem_pgr <- nuvem_categoria("PGR", "#7a8aff", "#001eff")

nuvem_partido <- nuvem_categoria("Partido Político", "#7f806a", "#e7eb09")

nuvem_gov <- nuvem_categoria("Governador/Prefeito", "#6c6470", "#9576a3")


