# Caltech Conte Center Data Release 2021
#
# Factor Analysis
#
# Author : Rona Yu
#
# Copyright 2021 California Institute of Technolog
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

setwd("/Users/jmt/GitHub/ConteDataRelease/FactorAnalysis")

# Libraries
library(corrplot)
library(paran)
library(readxl)
library(nFactors)
# library(paramap) now released as EFA.dimensions
library(EFA.dimensions)
library(FactoMineR)
library(factoextra)
library(data.table)
library(psych)
library(GPArotation)
library(ggplot2)
library(corrplot)

# ************* Load File *************
conteData <- read_excel('PARL_FA_20210312_Rona.xlsx') # n = 144

# exclude values with low Quality measure
# cex <- subset(conteData, Include..Exclude. != 'Exclude all data') # n = 144
cex <- conteData

# Added PSS, SQ, and EQ
# Added an X at the beginning of columns beginning with numbers
no_msceit <- cbind(cex$STAI_State_Tscore, cex$STAI_Trait_Tscore, cex$BDI2_Total, cex$PANAS_Negative, 
                  cex$PSS_Total, cex$SQ_Total, cex$EQ_Total,
                  cex$PANAS_Positive, cex$X16PF_Q1, 
                  cex$X16PF_C,
                  cex$X16PF_B,
                  cex$VCI, cex$X16PF_O,
                  cex$PRI, cex$X16PF_G, 
                  cex$X16PF_Q1,
                  cex$X16PF_A, cex$X16PF_Q2, 
                  cex$X16PF_N, cex$X16PF_F, 
                  cex$X16PF_H, cex$SNI_Count,
                  cex$X16PF_M, cex$X16PF_Q3,
                  cex$X16PF_E, cex$X16PF_L, 
                  cex$X16PF_I)

names <- cbind("STAI State T Score", "STAI Trait T Score", "BDI Total", "PANAS Negative", "PSS", "SQ", "EQ", 
               "PANAS Positive", "16PF Tension", "16PF Emotional Stability", "16PF Reasoning",
               "VCI IQ", "16PF Apprehension", "PRI IQ", "16PF Rule Conciousness", "16PF Openness to Change",
               "16PF Warmth", "16PF Self Reliance", "16PF Privateness", "16PF Liveliness", 
               "16PF Social Boldness", "SNI People in Network", "16PF Abstractedness", "16PF Perfectionism", 
               "16PF Dominance", "16PF Vigilance", "16PF Sensitivity")

row.names(no_msceit) <- cex$CC_ID

# ************* Functions *************
# Function to impute NA values with the column mean
impute_df <- function(df) {
  to_ret <- df
  for(i in 1:ncol(df)) {
    to_ret[is.na(to_ret[,i]), i] <- mean(to_ret[, i], na.rm=TRUE)
  }
  return(to_ret)
}

# Function to compute the overall correlation matrix
plot_corr <- function(df){
  M <- cor(df, method="spearman")
  corrplot(M, method="color")
}

# Function to write number of factors to file 
write_file <- function(method, numFac, fileName){ 
  cat(method, "\t", numFac, "\n", file=fileName,fill=FALSE, append=TRUE)
}

# Function to calculate number of factors 
find_factors <- function(df, fileName) {
  
  # Velicer's MAP
  a <- MAP(df, corkind="spearman", verbose=TRUE)
  write_file("Velicer's 1976", a[[3]][1], fileName)
  write_file("Velicer's 2000", a[[4]][1], fileName)
  
  # Horn's 
  a <- paran(df, cfa=TRUE, graph=FALSE)
  write_file("Horn's PA", a[[1]][1], fileName)
  
  # Scree NOC
  aparallel <- eigenBootParallel(x=df, cor=TRUE, quantile=0.95,method="spearman")$quantile
  r <- nScree(x=df, aparallel=aparallel, cor=TRUE, model = "factors", method="spearman")
  a <- r[[1]][1]
  a <- as.integer(a)
  print(r) 
  write_file("Cattell's Scree Test", a, fileName)
  
  # CNG
  cng <- nCng(x=df, cor=TRUE, model="factors", details=TRUE, method="spearman")
  write_file("Cng", cng[[2]], fileName)
  cat("\n***** Cng *****\n")
  print(cng)
  
  # Multiply regression (b coeff)
  cat("\n***** Zoski B Coefficient *****\n")
  a <- nMreg(x=df, cor=TRUE, model="factors",details=TRUE, method="spearman")
  write_file("Zoski", a[[2]][[1]], fileName)
  print(a)
  
}

