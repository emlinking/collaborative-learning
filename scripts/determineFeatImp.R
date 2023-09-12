########## determineFeatImp.R ##########
# Author: Eleanor Lin
# Last updated: 7/3/2021

# Setup -------------------------------------------------------------------
setwd("C:/corter_lab/FeatImp")
getwd()
dir()

# Load Libraries
library(dplyr)
library(tidyr)
library(tidytext)
library(ggplot2)
library(gt)
library(webshot)

# Data Cleaning and Formatting--------------------------------------------------
# Read in and combine transcripts (excluding GJ0805131100_flagged.csv)
file_names <- list.files(pattern = '\\.csv')
file_names <- file_names[file_names != "GJ0805131100_flagged.csv"]

# Exclude codes "Qr", "Rd", "C" from speech acts to analyze
obsolete_acts <- c("Qr", "Rd", "C")
speech_acts <- colnames(read.csv(file_names[1]))[1:12]
speech_acts <- speech_acts[! speech_acts %in% obsolete_acts]

# Extract utterances for speech acts with majority (2/3) agreement from raters
# Store each speech act dataset in the list utterance_tables
utterance_tables <- list()
for(i in 1:length(speech_acts)){
  utterances_all_trials <- data.frame() # Data frame for speech-act data set
  
  for(j in 1:length(file_names)) {
    trial_table <- 
      read.csv(file_names[j], blank.lines.skip = TRUE, header = TRUE) %>%
      select(speech_acts[i], 14) # Select rating and utterance columns only
    colnames(trial_table)[2] <- "utterance"
    trial_table <- dplyr::filter(trial_table, trial_table[,1] > 1)
    utterances_all_trials <- rbind(trial_table, utterances_all_trials)
  }
  
  utterance_tables <- c(utterance_tables, list(utterances_all_trials))
}

# Tokenize utterances into uni-, bi-, and tri-grams, and sort each ngram list
# for each utterance by frequency.
# Also filter out NLTK stop words from all ngrams.
unigrams_by_speech_act <- list() # Empty list for tokenized speech act datasets
bigrams_by_speech_act <- list()
trigrams_by_speech_act <- list()

nltk_stop_words <- read.table("NLTK's list of english stopwords")

for(i in 1:length(utterance_tables)){
  unigrams_by_speech_act[[i]] <- utterance_tables[[i]] %>% 
    unnest_tokens(word, utterance) %>% 
    count(word, sort = TRUE) %>%
    filter(!word %in% nltk_stop_words$V1) 
  
  bigrams_by_speech_act[[i]] <- utterance_tables[[i]] %>%
    unnest_tokens(bigram, utterance, token = "ngrams", n = 2) %>%
    count(bigram, sort = TRUE) %>%
    separate(bigram, into = c("word1", "word2"), sep = " ") %>%
    na.omit() %>%
    filter(!word1 %in% nltk_stop_words$V1, !word2 %in% nltk_stop_words$V1) %>%
    unite(bigram, c(word1, word2), sep = " ") 
  
  trigrams_by_speech_act[[i]] <- utterance_tables[[i]] %>%
    unnest_tokens(trigram, utterance, token = "ngrams", n = 3) %>%
    count(trigram, sort = TRUE) %>%
    separate(trigram, into = c("word1", "word2", "word3"), sep = " ") %>%
    na.omit() %>%
    filter(!word1 %in% nltk_stop_words$V1, !word2 %in% nltk_stop_words$V1,
           !word3 %in% nltk_stop_words$V1) %>%
    unite(trigram, c(word1, word2, word3), sep = " ")
}

names(unigrams_by_speech_act) <- speech_acts
names(bigrams_by_speech_act) <- speech_acts
names(trigrams_by_speech_act) <- speech_acts

# Create visualizations for uni-, bi-, and tri-grams
for(i in 1:length(unigrams_by_speech_act)){
  # Unigram Visualizations
  top_words <- data.frame(unigrams_by_speech_act[[i]][1:10,])
  title <- 
    paste("Top 10 Words in", names(unigrams_by_speech_act)[i], 
          "-coded Utterances")
  
  ggplot(data = top_words, aes(x = reorder(word, -n), y = n)) +
    geom_bar(stat = "identity", color = "white", fill = "steelblue") + 
    theme_minimal() +
    labs(title = title, x = "Word", y = "Frequency")
  
  plot_name <- paste(names(unigrams_by_speech_act)[i], "_unigrams.png", sep = "")
  ggsave(plot_name, width = 5, height = 5)
  
  table_name <- 
    paste("all_unigrams_", names(unigrams_by_speech_act)[i], ".html")
  unigrams_by_speech_act[[i]] %>%
    gt() %>%
    tab_header(title = paste("Unigram Frequency in", 
                    names(unigrams_by_speech_act)[i], "-coded Utterances")) %>%
    gtsave(table_name)
  
  # Bigram visualization
  top_bigrams <- data.frame(bigrams_by_speech_act[[i]][1:10,])
  title <- 
    paste("Top 10 Bigrams in", names(bigrams_by_speech_act)[i], 
          "-coded Utterances")
  
  ggplot(data = top_bigrams, aes(x = reorder(bigram, -n), y = n)) +
    geom_bar(stat = "identity", color = "white", fill = "steelblue") + 
    theme_minimal() +
    labs(title = title, x = "Bigram", y = "Frequency")
  
  plot_name <- paste(names(bigrams_by_speech_act)[i], "_bigrams.png", sep = "")
  ggsave(plot_name, width = 10, height = 5)
  
  table_name <- paste("all_bigrams_", names(bigrams_by_speech_act)[i], ".html")
  bigrams_by_speech_act[[i]] %>%
    gt() %>%
    tab_header(title = paste("Bigram Frequency in", 
                             names(bigrams_by_speech_act)[i], 
                             "-coded Utterances")) %>%
    gtsave(table_name)
  
  # Trigram visualization
  top_trigrams <- data.frame(trigrams_by_speech_act[[i]][1:10,])
  title <- 
    paste("Top 10 Trigrams in", names(trigrams_by_speech_act)[i], 
          "-coded Utterances")
  
  ggplot(data = top_trigrams, aes(x = reorder(trigram, -n), y = n)) +
    geom_bar(stat = "identity", color = "white", fill = "steelblue") + 
    theme_minimal() +
    labs(title = title, x = "Trigram", y = "Frequency")
  
  plot_name <- paste(names(trigrams_by_speech_act)[i], "_trigrams.png", sep = "")
  ggsave(plot_name, width = 15, height = 5)
  
  table_name <- 
    paste("all_trigrams_", names(trigrams_by_speech_act)[i], ".html")
  trigrams_by_speech_act[[i]] %>%
    gt() %>%
    tab_header(title = paste("Trigram Frequency in", 
                             names(trigrams_by_speech_act)[i], 
                             "-coded Utterances")) %>%
    gtsave(table_name)
}