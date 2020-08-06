### Chapter 2.4  (Creating a data package -> Upload a package) ###

##############################
# Step 1: ID myself as admin by passing temp token into R
  # Sign into ADC with ORCiD: https://arcticdata.io/catalog/data
  # My profile -> Settings -> Authentication Token -> Token for DataONE R 
  # Run in console
##############################

# NOTE: this is just a placeholder to remind you to get temp token and run in console
# options(dataone_test_token = "...")

##############################
# Step 2: load packages
##############################

library(devtools)
library(dataone)
library(datapack)
library(EML)
library(remotes)
library(XML)
library(arcticdatautils)
library(datamgmt)

##############################
# Step 3: set node to the test Arctic node (we'll work exclusively on this node for training)
  # once this is set, you can publish an object
##############################

cn_staging <- CNode('STAGING')
adc_test <- getMNode(cn_staging,'urn:node:mnTestARCTIC')

##############################
# Step 4: publish data and metadata to the *test* site
##############################

# data
data_path <- "data/Exercise1_reformatted_table.csv"
data_formatId <- "text/csv"
data_pid <- publish_object(adc_test,
                           path = data_path,
                           format_id = data_formatId) # output is PID of newly published object

# metadata
metadata_path <- "metadata/Aggregated_Land_Cover_Data_for_Circum_Arctic.xml"
metadata_formatId <- format_eml("2.2.0")
metadata_pid <- publish_object(adc_test,
                               path = metadata_path,
                               format_id = metadata_formatId)

##############################
# Step 5: Create a resource map 
##############################

resource_map_pid <- create_resource_map(adc_test,
                                        metadata_pid = metadata_pid,
                                        data_pids = data_pid)


##############################
# View your new data set by appending the metadata PID to the end of the URL: test.arcticdata.io/#view/…
##############################
