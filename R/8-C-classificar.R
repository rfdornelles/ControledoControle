# library(tidyverse)
library(magrittr)

###### função auxiliar
## embrulha o str_detect e coloca o ignore_case
detecta_parametro <- function(x,y) {
  y <- stringr::regex(pattern = y, ignore_case = TRUE)

  stringr::str_detect(string = x , pattern = y)

}

### cria lista com o nome dos estados em formato de regex
# ela vem duplicada pra pegar com e sem acento
lista_estados <- abjData::pnud_uf %>%
  dplyr::pull(ufn) %>%
  unique()

lista_estados <- lista_estados %>%
  c(.,
    abjutils::rm_accent(lista_estados)) %>% # aqui eu duplico
  unique() %>%
  stringr::str_c(collapse = "|") %>%
  stringr::regex(., ignore_case = T)

### cria lista com as UFs para tentar pegar a estrutura
# Município - UF em formato de regex
lista_uf <- abjData::cadmun %>%
  dplyr::pull(uf) %>%
  unique() %>%
  stringr::str_c(., collapse = "|") %>%
  c("\b*", ., "\b") %>%
  stringr::str_c(collapse = "") %>%
  stringr::regex(., ignore_case = T)


####### função pra dizer qual é o nível federativo de cada ato
# tentar ver se é de competência federal, estadual/distrital, municipal


analisa_esfera <- function(texto) {

  # lembrando que a detecta_parametro já chama elas em formato
  # case_insensitive = TRUE

  dplyr::case_when(
    detecta_parametro(texto, "Federal") ~ "Federal",
    detecta_parametro(texto, "Estadual|Distrital") ~ "Estadual",
    detecta_parametro(texto, "Municipal") ~ "Municipal",
    detecta_parametro(texto, "do Estado d(e|o)") ~ "Estadual",
    detecta_parametro(texto, "Munic(í|i)pio") ~ "Municipal",
    detecta_parametro(texto, "Distrito Federal") ~ "Estadual",
    # olhar se faz referência ao nome dos estados
    stringr::str_detect(texto, lista_estados) ~ "Estadual",
    # olhar se tem uma estrutura parecida com "Município - UF", que indicaria
    # ser municipal
    stringr::str_detect(texto, lista_uf) ~ "Municipal",
    detecta_parametro(texto, "C(o|ó)digo|Consolida(c|ç)(ã|a)o das Leis") ~ "Federal",
    detecta_parametro(texto, "Minist(e|é)rio [^p(ú|u)blico]") ~ "Federal",
    detecta_parametro(texto, "Ministro|Interministerial") ~ "Federal",
    detecta_parametro(texto, "Decreto-Lei") ~ "Federal",
    detecta_parametro(texto, "Conselho Nacional") ~ "Federal",
    detecta_parametro(texto, "Lei Complementar|Medida Provis(ó|o)ria") ~ "Federal",
    detecta_parametro(texto, "presidencial|president(e|a) d.") ~ "Federal",
    detecta_parametro(texto, "Uni(ã|a)o") ~ "Federal",
    TRUE ~ NA_character_) # se não couber em nada, NA
  # sabendo que, obviamente, a maior parte dos atos tende a cair na esfera
  # federal

}

#### função para me dizer que tipo de ato é o questionado
## olhar o campo "Legislação" que indica qual é o objeto da ação
# atenção aos tipos IN, portaria, Ato, Prov, etc que talvez possam ser
# agrupados como "infralegal"


analisa_ato <- function(texto) {

  # lembrando que a detecta_parametro já chama elas em formato
  # case_insensitive = TRUE

  dplyr::case_when(
    detecta_parametro(texto, "Lei") ~ "Lei",
    detecta_parametro(texto, "Decreto") ~ "Decreto",
    detecta_parametro(texto, "Código|Estatuto d.") ~ "Lei",
    detecta_parametro(texto, "Emenda Constitucional") ~ "Emenda Constitucional",
    detecta_parametro(texto, "Constitui(ç|c)(ã|a)o|Constitucion*") ~ "Constituição",
    detecta_parametro(texto, "Resolu(ç|c)(ã|a)o") ~ "Resolução",
    detecta_parametro(texto, "Portaria") ~ "Portaria",
    detecta_parametro(texto, "Medida Provisória") ~ "Medida Provisória",
    detecta_parametro(texto, "Instrução Normativa") ~ "Instrução Normativa",
    detecta_parametro(texto, "Regimento Interno") ~ "Regimento Interno",
    detecta_parametro(texto, "Ato n.") ~ "Ato",
    detecta_parametro(texto, "Provimento n.") ~ "Provimento",
    detecta_parametro(texto, "(Conven(ç|c)(a|ã)o|Tratado) Internacional") ~ "Convenção Internacional",
    detecta_parametro(texto, "S(ú|u)mula") ~ "Súmula",
    TRUE ~ "Outro"
  )

  # o tema "Convenção internacional" é meio curioso porque na prática o certo
  # seria questionar os atos internos que o promulgaram (decreto e decreto
  # legislativo)

}

#### testes
base_partes_categorizada_tipo_ato <- base_partes_categorizada %>%
  dplyr::select(classe, numero, categoria, autuacao, ano, mes, legislacao) %>%
  dplyr::mutate(
    esfera = analisa_esfera(legislacao),
    tipo_ato = analisa_ato (legislacao),
    esfera = dplyr::case_when(esfera == "Estadual" ~ "Estadual/Municipal",
                              esfera == "Municipal" ~ "Estadual/Municipal",
                              is.na(esfera) ~ "Não identificada",
                              TRUE ~ esfera))

grafico_esfera_ato_questionado <- base_partes_categorizada_tipo_ato %>%
  ggplot(aes(x = ano, fill = esfera)) +
 # scale_x_datetime(date_labels = "%y", date_breaks = "1 year") +
  facet_wrap(~categoria) +
  geom_bar(position = "fill", show.legend = T) +
  theme_classic() +
  scale_fill_brewer(palette = "Dark2") +
  labs(y = "Proporção", x = "Ano",
       title = "Qual esfera de competência dos atos questionados pelos legitimados",
       subtitle = "Agrupado pelas categorias de proponentes",
       caption = "Até 31/12/2020",
       fill = "Esfera de competência") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45))

grafico_perfil_atos_federais <- base_partes_categorizada_tipo_ato %>%
  dplyr::filter(esfera == "Federal") %>%
  dplyr::mutate(tipo_ato = forcats::as_factor(tipo_ato),
                tipo_ato = forcats::fct_collapse(tipo_ato,
                  Constitucional = c("Constituição", "Emenda Constitucional"),
                  Legal = c("Lei", "Medida Provisória"),
                  Infralegal = c("Portaria", "Decreto", "Resolução",
                                 "Instrução Normativa"),
                  other_level = "Outros"

                )) %>%
  ggplot(aes(x = ano, fill = tipo_ato)) +
  geom_bar(position = "fill") +
  scale_fill_brewer(palette = "Dark2") +
  scale_x_binned(limits = c(2000, 2020)) +
  labs(y = "Proporção", x = "Ano",
       title = "Perfil dos atos federais questionados",
       subtitle = "",
       caption = "Até 31/12/2020",
       fill = "Tipo de ato") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45)) +
  scale_x_continuous(breaks = seq(from = 2000, to = 2020, by = 1))

