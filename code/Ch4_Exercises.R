### Ch. 4 Editing EML Exercises

##############################
# get token, load packages, set nodes, load data packages, load EML file
##############################

# REMEMBER TO GET TOKEN FIRST (from test.arcticdata.io)

# load packages
# library(tidyverse)
library(devtools)
library(dataone)
library(datapack)
library(EML)
library(remotes)
library(XML)
library(arcticdatautils)
library(datamgmt)

# source Ch2 file to get resource map pid (this will also set nodes)
source("code/Ch2_Creating_a_data_package.R")

# load data packages
rm_pid <- "resource_map_urn:uuid:e9822a3a-080d-42a5-9c42-38e5cbf56d57"
pkg <- get_package(adc_test, # member node
                   rm_pid, # resource map
                   file_names = TRUE)

# NOTE! now you can get pids directly from the pkg object:
metadata_pid <- pkg$metadata
data_pid <- pkg$data
resource_pid <- pkg$resource_map

# Load EML file (remember: EML = metadata)
doc <- read_eml(getObject(adc_test, pkg$metadata))

# IMPORTANT NOTE: when editing data packages, make sure that you're working with the most recent update
# use following commands to ensure you have the most recent resource map:
rm_pid_original <- "resource_map_urn:uuid:e9822a3a-080d-42a5-9c42-38e5cbf56d57"
all_rm_versions <- get_all_versions(adc_test, rm_pid_original)
rm_pid <- all_rm_versions[length(all_rm_versions)]
print(rm_pid)

##############################
# Exercise 3a (4.9)
  # metadata for the dataset created in Exercise 2 was not very complete; here we will add an attribute and physical to our entity (csv file)
  # replace existing `dataTable` with a new `dataTable` object... 
  # ...with an `attributeList` and `physical` section that you write in R with the above commands
##############################

# load data file
my_data <- read.csv(here::here("data", "Exercise1_reformatted_table.csv"))
my_data <- as.data.frame(my_data) # is this necessary??

# launch Shiny app
EML::shiny_attributes(data = my_data)

# read in attributes list generated in shiny app above
my_attributes<- read.csv("data/Attributes_Table.csv")
my_attributes <- as.data.frame(my_attributeList)

# first view units
standardUnits <- EML::get_unitList()
View(standardUnits$units)

# build custom list (b/c of km^2 10^6)
custom_units <- data.frame(
  
  id = c("kilometer2106", "percentage"), # these need to match `unit` in downloaded Attributes_Table.csv
  unitType = c("area", "dimensionless"),
  parentSI = c("meter", "dimensionless"),
  multiplierToSI = c("1000000", "1"),
  abbreviation = c("km^2 10^6", "%"),
  description = c("square kilometer times 10^6", "percent, one part per hundred parts"),
  
  stringsAsFactors = FALSE)

# add custom units to `additionalMetadata`
unitlist <- set_unitList(custom_units, as_metadata = TRUE)
doc$additionalMetadata <- list(metadata = list(unitList = unitlist))

# finalize attributeList 
my_attributeList <- EML::set_attributes(attributes = my_attributes)

# build a `physical` object from the data `PID`
my_physical <- arcticdatautils::pid_to_eml_physical(adc_test, data_pid)

# now add attributeList and physical to dataTable
dataTable <- eml$dataTable(entityName = "Land cover of permafrost zones in the Circum-Arctic (2000)",
                           entityDescription = "Aggregated land cover data for Circum-Arctic permafrost zones (2000)",
                           physical = my_physical,
                           attributeList = my_attributeList)

# replace whatever dataTable elements already exist in EML:
doc$dataset$dataTable <- dataTable

##############################
# Exercise 3b (4.15)
  # after adding more metadata, we want to publish the dataset to test.arcticdata.io but need to first:
    # validate metadata using `eml_validate`
    # use the checklist to review your submission
    # make edits where necessary
  # once `eml_validate` returns TRUE, go ahead and run `write_eml` and `publish_update`
##############################

# validate
eml_validate(doc)

# save EML
eml_path <- "eml/my_first_eml.xml"
write_eml(doc, eml_path)

# publish update
update <- publish_update(adc_test,
                         metadata_pid = pkg$metadata,
                         resource_map_pid = pkg$resource_map,
                         data_pids = pkg$data,
                         metadata_path = eml_path,
                         public = FALSE)

# run `datamgmt::qa_package()` to check for correctness of distribution URLs for each data object & congruence of metadata and data
qa_package(adc_test, pkg$resource_map)