# Function to extract factors
exFac <- function(df, numFac){
  
  fit <- factanal(df, numFac, rotation="varimax")
  
  # Plot factor 1 by factor 2
  load <- fit$loadings[,1:2]
  plot(load, type="n") #set up plot
  text(load, labels=names(df), cex=.7)
  write.table(fit$loadings, file="factor_output.txt", sep = "\t")
  
  return((fit$loadings))
  
}

# Function to estimate number of factors after removing X random subjects
# df: dataframe. numSubj: maximum number of subjects to remove 
remSubj <- function(df, numSubj, fileName){
  
  cat("New Trial", "\n", file=fileName, fill=FALSE, append=FALSE)
  
  n <- dim(df)[1] # number of rows 
  r <- seq(1, numSubj) # 1 to numSubj
  
  for(numRemoved in r){
    toRemove <- sample(1:n, numRemoved, replace=F)
    rem <- df[-toRemove, ]
    print(rem)
    cat("Number of subjects removed is: ", numRemoved, "\n", file=fileName, fill=FALSE, append=TRUE)
    find_factors(rem, fileName) # find factors 
  }
  
}

# Function to extract factors after removing X random subjects
remExtract <- function(df, numSubj, numFac, fileName){
  
  n <- dim(df)[1]
  toRemove <- sample(1:n, numSubj, replace=F)
  rem <- df[-toRemove, ]
  res <- exFac(rem, numFac)
  write.table(res, file=fileName, sep="\t")
  
}

# Function to visualize factors with FactoMineR
visualize <- function(df, n, num_comp) {
  
  setnames(df, n)
  df.pca <- PCA(df, ncp = num_comp, graph=FALSE)
  fviz_pca_ind(df.pca, geom="text") # plot PCA results
  var <- get_pca_var(df.pca)
  print(var$contrib)
  
}

# ************* Determine individual factor scores *************
individual_scores <- function(df, numFactors, num_obs, fileName) {
  
  corr_mat <- cor(df, method="spearman")
  factor_analysis <- fa(corr_mat, nfactors = numFactors, n.obs = num_obs, scores="regression")
  scores <- factor.scores(df, factor_analysis)$scores
  write.table(scores, file=fileName, sep="\t")
  
}
# *** END OF FUNCTIONS ***

# ************* Initialize Data Frames *************
all_df <- data.frame(no_msceit) # 144 subjects
colnames(all_df) <- names
sum(is.na(all_df)/prod(dim(all_df))) # 0
nona_df <- data.frame(na.omit(all_df)) # 144 subjects, 27 variables
imputed_df <- impute_df(all_df) # 144 subjects

# ************* Function Calls *************
corr_mat <- cor(nona_df, method="spearman")
factor_analysis <- fa(corr_mat, nfactors = 4, n.obs = 144, scores="regression")
scores <- factor.scores(nona_df, factor_analysis$loadings, method="Harman")$scores
write.table(scores, file="individual_score.tsv", sep="\t")
write.table(factor_analysis$loadings, file="loadings.tsv", sep="\t")

# Determine the number of factors
num_fac <- find_factors(nona_df, "num_factor_revised.tsv")

# Correlation plots
# 2021-12 Mike Tyszka | CBIC
r_pearson <- cor(nona_df, method="pearson")
corrplot(r_pearson, order="alphabet", tl.col="black")
corrplot(r_pearson, order="FPC", tl.col="black")
corrplot(r_pearson, order="hclust", hclust.method="complete", addrect=4, tl.col="black")