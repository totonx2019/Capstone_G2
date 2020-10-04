library(quantmod)
library(quantstrat)
library(tibbletime)
library(dplyr)

#------------------------------------------
#------------------DEFINE------------------
#------------------------------------------
data_path <- "D:/toto_data/"
data_file <- paste0(data_path,"XAUUSD1440.txt")
baseAsset <- read.csv(file=data_file)
baseAsset <- as.xts(baseAsset[,c(2,3,4,5)],order.by = as.Date(row.names(baseAsset),format = "%m/%d/%Y"))


#------------------------------------------
#-------------SUPPORT FUNCTION-------------
#------------------------------------------
### FINANCIAL INDICATOR HERE ###
#1. moving average 20
mean_roll_20 <- rollify(mean, window = 20)


### CUSTOMIZED FUNCTION TO LOAD DATA ###
load_data <- function (string)
{
  #Read all csv files in a folder
  temp <- read.csv(file=paste0(data_path,paste0(string,'.csv')))
  temp <- as.xts(temp[,c(2,3,4,5)],order.by = as.Date(temp$Date,format="%Y-%m-%d"))
  assign(string,temp,envir = .GlobalEnv)
}
#-------------

get_combine_data <- function(csv_file,input,special="")
{
  count <- 1
  combine <- 0
  for (name in csv_file)
  {
    if (count==1)
    {
      combine <- get(name)[,input]
      if(special=="sma")
        {
            combine <- na.omit(as.xts(mean_roll_20(combine),order.by = index(combine)))
        }
      combine <- normalize(combine)
      #combine <- return_sign(combine)
    }
    else
    {
      temp <- get(name)[,input]
      if(special=="sma"){temp <- na.omit(as.xts(mean_roll_20(temp),order.by = index(temp)))}
      temp <- normalize(temp)
      #temp <- return_sign(temp)
      combine <- cbind(combine,temp)
    }
    count <- count+1
  }
  ###we fill the value with NA.LOCF
  #combine <- na.locf(combine)
  colnames(combine) <- csv_file
  ### dont forget to lag the signal for prediction
  combine <- lag.xts(combine,k=1)
  #combine <- scale(combine)
  return (combine)
}
#-------------


#### NORMALIZE THE DATA ####
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}
#-------------
denormalize <- function(x,ori_data)
{
  return(x*(max(ori_data) - min(ori_data))+min(ori_data))
}
#-------------

return_sign <- function(x)
{
  x <- Return.calculate(x)
  x <- ifelse(x>0,1,0)
  return(x)
}
#-------------

#### IN-OUT SAMPLE SPLIT ####
split_sample <- function (data,split_ratio,type)
{
  #### TYPE : 1 = IN-SAMPLE; TYPE : 2 = OUT-SAMPLE
  in_sample_ratio <- split_ratio
  out_sample_ratio <- 1-in_sample_ratio
  data_in_sample <- data[c(1:round(nrow(data)*in_sample_ratio)),]
  data_out_sample <- data[c((round(nrow(data)*in_sample_ratio)+1):nrow(data)),]
  if (type == 1){return(data_in_sample)}
  if (type == 2){return(data_out_sample)}
}

#------------------------------------------
#---------------MAIN PROGRAM---------------
#------------------------------------------
#LOAD CORRELATION DATA
csv_file <- list.files(path = data_path,pattern = ".csv")
csv_file <- tools::file_path_sans_ext(basename(csv_file))
for (name in csv_file){load_data(name)}
#-------------


#### get combination of data ####
combine_low <- get_combine_data(csv_file,'Low')
combine_low <- na.omit(combine_low)
combine_high <- get_combine_data(csv_file,'High')
combine_high <- na.omit(combine_high)
combine_open <- get_combine_data(csv_file,'Open')
combine_open <- na.omit(combine_open)
combine_close <- get_combine_data(csv_file,'Close')
combine_close <- na.omit(combine_close)
combine_ma    <- get_combine_data(csv_file,'Close','sma')
combine_ma    <- na.omit(combine_ma)

#Show data
head(combine_close)
#-------------

#### Normalize baseAsset to [0..1] ####
low_target <- normalize(baseAsset$Low)
high_target <- normalize(baseAsset$High)
open_target <- normalize(baseAsset$Open)
close_target <- normalize(baseAsset$Close)
ma_target   <- normalize(na.omit(as.xts(mean_roll_20(baseAsset$Close),order.by = index(baseAsset$Close))))
colnames(ma_target) <- "MA"

#Show data
head(close_target)
#-------------

#### Create ANN dataset ####
df_low <- cbind(combine_low,low_target)
df_low <- na.omit(df_low)
df_high <- cbind(combine_high,high_target)
df_high <- na.omit(df_high)
df_open <- cbind(combine_open,open_target)
df_open <- na.omit(df_open)
df_close <- cbind(combine_close,close_target)
df_close <- na.omit(df_close)
df_ma   <- cbind(combine_ma,ma_target)
df_ma   <- na.omit(df_ma)
#-------------


##### SPLIT THE DATA INTO TRAINING AND TESTING 70:30#####
df_low_in_sample <- split_sample(df_low,0.7,1)
df_low_out_sample <- split_sample(df_low,0.7,2)
df_high_in_sample <- split_sample(df_high,0.7,1)
df_high_out_sample <- split_sample(df_high,0.7,2)
df_open_in_sample <- split_sample(df_open,0.7,1)
df_open_out_sample <- split_sample(df_open,0.7,2)
df_close_in_sample <- split_sample(df_close,0.7,1)
df_close_out_sample <- split_sample(df_close,0.7,2)
df_ma_in_sample <- split_sample(df_ma,0.7,1)
df_ma_out_sample <- split_sample(df_ma,0.7,2)
#-------------


