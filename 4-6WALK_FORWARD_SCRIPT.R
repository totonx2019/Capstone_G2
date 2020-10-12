#### we try the walk forward analysis performance ####
# 1. Initialization of Required Library
library(quantmod)
library(quantstrat)
library(tibbletime)
library(dplyr)
library(neuralnet)
asset_index <- "06"
wd <- "D:/trading/CAPSTONE/"
data_path <- paste0(paste0("D:/trading/CAPSTONE/toto_data/dataset",asset_index),"/")
source(paste0(wd,"CAPSTONE_LIBRARY.R"))

# 2. Defining Data and Features
# A. LOAD TARGET DATA
txt_file <- list.files(path = data_path,pattern = ".txt")
file_name <- paste0(data_path,txt_file)
data <- read.csv(file=file_name)
data <- as.xts(data[,c(2,3,4,5)],order.by = as.Date(data[,1],format = "%Y-%m-%d"))
result_path <- paste0(data_path,"RESULT/WFO/")
dir.create(result_path)
asset_name <- paste0("asset",asset_index)

# B. LOAD FEATURES DATA
csv_file <- list.files(path = data_path,pattern = ".csv")
csv_file <- tools::file_path_sans_ext(basename(csv_file))
for (name in csv_file){load_data(name)}

#### get combination of features data ####
# NOTES : The function is doing 2 things : 1. Normalized 2. Lag the signal (so can use directly)
combine_low <- get_combine_data(csv_file,'Low',NULL)
combine_high <- get_combine_data(csv_file,'High',NULL)
combine_open <- get_combine_data(csv_file,'Open',NULL)
combine_close <- get_combine_data(csv_file,'Close',NULL)
combine_ma_20    <- get_combine_data(csv_file,'Close',c('sma',20))
combine_ma_40    <- get_combine_data(csv_file,'Close',c('sma',40))
#### get target data in normalized form ####
low_target <- normalize(data$Low)
high_target <- normalize(data$High)
open_target <- normalize(data$Open)
close_target <- normalize(data$Close)
ma_20_target   <- normalize(na.omit(as.xts(sma(data$Close,20),order.by = index(data$Close))))
colnames(ma_20_target) <- "MA20"
ma_40_target   <- normalize(na.omit(as.xts(sma(data$Close,20),order.by = index(data$Close))))
colnames(ma_40_target) <- "MA40"

### COMBINING THE FEATURES WITH TARGET DATA FOR EASY SPLITTING
df_low <- cbind(combine_low,low_target)
df_low <- na.omit(df_low)
df_high <- cbind(combine_high,high_target)
df_high <- na.omit(df_high)
df_open <- cbind(combine_open,open_target)
df_open <- na.omit(df_open)
df_close <- cbind(combine_close,close_target)
df_close <- na.omit(df_close)
df_ma_20   <- cbind(combine_ma_20,ma_20_target)
df_ma_20   <- na.omit(df_ma_20)
df_ma_40   <- cbind(combine_ma_40,ma_40_target)
df_ma_40   <- na.omit(df_ma_40)

### with self lag signal
### COMBINING THE FEATURES WITH TARGET DATA FOR EASY SPLITTING
lag_target_low <- lag(low_target,1)
colnames(lag_target_low) <- 'lag_target_low'
df_low <- cbind(combine_low,lag_target_low,low_target)
df_low <- na.omit(df_low)
lag_target_high <- lag(high_target,1)
colnames(lag_target_high) <- 'lag_target_high'
df_high <- cbind(combine_high,lag_target_high,high_target)
df_high <- na.omit(df_high)
lag_target_open <- lag(open_target,1)
colnames(lag_target_open) <- 'lag_target_open'
df_open <- cbind(combine_open,lag_target_open,open_target)
df_open <- na.omit(df_open)
lag_target_close <- lag(close_target,1)
colnames(lag_target_close) <- 'lag_target_close'
df_close <- cbind(combine_close,lag_target_close,close_target)
df_close <- na.omit(df_close)
lag_target_ma_20 <- lag(ma_20_target,1)
colnames(lag_target_ma_20) <- 'lag_target_ma_20'
df_ma_20   <- cbind(combine_ma_20,lag_target_ma_20,ma_20_target)
df_ma_20   <- na.omit(df_ma_20)
lag_target_ma_40 <- lag(ma_40_target,1)
colnames(lag_target_ma_40) <- 'lag_target_ma_40'
df_ma_40   <- cbind(combine_ma_40,lag_target_ma_40,ma_40_target)
df_ma_40   <- na.omit(df_ma_40)

### 3. LOAD PARAMETERS AND FORMULA FOR FRAMEWORK TRADING (TO BE PLUGGED INTO 4)
low_f  <- as.formula(paste("Low ~", paste(colnames(df_low)[!colnames(df_low) %in% "Low"], collapse = " + ")))
high_f <- as.formula(paste("High ~", paste(colnames(df_high)[!colnames(df_high) %in% "High"], collapse = " + ")))
open_f <- as.formula(paste("Open ~", paste(colnames(df_open)[!colnames(df_open) %in% "Open"], collapse = " + ")))
close_f <- as.formula(paste("Close ~", paste(colnames(df_close)[!colnames(df_close) %in% "Close"], collapse = " + ")))
ma_20_f    <- as.formula(paste("MA20 ~", paste(colnames(df_ma_20)[!colnames(df_ma_20) %in% "MA20"], collapse = " + ")))
ma_40_f    <- as.formula(paste("MA40 ~", paste(colnames(df_ma_40)[!colnames(df_ma_40) %in% "MA40"], collapse = " + ")))


