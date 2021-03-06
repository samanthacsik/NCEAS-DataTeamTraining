##########################################################################
##########################################################################
##########################################################################
### Ch. 2 Creating a Data Package
##########################################################################
##########################################################################
##########################################################################

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

##########################################################################
##########################################################################
##########################################################################
### Ch. 4 Editing EML Exercises
##########################################################################
##########################################################################
##########################################################################

##############################
# get token, load packages, set nodes, load data packages, load EML file
##############################

# REMEMBER TO GET TOK(from test.arcticdata.io)

# load data packages
rm_pid <- "resource_map_urn:uuid:39b5af4c-43d0-4b3f-b83a-bb2a6cde089a"
pkg <- get_package(adc_test, # member node
                   rm_pid, # resource map
                   file_names = TRUE)

# NOTE! now you can get pids directly from the pkg object:
# metadata_pid <- pkg$metadata
# data_pid <- pkg$data
# resource_pid <- pkg$resource_map

# Load EML file (remember: EML = metadata)
doc <- read_eml(getObject(adc_test, pkg$metadata))

# IMPORTANT NOTE: when editing data packages, make sure that you're working with the most recent update
# use following commands to ensure you have the most recent resource map:
rm_pid_original <- "resource_map_urn:uuid:39b5af4c-43d0-4b3f-b83a-bb2a6cde089a"
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

# launch Shiny app (commented out bc script sourced into Ch5_Updating_a_data_package.R)
EML::shiny_attributes(data = my_data)

# read in attributes list generated in shiny app above
my_attributes<- read.csv("data/Attributes_Table.csv")
my_attributes <- as.data.frame(my_attributes)

# first view units
# standardUnits <- EML::get_unitList()
# View(standardUnits$units)

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

# add these to all data processing scripts to make metadata FAIR
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)

##########################################################################
##########################################################################
##########################################################################
### Ch. 5 Updating a data package
##########################################################################
##########################################################################
##########################################################################

##############################
# Exercise 4 (5.3)
##############################

# make an edit to `my_data` by changing one of the colnames to "TEST"
my_data_new <- my_data %>% 
  rename(TEST = GLC2000_class)

# save edited data
write.csv(my_data_new, here::here("data", "Exercise4_reformatted_table_new.csv"), row.names = FALSE)

# updated the data file in the package with the edited table using `update_object`
my_updated_data_file <- update_object(adc_test,
                        pid = pkg$data,
                        path = "data/Exercise4_reformatted_table_new.csv",
                        format_id = "text/csv")

# update your package using `publish_update()`
my_update <- publish_update(adc_test,
                            metadata_pid = "urn:uuid:ae578c82-4b7c-43ea-ae8a-d97bd45c3a0b", # how do i find this??
                            resource_map_pid = "resource_map_urn:uuid:ae578c82-4b7c-43ea-ae8a-d97bd45c3a0b", # can use rm_pid
                            data_pids = c(pkg$data, my_updated_data_file), # add new pid
                            metadata_path = eml_path,
                            public = FALSE) # FIGURE OUT HOW TO FIND THIS ON THE WEB PORTAL + "NEWER VERSIONS LINK"???

##########################################################################
##########################################################################
##########################################################################
### Ch. 6 Editing system metadata
##########################################################################
##########################################################################
##########################################################################

##############################
# Exercise 5 (6.3)
##############################

# read in the system metadata from the file you uploaded previously
my_sysmeta <- getSystemMetadata(adc_test, my_updated_data_file) # is this right????

# check that the `fileName` and `formatId` are set correctly 
# fileName = "Exercise1_reformatted_table.csv; formatId = "text/csv"
# extensions are supposed to match, so I think this is good???

# set the rights and access for all objects with your ORCiD (i.e. make sure that the researcher has permission to edit and view the dataset)
# manually set ORCiD
subject <- 'https://orcid.org/0000-0002-5300-3075'

# change to `http` (convention)
subject <- sub("^https://", "http://", subject)

# set the rights and access
set_rights_and_access(adc_test,
                      pids = c(pkg$metadata, pkg$data, pkg$resource_map),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))
