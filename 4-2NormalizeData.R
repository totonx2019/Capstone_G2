data_path <- "D:/toto_data/"


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

get_combine_data_org <- function(csv_file,input,special="")
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
      #combine <- normalize(combine)
      #combine <- return_sign(combine)
    }
    else
    {
      temp <- get(name)[,input]
      if(special=="sma"){temp <- na.omit(as.xts(mean_roll_20(temp),order.by = index(temp)))}
      #temp <- normalize(temp)
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

#------------------------------------------
#---------------MAIN PROGRAM---------------
#------------------------------------------
#LOAD CORRELATION DATA
csv_file <- list.files(path = data_path,pattern = ".csv")
csv_file <- tools::file_path_sans_ext(basename(csv_file))
for (name in csv_file){load_data(name)}
#-------------
csv_file

#### get combination of data ####
combine_close <- get_combine_data(csv_file,'Close')
combine_close <- na.omit(combine_close)

combine_close_org <- get_combine_data_org(csv_file,'Close')
combine_close_org <- na.omit(combine_close_org)

#Show data
head(combine_close)
head(combine_close_org)
