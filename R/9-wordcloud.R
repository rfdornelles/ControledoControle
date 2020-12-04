## nuvem de palavras
# ref: hhttps://lepennec.github.io/ggwordcloud/articles/ggwordcloud.html#word-cloud-and-color

textos <- readr::read_rds("data/peticoes.rds")$texto_inicial[1]

library(ggwordcloud)

set.seed(837)

tabela <- retornar_palavras_frequentes(textos, simplifica = F, quantidade = 15) %>%
  tidyr::unnest(data) %>%
  dplyr::mutate(angle = 90 *
                  sample(c(0, 1), dplyr::n(), replace = TRUE, prob = c(70, 30)))

tabela %>%
  ggplot(aes(label = token, size = n, color = n)) +
  geom_text_wordcloud(rm_outside = TRUE) +
  scale_size_area(max_size = 15) +
  theme_minimal() +
  scale_color_gradient(low = "#abbf8f", high = "#07e31d"


####### wordcloud corona petições

base_temas <- base_partes_categorizada %>%
  select(-autuacao, -distribuicao, -polo_ativo, -polo_passivo, -dia) %>%
  tidyr::unite(assuntos, assunto_principal, assunto_secundario,
               assunto_outros, ramo_direito_novo, legislacao, sep = "") %>%
  mutate(assuntos = str_squish(assuntos),
         assuntos = str_to_lower(assuntos),
         assuntos = abjutils::rm_accent(assuntos)) %>%
  mutate(corona = if_else(str_detect(assuntos, "covid*|coronavirus|pandemia"),
                          TRUE, FALSE)
  )

base_textos <- base_temas %>%
  filter(ano == 2020) %>%
  left_join(readr::read_rds("data/palavra-chave-nest.rds")) %>%
  select(-nome, -assuntos, -mes, -tramitando, -ano, - relator, -incidente,
         -numero)


peticoes_corona <- base_textos %>%
  select(-categoria) %>%
  filter(corona)  %>%
  tidyr::unnest() %>%
  tidyr::unnest() %>%
  select(token, n) %>%
  group_by(token) %>%
  summarise(soma = sum(n)) %>%
  arrange(-soma)

peticoes_nao <- base_textos %>%
  select(-categoria) %>%
  filter(!corona)  %>%
  tidyr::unnest() %>%
  tidyr::unnest() %>%
  select(token, n) %>%
  group_by(token) %>%
  summarise(soma = sum(n)) %>%
  arrange(-soma)


peticoes_corona %>%
  head(20) %>%
  ggplot(aes(label = token, size = soma, color = soma)) +
  ggwordcloud::geom_text_wordcloud(rm_outside = TRUE) +
  scale_size_area(max_size = 15) +
  theme_minimal() +
  scale_color_gradient(low = "#abbf8f", high = "#07e31d")

peticoes_nao %>%
  head(20) %>%
  ggplot(aes(label = token, size = soma, color = soma)) +
  ggwordcloud::geom_text_wordcloud(rm_outside = TRUE) +
  scale_size_area(max_size = 15) +
  theme_minimal() +
  scale_color_gradient(low = "#d6b58d", high = "#693900")

peticoes_nao %>%
  anti_join(peticoes_corona %>% select(token))

base_temas %>%
  filter(ano == 2020) %>%
  left_join(readr::read_rds("data/palavra-chave-nest.rds")) %>%
  select(corona, palavra) %>%
  tidyr::unnest(palavra) %>%
  tidyr::unnest() %>%
  group_by(corona, token) %>%
  summarise(soma = sum(n)) %>%
  arrange(-soma)



# summarise(sintese = str_c(palavra, collapse = ""))
#
# mutate(sintese = str_remove_all(sintese, "n*(º|ª)|(º|ª)|,")) %>%
# rowwise() %>%
# mutate(sintese = retornar_palavras_frequentes(sintese, 20)) %>%
# kableExtra::kbl()

