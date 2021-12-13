# Caltech Conte Center Data Release 2021
#
# Factor Analysis
#
# Author : Rona Yu
#
# Copyright 2021 California Institute of Technology
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

# Libraries
library(corrplot)
library(paran)
library(readxl)
library(nFactors)
library(EFA.dimensions)
library(FactoMineR)
library(factoextra)
library(data.table)
library(psych)
library(GPArotation)
library(ggplot2)
library(corrplot)


# Edit for local folder location
setwd("/Users/jmt/GitHub/ConteDataRelease/FactorAnalysis")

# Load excel sheet
cex <- read_excel('PARL_FA_Final.xlsx') # n = 144

# Composite data frame from spreadsheet columns
# Replace 16PF with X16PF in spreadsheet (variable names cannot begin with a number)
no_msceit <- cbind(
  cex$STAI_State_Tscore, # 1
  cex$STAI_Trait_Tscore,
  cex$BDI2_Total,
  cex$PANAS_Negative,
  cex$PSS_Total, # 5
  cex$SQ_Total,
  cex$EQ_Total,
  cex$PANAS_Positive,
  cex$X16PF_Q4,
  cex$X16PF_C, # 10
  cex$X16PF_B,
  cex$VCI,
  cex$X16PF_O,
  cex$PRI,
  cex$X16PF_G, # 15
  cex$X16PF_Q1,
  cex$X16PF_A,
  cex$X16PF_Q2, 
  cex$X16PF_N,
  cex$X16PF_F, # 20 
  cex$X16PF_H,
  cex$SNI_Count,
  cex$X16PF_M,
  cex$X16PF_Q3,
  cex$X16PF_E, # 25
  cex$X16PF_L,
  cex$X16PF_I) # 27

# Readable name mapping
names <- cbind(
  "STAI State T Score", # 1
  "STAI Trait T Score",
  "BDI Total",
  "PANAS Negative",
  "PSS", # 5
  "SQ",
  "EQ",
  "PANAS Positive",
  "16PF Tension",
  "16PF Emotional Stability", # 10
  "16PF Reasoning",
  "VCI IQ",
  "16PF Apprehension",
  "PRI IQ",
  "16PF Rule Consciousness", # 15
  "16PF Openness to Change",
  "16PF Warmth",
  "16PF Self Reliance",
  "16PF Privateness",
  "16PF Liveliness", # 20
  "16PF Social Boldness",
  "SNI People in Network",
  "16PF Abstractedness",
  "16PF Perfectionism",
  "16PF Dominance", # 25
  "16PF Vigilance",
  "16PF Sensitivity") # 27

# Subject IDs to row names
row.names(no_msceit) <- cex$CC_ID

# *** FUNCTION DEFINITIONS ***

# Function to impute NA values with the column mean
impute_df <- function(df) {
  to_ret <- df
  for(i in 1:ncol(df)) {
    to_ret[is.na(to_ret[,i]), i] <- mean(to_ret[, i], na.rm=TRUE)
  }
  return(to_ret)
}

# Function to write number of factors to file 
write_file <- function(method, numFac, fileName){ 
  cat(method, "\t", numFac, "\n", file=fileName, fill=FALSE, append=TRUE)
}

# Function to calculate number of factors 
find_factors <- function(df, fileName) {
  
  # Init output file
  write("Number of Factor Estimates", file=fileName, append=FALSE)
  
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

# *** END OF FUNCTIONS ***

# Initialize data frames
all_df <- data.frame(no_msceit) # 144 subjects
colnames(all_df) <- names
sum(is.na(all_df)/prod(dim(all_df))) # 0
nona_df <- data.frame(na.omit(all_df)) # 144 subjects, 27 variables
imputed_df <- impute_df(all_df) # 144 subjects

# Use Spearman's correlation coefficient - scores not transformable to normal
r_spearman <- cor(nona_df, method="spearman")

# Perform maximum likelihood factor analysis with varimax rotation
# Write individual scores and loadings to files
cat("\nFactor Analysis with Rotation\n")
fa_rot <- fa(r_spearman, nfactors = 4, n.obs = 144, rotate="varimax", scores="regression", fm="ml")
fa_rot_scores <- factor.scores(nona_df, fa_rot$loadings, method="Bartlett")$scores
write.table(fa_rot_scores, file="fa_rotated_individual_score.tsv", sep="\t")
write.table(fa_rot$loadings, file="fa_rotated_loadings.tsv", sep="\t")

# Perform maximum likelihood factor analysis without rotation
# Write individual scores and loadings to files
cat("\nFactor Analysis without Rotation\n")
fa_unrot <- fa(r_spearman, nfactors = 4, n.obs = 144, rotate="none", scores="regression", fm="ml")
fa_unrot_scores <- factor.scores(nona_df, fa_rot$loadings, method="Bartlett")$scores
write.table(fa_unrot_scores, file="fa_unrotated_individual_score.tsv", sep="\t")
write.table(fa_unrot$loadings, file="fa_unrotated_loadings.tsv", sep="\t")

# Estimate number of factors with a variety of methods
num_fac <- find_factors(nona_df, "num_factor_estimates.tsv")

# Correlation plot - save to PNG file
png(file="CorrMat_FPC.png", width=3000, height=3000, res=300)
corrplot(r_spearman, order="FPC", tl.col="black")
dev.off()