### 4. START BUIDLING WALK FORWARD OPTIMIZATION SIGNAL
# TIPS : WE USE ROLLIFY TO HELP US ACHIEVE
walk_forward_signal <- function(formula,df,chunk_number,oos_percent,ori_data)
{
  rolling_frame <- floor(nrow(df)/chunk_number)
  combine_frame <- c()
  
  i <- 1
  while (i <= nrow(df))
  {
    #processing
    end_frame <- i+rolling_frame
    if (end_frame>=nrow(df)){end_frame=nrow(df)}
    if (i==end_frame){break}
    process_data <- df[i:end_frame,]
    process_data_in  <- split_sample(process_data,0.7,1)
    process_data_out <- split_sample(process_data,0.7,2)
    ### Signal Processing
    # 1. Train the neural network
    nn <- neuralnet(formula, data=process_data_in, hidden=c(2,1), linear.output=FALSE, threshold=0.01)
    # 2. Use the network to generate output 
    process_data_out_features <- process_data_out[,c(1:(ncol(process_data_out)-1))]
    nn_output <- compute(nn, process_data_out_features)
    #nn_output <- lag(nn_output,1)
    nn_result <- as.xts(nn_output$net.result,order.by = as.Date(row.names(nn_output$net.result)))
    # 3. Denormalize the Data
    actual_denorm    <- denormalize(process_data_out[,ncol(process_data_out)],ori_data)
    nn_result_denorm <- denormalize(nn_result,ori_data)
    compare_table <- cbind(actual_denorm,nn_result_denorm)
    colnames(compare_table) <- c("Actual","Predict")
    # 4. Join the table
    if(i==1){combine_frame<- compare_table}
    else{combine_frame<- rbind(combine_frame,compare_table)}
    #loop code
    i <- i+nrow(process_data_out)
  }
  return(combine_frame)
}


#### 5. START FOR SOME TRADING RULES

### A. MA CROSSOVER
open_table  <- walk_forward_signal(open_f,df_open,3,0.3,data$Open)
high_table  <- walk_forward_signal(high_f,df_high,3,0.3,data$High)
low_table   <- walk_forward_signal(low_f,df_low,3,0.3,data$Low)
close_table <- walk_forward_signal(close_f,df_close,3,0.3,data$Close)
ma_20_table <- walk_forward_signal(ma_20_f,df_ma_20,3,0.3,na.omit(as.xts(sma(data$Close,20),order.by = index(data$Close))))
ma_40_table <- walk_forward_signal(ma_40_f,df_ma_40,3,0.3,na.omit(as.xts(sma(data$Close,40),order.by = index(data$Close))))

ma_signal <- cbind(ma_20_table$Predict,ma_40_table$Predict)
colnames(ma_signal) <- c("MA20","MA40")
ma_signal <- na.omit(ma_signal)
ma_signal$MA20_lag <- lag(ma_signal$MA20,1)
ma_signal$MA40_lag <- lag(ma_signal$MA40,1)
ma_signal$sign <- ifelse(ma_signal$MA20>ma_signal$MA40 & ma_signal$MA20_lag<ma_signal$MA40_lag,1,ifelse(ma_signal$MA20<ma_signal$MA40 & ma_signal$MA20_lag>ma_signal$MA40_lag,-1,NA))
ma_signal$sign <- na.locf(ma_signal$sign)

#ret <- (data$Close - lag(data$Close,1)) * 0.01
ret <- Return.calculate(data$Close)
ret <- ma_signal$sign*ret
ret <- na.omit(ret)
charts.PerformanceSummary(ret,geometric = TRUE)
dev.copy(png,paste0(result_path,"WFO_MA_CROSSOVER.png"))
dev.off()
print(table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE))
wfo_ma_cross <- table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE)

### B. CLOSE PREDICT VS CLOSE ACTUAL
#close_table$Actual <- lag(close_table$Actual,1)
close_table <- walk_forward_signal(close_f,df_close,3,0.3,data$Close)
close_table$Predict_Lag <- lag(close_table$Predict,1)
close_table$Sig <- ifelse(close_table$Predict>close_table$Actual & close_table$Predict> close_table$Predict_Lag,1,ifelse(close_table$Predict<close_table$Actual & close_table$Predict< close_table$Predict_Lag,-1,NA))
#close_table$Sig <- ifelse(close_table$Predict>close_table$Actual,1,ifelse(close_table$Predict<close_table$Actual,-1,NA))
#close_table$Sig <- na.locf(close_table$Sig)

