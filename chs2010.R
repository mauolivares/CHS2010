########################################################################
#
#  CHS2010
#
#  Summary Statistics (Table A9.1-A9.3)
########################################################################

###' Cleaning and working directory
rm(list = ls())
#dev.off()
local({r <- getOption("repos"); r["CRAN"] <- "http://cran.r-project.org"; options(repos=r)}) #set repo
setwd("D:/OneDrive - University College London/CHS2010")



###' Replicate Table A9-1, supplement

pkg<-list("modelsummary","dplyr","haven")
lapply(pkg, require, character.only=T)
rm(pkg)


#' Load data
dat <- read_dta('Data/data.dta')

#' Generate the age period variable
temp_age <- data.frame(age = c(0,1,3,5,7,9,11,13), 
rep_age = c('Period 1: Year of Birth of Child',
            'Period 2: Ages 1-2',
            'Period 3: Ages 3-4',
            'Period 4: Ages 5-6',
            'Period 5: Ages 7-8',
            'Period 6: Ages 9-10',
            'Period 7: Ages 11-12',
            'Period 8: Ages 13-14')) 
dat <- merge(dat, temp_age, by = 'age')
rm(temp_age)

#' Create a function to exclude obs with -100 gestation length and generate a new variable
#' @param var string, name of the variable
#' @param data dataset
#' @return a new dataset with a new variable added
inputNaN <- function(var, data){
  data[[paste('rep_',var,sep = '')]] <- data[[var]]
  data[[paste('rep_',var,sep = '')]][data[[paste('rep_',var,sep = '')]] < -99] <- NaN
  return(data)
}

#' Create a function to make summaries
#' @param var string, name of the variable
#' @param label string, label of the variable, a string
#' @param data dataset
#' @return a table
sumtable <- function(var, label, data){
  a <- paste('(\'', label,'\' = rep_',var ,')', sep = '')
  b <- '~ rep_age * (N + Mean * Arguments(fmt = \'%.3f\')+ SD * Arguments(fmt = \'%.3f\'))'
  c <- datasummary(as.formula(paste(a,b)),
              sparse_header = FALSE,
              data = data)
  return(c)
}


##' Summary Statistics Table
#' Pick the first observation of the same childid, because
#' observations with the same childid have the same gestation
dat <- dat %>% group_by(childid) %>% 
  mutate(rep_first = as.numeric(row_number() == 1L) )
dat$rep_first[dat$rep_first == 0] <- NaN

#' The following transformations are needed to report results
#' that only consider the first period. Inputs for function
#' sumtable()
dat <- inputNaN(var = 'gestlenght', data = dat)
dat <- inputNaN(var = 'weightbirth', data = dat)
dat$rep_gestlenght <- dat$rep_gestlenght * dat$rep_first
dat$rep_weightbirth <- dat$rep_weightbirth * dat$rep_first

#'  Remove observations with -100 scores. 
#'  
#'  Step 1. Begin with a list of such variables. The elements  
#'  of the list correspond with rows in table A9-1 in CHS.
#'  The list contains:
#'  a) Gestation length
#'  b) Weight at birth
#'  c) Motor-Social Development Score
#'  d) Body Parts
#'  e) Memory for Locations
#'  f) Peabody Picture Vocabulary Test
#'  g) PIAT Math
#'  h) PIAT Reading Recognition
#'  i) PIAT Reading Comprehension
#'  j) Temperament/Compliance Raw Score
#'  k) Temperament/Insecure Attachment Raw Score
#'  l) Temperament/Sociability Raw Score
#'  m) Temperament/Difficulty Raw Score
#'  n) Temperament/Friendliness Raw Score
#'  o) Behavior Problem Index/Antisocial Raw Score
#'  p) Behavior Problem Index/Anxiety Raw Score
#'  q) Behavior Problem Index/Headstrong Raw Score
#'  r) Behavior Problem Index/Hyperactive Raw Score
#'  s) Behavior Problem Index/Conflict Raw Score


list.covar        <- c("rep_gestlenght","rep_weightbirth","msd","bp","ml","ppvt","math","recg","comp",
                       "tempE","tempF","tempG","tempI","tempJ","bpiA","bpiB","bpiC","bpiD","bpiE")
