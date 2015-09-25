######################################################
# run_analysis.R
#
# Course Project of Getting and Cleaning Data Course
# Author: John Wu <webmaster@leapoahead.com>
######################################################

# Loading libraries
print("Loading libraries")
library('data.table', quietly = T)
library('reshape', quietly = T)

# Constants
uci.datasetUrl='https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
uci.path=getwd()
uci.datasetPath=file.path(uci.path, 'data')

# Helpers
uci.helpers.readAsDataTable <- function (path) {
  data.table(read.table(path))
}

# Download and extract dataset

if (!file.exists(uci.datasetPath)) {
  print("Downloading dataset");
  tmpfile <- tempfile()
  download.file(uci.datasetUrl, tmpfile, quiet = T)
  print("Extracting dataset")
  unzip(tmpfile, exdir=uci.datasetPath, junkpaths = T)
  unlink(tmpfile)
}

# Load data
print("Reading dataset")
uciData.train.x <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'X_train.txt'))
uciData.train.y <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'y_train.txt'))
uciData.train.sub <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'subject_train.txt'))
uciData.test.x  <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'X_test.txt'))
uciData.test.y  <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'y_test.txt'))
uciData.test.sub <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'subject_test.txt'))
uciData.features <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'features.txt'))

# Merge train and test data
names(uciData.train.y) <- "activityId"
names(uciData.test.y) <- "activityId"
names(uciData.train.sub) <- "subject"
names(uciData.test.sub) <- "subject"
uciData.train <- cbind(uciData.train.x, uciData.train.y, uciData.train.sub)
uciData.test  <- cbind(uciData.test.x, uciData.test.y, uciData.test.sub)
uciData.all <- rbind(uciData.train, uciData.test)
remove(uciData.train)
remove(uciData.test)
remove(uciData.train.x)
remove(uciData.test.x)
remove(uciData.train.y)
remove(uciData.test.y)
remove(uciData.train.sub)
remove(uciData.test.sub)

# Select measurements on mean and std
names(uciData.features) <- c('featureId', 'featureName')
featuresOnMeanOrStd <- uciData.features[grepl("mean\\(\\)|std\\(\\)", uciData.features$featureName),]
featureIdsOnMeanOrStd <- c(paste('V', featuresOnMeanOrStd$featureId, sep=''), 'activityId', 'subject')
uciData.all <- uciData.all[, featureIdsOnMeanOrStd, with = F]

# Set descriptive activity names
uciData.activityNames <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'activity_labels.txt'))
names(uciData.activityNames) <- c("activityId", "activityName")
setnames(uciData.all, paste0('V',featuresOnMeanOrStd$featureId), as.character(featuresOnMeanOrStd$featureName))

# Write tidy dataset
write.table(uciData.all, file="result.txt", row.names = F)