#ret <- (data$Close - lag(data$Close,1)) * 0.01
#ret <- close_table$Sig*ret
ret <- Return.calculate(data$Close)
ret <- lag(close_table$Sig,1)*ret
ret <- na.omit(ret)
charts.PerformanceSummary(ret,geometric = TRUE)
dev.copy(png,paste0(result_path,"WFO_CLOSE_SIMPLE.png"))
dev.off()
print(table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE))
wfo_close_simple <- table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE)


### COMBINE CLOSE AND MA SIGNAL
combine_sign <- cbind(close_table$Sig,ma_signal$sign)
combine_sign$fin_sig <- ifelse(combine_sign$Sig==1 & combine_sign$sign==1,1,ifelse(combine_sign$Sig==-1 & combine_sign$sign==-1,-1,NA))
ret <- Return.calculate(data$Close)
ret <- lag(combine_sign$fin_sig,1)*ret
ret <- na.omit(ret)
charts.PerformanceSummary(ret,geometric = TRUE)
dev.copy(png,paste0(result_path,"WFO_COMBINE.png"))
dev.off()
print(table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE))
wfo_combine <- table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE)


#### COMBINE OHLC SIGNAL
open_table$Actual <- lag(open_table$Actual,1)
open_table$Predict_Lag <- lag(open_table$Predict,1)
open_table$Sig <- ifelse(open_table$Predict>open_table$Actual & open_table$Predict> open_table$Predict_Lag,1,ifelse(open_table$Predict<open_table$Actual & open_table$Predict< open_table$Predict_Lag,-1,NA))

high_table$Actual <- lag(high_table$Actual,1)
high_table$Predict_Lag <- lag(high_table$Predict,1)
high_table$Sig <- ifelse(high_table$Predict>high_table$Actual & high_table$Predict> high_table$Predict_Lag,1,ifelse(high_table$Predict<high_table$Actual & high_table$Predict< high_table$Predict_Lag,-1,NA))

low_table$Actual <- lag(low_table$Actual,1)
low_table$Predict_Lag <- lag(low_table$Predict,1)
low_table$Sig <- ifelse(low_table$Predict>low_table$Actual & low_table$Predict> low_table$Predict_Lag,1,ifelse(low_table$Predict<low_table$Actual & low_table$Predict< low_table$Predict_Lag,-1,NA))

close_table$Actual <- lag(close_table$Actual,1)
close_table$Predict_Lag <- lag(close_table$Predict,1)
close_table$Sig <- ifelse(close_table$Predict>close_table$Actual & close_table$Predict> close_table$Predict_Lag,1,ifelse(close_table$Predict<close_table$Actual & close_table$Predict< close_table$Predict_Lag,-1,NA))

combine_ohlc <- cbind(open_table$Sig,high_table$Sig,low_table$Sig,close_table$Sig)
colnames(combine_ohlc) <- c("Open","High","Low","Close")
combine_ohlc$Sig <- ifelse(combine_ohlc$Open==1 & combine_ohlc$High==1 & combine_ohlc$Low==1 & combine_ohlc$Close==1,1,
                           ifelse(combine_ohlc$Open==-1 & combine_ohlc$High==-1 & combine_ohlc$Low==-1 & combine_ohlc$Close==-1,-1,NA)
                           )
#combine_ohlc$Sig <- na.locf(combine_ohlc$Sig)
ret <- Return.calculate(data$Close)
ret <- lag(combine_ohlc$Sig,1)*ret
ret <- na.omit(ret)
charts.PerformanceSummary(ret,geometric = TRUE)
dev.copy(png,paste0(result_path,"WFO_OHLC.png"))
dev.off()
print(table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE))
wfo_ohlc <- table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE)



##### MA20 REAL VS PREDICT
ma_20_table$Predict_Lag <- lag(ma_20_table$Predict,1)
ma_20_table$Actual_Lag <- lag(ma_20_table$Actual,1)
ma_20_table$Sig <- ifelse(ma_20_table$Predict>ma_20_table$Actual & ma_20_table$Predict_Lag< ma_20_table$Actual_Lag,1,ifelse(ma_20_table$Predict<ma_20_table$Actual & ma_20_table$Predict_Lag> ma_20_table$Actual_Lag,-1,NA))

ret <- Return.calculate(data$Close)
#ret <- close_table$Sig*ret
ret <- lag(ma_20_table$Sig,1)*ret
ret <- na.omit(ret)
charts.PerformanceSummary(ret,geometric = TRUE)
dev.copy(png,paste0(result_path,"WFO_MA20.png"))
dev.off()
print(table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE))
wfo_ma_20 <- table.AnnualizedReturns(ret,Rf=0.000158,geometric = TRUE)



#### WRITE OUT AR 
result_table <- cbind(wfo_ma_cross,wfo_close_simple,wfo_combine,wfo_ohlc,wfo_ma_20)
colnames(result_table) <- c("WFO MA CROSSOVER","WFO CLOSE SIMPLE","WFO COMBINE","WFO OHLC","WFO MA 20 PRED")
rownames(result_table) <- c("Annualized Return","Annualized Std Dev","Annualized Sharpe (Rf=0.82%)")
write.csv(result_table,paste0(result_path,"AR.csv"),col.names = TRUE,row.names = TRUE)