labels.list.covar <- c("Gestation length","Weight at birth","Motor-Social Development Score",
                       "Body Parts","Memory for Locations","Peabody Picture Vocabulary Test",
                       "PIAT Math","PIAT Reading Recognition","PIAT Reading Comprehension",
                       "Temperament/Compliance Raw Score","Temperament/Insecure Attachment Raw Score",
                       "Temperament/Sociability Raw Score","Temperament/Difficulty Raw Score",
                       "Temperament/Friendliness Raw Score","Behavior Problem Index/Antisocial Raw Score",
                       "Behavior Problem Index/Anxiety Raw Score","Behavior Problem Index/Headstrong Raw Score",
                       "Behavior Problem Index/Hyperactive Raw Score","Behavior Problem Index/Conflict Raw Score")

#'  Step 2. Remove observations with -100 scores. This operation returns a list of data.frames.
#'  The j-th element in the list is a data.frame excluding -100 scores for the j-th variable
#'  for all j in list.covar. For Example, the second element in list.data is a copy of dat
#'  such that variable 'weightbirth' no longer has -100 scores.
list.data <- lapply(list.covar, function(s,dat){inputNaN(var = s, data = dat)},dat)

#'  Step 3. Summary of results. This operation returns a list whose elements are summary tables.
#'  The j-th element in the list is the summary table for the j-th covariate in list.covar
list.sumtables <- lapply(1:length(list.covar), function(s) sumtable(var=list.covar[s],label = labels.list.covar[s],data = list.data[[s]]))

# Visualization. Summary table for the last variable
list.sumtables[[length(list.covar)]]



###' Replicate Table A9-2, supplement

#'  Step 1. Begin with a list of such variables. The elements  
#'  of the list correspond with rows in table A9-2 in CHS.
#'  The list contains:
#'  a) How Often Child Gets Out of House
#'  b) Number of Books
#'  c) How Often Mom Reads to Child
#'  d) Number of Soft/Role Play Toys
#'  e) Number of Push/Pull Toys
#'  f) How Often Child Eats With Mom/Dad
#'  g) How Often Mom Talks to Child From Work
#'  h) Number of Magazines
#'  i) Child Has Tape Recorder/CD Player
#'  j) How Often Child Is Taken to Museum
#'  k) Child Has Musical Instrument
#'  l) Family Receives Daily Newspaper
#'  m) Child Receives Special Lessons/Activities
#'  n) Child Is Taken to Musical Performances
#'  o) How Often Child Sees Family Friends
#'  p) Number of Times Praised Child Last Week
#'  q) Number of Times Said Positive Things Last Week


list.covar        <- c("inv01","inv02","inv03","inv05","inv06","inv09","inv10","inv12",
                       "inv13","inv18","inv19","inv20","inv23","inv24","inv25","inv28",
                       "inv32")
labels.list.covar <- c("How Often Child Gets Out of House","Number of Books",
                       "How Often Mom Reads to Child","Number of Soft/Role Play Toys",
                       "Number of Push/Pull Toys","How Often Child Eats With Mom/Dad",
                       "How Often Mom Talks to Child From Work","Number of Magazines",
                       "Child Has Tape Recorder/CD Player","How Often Child Is Taken to Museum",
                       "Child Has Musical Instrument","Family Receives Daily Newspaper",
                       "Child Receives Special Lessons/Activities",
                       "Child Is Taken to Musical Performances","How Often Child Sees Family Friends",
                       "Number of Times Praised Child Last Week",
                       "Number of Times Said Positive Things Last Week")

#'  Step 2. Remove observations with -100 scores. This operation returns a list of data.frames.
#'  The j-th element in the list is a data.frame excluding -100 scores for the j-th variable
#'  for all j in list.covar. For Example, the second element in list.data is a copy of dat
#'  such that variable 'inv02' no longer has -100 scores.
list.data <- lapply(list.covar, function(s,dat){inputNaN(var = s, data = dat)},dat)

#'  Step 3. Summary of results. This operation returns a list whose elements are summary tables.
#'  The j-th element in the list is the summary table for the j-th covariate in list.covar
list.sumtables <- lapply(1:length(list.covar), function(s) sumtable(var=list.covar[s],label = labels.list.covar[s],data = list.data[[s]]))

# Visualization. Summary table for the last variable
list.sumtables[[length(list.covar)]]



###' Replicate Table A9-3, supplement

