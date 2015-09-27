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

print("Processing")

# Merge train and test data
setnames(uciData.train.y, names(uciData.train.y), c("activityId"))
setnames(uciData.test.y, names(uciData.test.y), c("activityId"))
setnames(uciData.train.sub, names(uciData.train.sub), c("subject"))
setnames(uciData.test.sub, names(uciData.test.sub), c("subject"))
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
setnames(uciData.features, names(uciData.features), c('featureId', 'featureName'))
featuresOnMeanOrStd <- uciData.features[grepl("mean\\(\\)|std\\(\\)", uciData.features$featureName),]
featureIdsOnMeanOrStd <- c(paste('V', featuresOnMeanOrStd$featureId, sep=''), 'activityId', 'subject')
uciData.all <- uciData.all[, featureIdsOnMeanOrStd, with = F]

# Set descriptive activity names
uciData.activityNames <- uci.helpers.readAsDataTable(file.path(uci.datasetPath, 'activity_labels.txt'))
setnames(uciData.activityNames, names(uciData.activityNames), c("activityId", "activityName"))
setnames(uciData.all, paste0('V',featuresOnMeanOrStd$featureId), as.character(featuresOnMeanOrStd$featureName))

# Write tidy dataset
write.table(uciData.all, file="dataset.txt", row.names = F)

# Generate dataset required by step 5
uciData.all$activityId <- factor(uciData.all$activityId)
uciData.all$subject <- factor(uciData.all$subject)
uciData.grouped <- split(uciData.all, list(uciData.all$activityId, uciData.all$subject))
uciData.summaryMean <- list()
for (item in uciData.grouped) {
  item$subject <- as.numeric(item$subject)
  item$activityId <- as.numeric(item$activityId)
  uciData.summaryMean <- c(uciData.summaryMean, colMeans(item))
}
uciData.summaryMean <- matrix(
  unlist(uciData.summaryMean),
  ncol = nrow(featuresOnMeanOrStd) + 2,
  byrow = T)
colnames(uciData.summaryMean) <- colnames(uciData.grouped$`1.1`)
write.table(uciData.summaryMean, 'summary_mean.txt', row.names = F)