##### BUILD PRIDICTION FROM NEURALNET #####
#install.packages("neuralnet")
library(neuralnet)
low_f  <- as.formula(paste("Low ~", paste(colnames(df_low)[!colnames(df_low) %in% "Low"], collapse = " + ")))
high_f <- as.formula(paste("High ~", paste(colnames(df_high)[!colnames(df_high) %in% "High"], collapse = " + ")))
open_f <- as.formula(paste("Open ~", paste(colnames(df_open)[!colnames(df_open) %in% "Open"], collapse = " + ")))
close_f <- as.formula(paste("Close ~", paste(colnames(df_close)[!colnames(df_close) %in% "Close"], collapse = " + ")))
ma_f    <- as.formula(paste("MA ~", paste(colnames(df_ma)[!colnames(df_ma) %in% "MA"], collapse = " + ")))

nn_low <- neuralnet(low_f, data=df_low_in_sample, hidden=c(2,1), linear.output=FALSE, threshold=0.01)
nn_high <- neuralnet(high_f, data=df_high_in_sample, hidden=c(2,1), linear.output=FALSE, threshold=0.01)
nn_open <- neuralnet(open_f, data=df_open_in_sample, hidden=c(2,1), linear.output=FALSE, threshold=0.01)
nn_close <- neuralnet(close_f, data=df_close_in_sample, hidden=c(2,1), linear.output=FALSE, threshold=0.01)
nn_ma <- neuralnet(ma_f, data=df_ma_in_sample, hidden=c(2,1), linear.output=FALSE, threshold=0.01)
#-------------


#------------------------------------------
#---------------VALIDATION---------------
#------------------------------------------
##### PLOT THE NET #####
plot(nn_low)


### TEST ACCURACY ####
check_accuracy <- function (data_in_sample,data_out_sample,neural_net,ori_data,type)
{
  ### IF TYPE == 1 : RETURN IN SAMPLE ACCURACY
  ### IF TYPE == 2 : RETURN OUT SAMPLE ACCURACY
  #In Sample Test
  data_in_sample_test <- data_in_sample[,c(1:(ncol(data_in_sample)-1))]
  nn_in_sample_results <- compute(neural_net, data_in_sample_test)

  #Denormalize the data
  data_in_sample[,ncol(data_in_sample)] <- denormalize(data_in_sample[,ncol(data_in_sample)],ori_data)
  nn_in_sample_results_denorm <- denormalize(nn_in_sample_results$net.result,ori_data)
  
  frame <- data.frame(actual = data_in_sample[,ncol(data_in_sample)], prediction = nn_in_sample_results_denorm)
  colnames(frame) <- c("Actual","Prediction")
  predicted=frame$Prediction 
  actual=frame$Actual
  comparison=data.frame(predicted,actual)
  deviation=((actual-predicted)/actual)
  comparison=data.frame(predicted,actual,deviation)
  accuracy=1-abs(mean(deviation))
  
  #Out Sample Test
  data_out_sample_test <- data_out_sample[,c(1:(ncol(data_out_sample)-1))]
  nn_out_sample_results <- compute(neural_net, data_out_sample_test)

  #Denormalize the data
  data_out_sample[,ncol(data_out_sample)] <- denormalize(data_out_sample[,ncol(data_out_sample)],ori_data)
  nn_out_sample_results_denorm <- denormalize(nn_out_sample_results$net.result,ori_data)
  
  out_frame <- data.frame(actual = data_out_sample[,ncol(data_out_sample)], prediction = nn_out_sample_results_denorm)
  colnames(out_frame) <- c("Actual","Prediction")
  out_predicted=out_frame$Prediction 
  out_actual=out_frame$Actual
  out_comparison=data.frame(out_predicted,out_actual)
  out_deviation=((out_actual-out_predicted)/out_actual)
  out_comparison=data.frame(out_predicted,out_actual,out_deviation)
  out_accuracy=1-abs(mean(out_deviation))
  
  if(type==1){return(accuracy)}
  else{return(out_accuracy)}
}
#-------------

check_accuracy(df_low_in_sample,df_low_out_sample,nn_low,xauusd$Low,1)
check_accuracy(df_low_in_sample,df_low_out_sample,nn_low,xauusd$Low,2)
check_accuracy(df_high_in_sample,df_high_out_sample,nn_high,xauusd$High,1)
check_accuracy(df_high_in_sample,df_high_out_sample,nn_high,xauusd$Low,2)
check_accuracy(df_open_in_sample,df_open_out_sample,nn_open,xauusd$Open,1)
check_accuracy(df_open_in_sample,df_open_out_sample,nn_open,xauusd$Open,2)
check_accuracy(df_close_in_sample,df_close_out_sample,nn_close,xauusd$Close,1)
check_accuracy(df_close_in_sample,df_close_out_sample,nn_close,xauusd$Close,2)
check_accuracy(df_ma_in_sample,df_ma_out_sample,nn_ma,na.omit(as.xts(mean_roll_20(xauusd$Close),order.by = index(xauusd$Close))),1)
check_accuracy(df_close_in_sample,df_close_out_sample,nn_close,na.omit(as.xts(mean_roll_20(xauusd$Close),order.by = index(xauusd$Close))),2)