#' Create a function to exclude obs with -100 value and generate a new variable
#' Pick the first observation of the same childid, because
#' observations with the same childid have the same value
#' @param var string, name of the variable
#' @param data dataset
#' @return a new dataset with a new variable added
inputNaN <- function(var, data){
  data[[paste('rep_',var,sep = '')]] <- data[[var]]
  data[[paste('rep_',var,sep = '')]][data[[paste('rep_',var,sep = '')]] < -99] <- NaN
  data <- data %>% group_by(childid) %>% 
    mutate(rep_first = as.numeric(row_number() == 1L) )
  data$rep_first[data$rep_first == 0] <- NaN
  data[[paste('rep_',var,sep = '')]] <- data[[paste('rep_',var,sep = '')]] * data$rep_first
  return(data)
}

#' Create a function to make summaries
#' @param var string, name of the variable
#' @param label string, label of the variable, a string
#' @param data dataset
#' @return a table
sumtable <- function(var, label, data){
  a <- paste('(\'', label,'\' = rep_',var ,')', sep = '')
  b <- '~ N + Mean * Arguments(fmt = \'%.3f\')+ SD * Arguments(fmt = \'%.3f\')'
  c <- datasummary(as.formula(paste(a,b)),
                   sparse_header = FALSE,
                   data = data)
  return(c)
}


#'  Step 1. Begin with a list of such variables. The elements  
#'  of the list correspond with rows in table A9-3 in CHS.
#'  The list contains:
#'  a) Mom's Arithmetic Reasoning Test Score
#'  b) Mom's Word Knowledge Test Score
#'  c) Mom's Paragraph Composition Test Score
#'  d) Mom's Numerical Operation Test Score
#'  e) Mom's Coding Speed Test Score
#'  f) Mom's Mathematical Knowledge Test Score
#'  g) Mom's Self-Esteem: "I am a person of worth"
#'  h) Mom's Self-Esteem: "I have good qualities"
#'  i) Mom's Self-Esteem: "I am a failure"
#'  j) Mom's Self-Esteem: "I have nothing to be proud of"
#'  k) Mom's Self-Esteem: "I have a positive attitude"
#'  l) Mom's Self-Esteem: "I wish I had more self-respect"
#'  m) Mom's Self-Esteem: "I feel useless at times"
#'  n) Mom's Self-Esteem: "I sometimes think I am no good"
#'  o) Mom's Rotter Score: "I have no control"
#'  p) Mom's Rotter Score: "I make no plans for the future"
#'  q) Mom's Rotter Score: "Luck is big factor in life"
#'  r) Mom's Rotter Score: "Luck plays big role in my life"


list.covar        <- c("asvab2","asvab3","asvab4","asvab5","asvab6","asvab8","se1","se2","se3","se5",
                       "se6","se8","se9","se10","rotter1","rotter2","rotter3","rotter4")
labels.list.covar <- c('Moms Arithmetic Reasoning Test Score', 'Moms Word Knowledge Test Score',
                       'Moms Paragraph Composition Test Score','Moms Numerical Operation Test Score',
                       'Moms Coding Speed Test Score', 'Moms Mathematical Knowledge Test Score',
                       'Moms Self-Esteem: I am a person of worth', 'Moms Self-Esteem: I have good qualities',
                       'Moms Self-Esteem: I am a failure', 'Moms Self-Esteem: I have nothing to be proud of',
                       'Moms Self-Esteem: I have a positive attitude',
                       'Moms Self-Esteem: I wish I had more self-respect',
                       'Moms Self-Esteem: I feel useless at times',
                       'Moms Self-Esteem: I sometimes think I am no good',
                       'Moms Rotter Score: I have no control',
                       'Moms Rotter Score: I make no plans for the future',
                       'Moms Rotter Score: Luck is big factor in life',
                       'Moms Rotter Score: Luck plays big role in my life')

#'  Step 2. Remove repeated observations and observations with -100 scores. 
#'  This operation returns a list of data.frames. The j-th element in the list is a data.frame 
#'  excluding -100 scores and repeated cells for the j-th variable
#'  for all j in list.covar. For Example, the first element in list.data is a copy of dat
#'  such that variable 'asvab2' no longer has -100 scores and repeated cells.
list.data <- lapply(list.covar, function(s,dat){inputNaN(var = s, data = dat)},dat)

#'  Step 3. Summary of results. This operation returns a list whose elements are summary tables.
#'  The j-th element in the list is the summary table for the j-th covariate in list.covar
list.sumtables <- lapply(1:length(list.covar), function(s) sumtable(var=list.covar[s],label = labels.list.covar[s],data = list.data[[s]]))

# Visualization. Summary table for the last variable
list.sumtables[[length(list.covar)]]




















