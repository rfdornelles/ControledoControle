##### Monitor do Controle Concentrado no STF  ######
### Rodrigo Dornelles
### dezembro/2020

#### Algumas análises exploratórias ####
## Os gráficos são gerados e salvos em variávei que serão carregadas no
# arquivo .Rmd

### carregar bases
library(ggplot2)
library(dplyr)
library(stringr)


source("R/1-baixar_lista_processos.R")

#### carregar as bases do site do STF

base_simplificada <- ler_tabela_stf()

# carregar os incidentes
lista_incidentes <- readr::read_rds("data/incidentes.rds")

# juntar os incidentes à base
base_referencia <- base_simplificada %>%
  dplyr::left_join(lista_incidentes)

#### grafico distribuição de açõees

## ver distribuição ao longo dos anos
grafico_distribuicao_acoes <- base_simplificada %>%
  dplyr::count(ano) %>%
  ggplot(aes(x = ano, y = n)) +
  geom_line(size = 1) +
  theme_classic() +
  labs(x = "Ano", y = "Processos novos autuados",
       title = "Distribuição da autuação de ações no STF",
       caption = "Até 31/12/2020") +
  scale_x_continuous(breaks = seq(from = 2000, to = 2020, by = 1)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_hline(yintercept = 228, color = "darkgreen", size = 1) +
  annotate(y  = 220, x = 2020, label = "Mediana", geom = "text",
           size = 3) +
  geom_vline(xintercept = 2000, linetype = "dotted", color = "blue",
             size = 2) +
  annotate(x = 2000, y  = 400, label = "FHC", geom = "label", size = 3) +
  geom_vline(xintercept = 2003, linetype = "dotted", color = "blue",
             size = 2) +
  annotate(x = 2003, y  = 400, label = "Lula", geom = "label", size = 3) +
  geom_vline(xintercept = 2012, linetype = "dotted", color = "blue",
             size = 2) +
  annotate(x = 2012, y  = 400, label = "Dilma", geom = "label", size = 3) +
  geom_vline(xintercept = 2016, linetype = "dotted", color = "blue",
             size = 2) +
    annotate(x = 2016, y  = 400, label = "Impeachment\nTemer",
           geom = "label", size = 3) +
  geom_vline(xintercept = 2019, linetype = "dotted", color = "orange",
             size = 2) +
  annotate(x = 2019, y  = 400, label = "Bolsonaro", geom = "label",
           size = 3) +
  annotate(geom = "pointrange", y = 132, ymin = 132, x =2014,
           xmax = 2014, ymax = 132, color = "blue", size = 0.9, alpha = 0.4) +
  annotate(x = 2014, y  = 90, label = "V. nmínimo", geom = "text",
           size = 3) +
  annotate(geom = "pointrange", y = 503, ymin = 503, x =2020,
           xmax = 2020, ymax = 503, color = "red", size = 0.9, alpha = 0.4) +
  annotate(x = 2020.5, y  = 503, label = "V. máximo", geom = "text",
           size = 3)



## ver distribuição por classe processual
grafico_acoes_classe <- base_simplificada %>%
  ggplot(mapping = aes(x = ano, fill = classe)) +
  geom_bar() +
  theme_classic() +
  xlab("Ano") +
  ylab("Classe processual") +
  labs(title = "Distribuição das ações",
       subtitle = "Controle concentrado ao longo dos anos (ações autuadas)",
       caption = "Até 31/12/2020") +
  scale_x_binned(limits = c(2000, 2020), n.breaks = 20) +
  theme(axis.text.x = element_text(angle = 45))


##### principais partidos
# carregar partes
base_partes <- readr::read_rds(file = "data/partes.rds")

### categorizar as partes por seu nome
# após limpar os nomes, vamos criar categorias

base_partes_categorizada <- base_partes %>%
  dplyr::filter(tipo == "REQTE") %>%
  dplyr::mutate(
    nome = abjutils::rm_accent(nome),
    nome = stringr::str_to_lower(nome),
    nome = stringr::str_squish(nome),
    nome = stringr::str_remove_all(nome, "e outro\\(a\\/s\\)"),
    nome = stringr::str_remove_all(nome, "[[:punct:]]")
    ) %>%
  dplyr::mutate(
    categoria = dplyr::case_when(
      str_detect(nome, "^presidente da republica") ~ "Presidente da República",
      str_detect(nome, "geral da republica$") ~ "PGR",
      str_detect(nome, "(procurador|procuradora).geral da repub.ica") ~ "PGR",
      str_detect(nome, "^partido") ~ "Partido Político",
      str_detect(nome, "associacao|confederacao|federacao|sindicato|sindical") ~ "OSC",
      str_detect(nome, "uniao nacional|uniao geral|articulacao|central nacional") ~ "OSC",
      str_detect(nome, "ordem dos advogados") ~ "OAB",
      str_detect(nome, "^governador*|prefeit*") ~ "Governador/Prefeito",
      str_detect(nome, "^estado de *") ~ "Governador/Prefeito",
      str_detect(nome, "rede sustentabilidade|podemos|solidariedade|cidadania|democratas - diretorio nacional") ~ "Partido Político",
      TRUE ~ NA_character_
    )) %>% select(-tipo)

## join para obter ano
base_partes_categorizada <- base_partes_categorizada %>%
  dplyr::left_join(base_referencia)


## ver quando essas categorias propuseram as ações
grafico_distribuicao_2020_categoria <- base_partes_categorizada %>%
  filter(ano == 2020, !is.na(categoria)) %>%
  group_by(categoria, autuacao) %>%
  count(autuacao) %>%
  ggplot(aes(x = autuacao, y = n, color = categoria)) +
  geom_line(size = 1.1, show.legend = F) +
  scale_y_continuous(limits = c(1, 15), n.breaks = 15, name = NULL) +
  scale_x_datetime(date_labels = "%b", date_breaks = "1 month") +
  theme_classic() +
  facet_wrap(~categoria) +
  labs(title = "Distribuição de ações em 2020",
       subtitle = "Por categoria de proponente", caption = "Até 31/12/2020",
       x = "Mês de autução",
       y = "Quantidade ações") +
  theme(axis.text.x = element_text(angle = 45))


### ver quais partidos são os que mais acionam

tabela_quais_partidos <- base_partes_categorizada %>%
  filter(categoria == "Partido Político") %>%
  mutate(nome = str_to_upper(nome),
         nome = str_squish(nome)) %>%
  count(nome, sort = T) %>%
  head(10) %>%
  knitr::kable()

### quais OSC

tabela_quais_osc <- base_partes_categorizada %>%
  filter(categoria == "OSC") %>%
  mutate(nome = str_to_upper(nome),
         nome = str_squish(nome)) %>%
  count(nome, sort = T) %>%
  head(10) %>%
  knitr::kable()


base_partes_categorizada <- base_partes_categorizada %>%
  left_join(base_referencia) %>%
  filter(!is.na(categoria))


grafico_partes_categorizadas <- base_partes_categorizada %>%
  select(classe, categoria, ano, mes, tramitando) %>%
  #group_by(ano) %>%
  ggplot(aes(x = ano, fill = categoria)) +
  facet_wrap(~categoria) +
  geom_bar(position = "dodge", show.legend = F) +
  theme_classic() +
  labs(x = NULL, y = "Ações propostas",
       title = "Evolução da propositura de ações",
       subtitle = "Por categoria de proponentes",
       caption = "Até 31/12/2020") +
  theme(axis.text.x = element_text(angle = 45))

#######################

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

grafico_quem_covid <- base_temas %>%
  filter(ano == 2020) %>%
  ggplot(aes(x = corona, fill = categoria)) +
  geom_bar() +
  theme_classic() +
  scale_x_discrete(labels = c("Outros temas", "COVID")) +
  scale_fill_brewer(palette = "Dark2") +
  labs(x = NULL, y = "Ações propostas",
       title = "Quem propôs as ações relacionadas ao COVID",
       subtitle = "Agrupado pelas categorias de proponentes",
       caption = "Até 31/12/2020")

grafico_evolucao_acoes_covid <- base_temas %>%
  filter(ano == 2020) %>%
  group_by(mes) %>%
  ggplot(aes(x = mes, fill = corona)) +
  geom_bar(position = "fill") +
  geom_hline(yintercept = 0.5) +
  scale_x_continuous(n.breaks = 12) +
  scale_fill_manual(values = c("#e8b835", "#269e5a"),
                    name = "Tema", labels = c("Outros", "COVID-19")) +
  theme_classic() +
  labs(x = "Mês", y = "Proporção",
       title = "Evolução da quantidade de ações autuadas",
       subtitle = "Proporção entre ações que tratam do COVID-19 e outros temas",
       caption = "Até 31/12/2020")







