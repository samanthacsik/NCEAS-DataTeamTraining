### Ch. 4 Editing EML

##############################
# Step 4.1: get token, load packages, set nodes, load data packages, load EML file
##############################

# REMEMBER TO GET TOKEN FIRST (from test.arcticdata.io)

# load packages
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
# Step 4.2 Edit and EML element
##############################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.2.1 Edit an EML element with strings
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# change the title
doc$dataset$title <- "New Title"

# set multiple titles (data sets can have more than one)
doc$dataset$title <- list("New Title", "Second New Tite")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.2.2 Edit EML with the "EML" package
  # the eml() family of functions provides the sub-elements as arguments (which is functionally creating a named list)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# use the `eml$elementName()` helper functions to pre-populate options with RStudio's autocomplete functionality if you don't know the sub-elements
# example: doc$dataset$abstract <- eml$abstract() <TAB> shows that the abstract element can either take the `section` or `para` sub-elements
doc$dataset$abstract <- eml$abstract() #THIS ISN'T WORKING FOR ME

# both of these are equivalent
doc$dataset$abstract <- eml$abstract(para = "A concise but thorough description of the who, what, where, when, why, and how of a dataset.")
doc$dataset$abstract <- list(para = "A concise but thorough description of the who, what, where, when, why, and how of a dataset.")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.2.3 Edit EML with objects
  # i.e. build new object to replace old object
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Ex: create two sets of keywords and save to objects
kw_list_1 <- eml$keywordSet(keywordThesaurus = "LTER controlled vocabulary",
                            keyword = list("bacteria", "carnivorous plants", "genetics", "thresholds"))


kw_list_2 <- eml$keywordSet(keywordThesaurus = "LTER core area",
                            keyword = list("populations", "inorganic nutrients", "disturbance"))

# now insert both keyword lists into our EML document
doc$dataset$keywordSet <- list(kw_list_1, kw_list_2)

##############################
# Step 4.3 FAIR (findable, accessible, interoperable, reusable) data practices.
##############################

# add these to all data processing scripts to make metadata more FAIR
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)

##############################
# Step 4.4 Edit attributeLists
  # attributes can exist in EML for dataTable, otherEntity, and spatialVector data objects
##############################

# use the following commands to examine and existing attribute table already in an EML file
# NOTE: i represents the index of the series element you are interested in
# NOTE: these wont' run

i = 1
# If they are stored in an otherEntity (submitted from the website by default)
attributeList <- EML::get_attributes(doc$dataset$otherEntity[[i]]$attributeList)
# Or if they are stored in a dataTable (usually created by a datateam member)
attributeList <- EML::get_attributes(doc$dataset$dataTable[[i]]$attributeList)
# Or if they are stored in a spatialVector (usually created by a datateam member)
attributeList <- EML::get_attributes(doc$dataset$spatialVector[[i]]$attributeList)

attributes <- attributeList$attributes
print(attributes)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.4.1 Edit attributes
  # need to be stored in data.frame
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# create manually (but this is annoying AF):
attributes <- data.frame(
  
  attributeName = c('Date', 'Location', 'Region','Sample_No', 'Sample_vol', 'Salinity', 'Temperature', 'sampling_comments'),
  attributeDefinition = c('Date sample was taken on', 'Location code representing location where sample was taken','Region where sample was taken', 'Sample number', 'Sample volume', 'Salinity of sample in PSU', 'Temperature of sample', 'comments about sampling process'),
  measurementScale = c('dateTime', 'nominal','nominal', 'nominal', 'ratio', 'ratio', 'interval', 'nominal'),
  domain = c('dateTimeDomain', 'enumeratedDomain','enumeratedDomain', 'textDomain', 'numericDomain', 'numericDomain', 'numericDomain', 'textDomain'),
  formatString = c('MM-DD-YYYY', NA,NA,NA,NA,NA,NA,NA),
  definition = c(NA,NA,NA,'Sample number', NA, NA, NA, 'comments about sampling process'),
  unit = c(NA, NA, NA, NA,'milliliter', 'dimensionless', 'celsius', NA),
  numberType = c(NA, NA, NA,NA, 'real', 'real', 'real', NA),
  missingValueCode = c(NA, NA, NA,NA, NA, NA, NA, 'NA'),
  missingValueCodeExplanation = c(NA, NA, NA,NA, NA, NA, NA, 'no sampling comments'),
  
  stringsAsFactors = FALSE)

# or use Shiny app to build attribute info in 3 ways ((a) from data, (b) from existing attribute file, (c) from scratch)
# NOTE: THESE WON'T RUN 
# (a) from data (recommended)
EML::shiny_attributes(data = data)
# (b) from existing attributret file
EML::shiny_attributes(attributes_table = attributes_table)
# (c) from scratch
atts <- EML::shiny_attributes()

# once done editing a table in the app, quit the app and tables will be assigned to `atts` as a list of dfs

# for simple attribute corrections, use datamgmt::edit_attribute(); THIS WON'T RUN
new_attribute <- datamgmt::edit_attribute(doc$dataset$dataTable[[1]]$attributeList$attribute[[1]], 
                                          attributeName = 'date_and_time', 
                                          domain = 'dateTimeDomain', 
                                          measurementScale = 'dateTime')
# insert new version back into EML doc; THIS WON'T RUN
doc$dataset$dataTable[[1]]$attributeList$attribute[[1]] <- new_attribute 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.4.2 Edit custom units
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# EML has a list of units that can be added to an EML file; find these using this code:
standardUnits <- EML::get_unitList()
View(standardUnits$units)

# verify that your unit is not on this list before building a custom unit list (as a df with specific fields below)
# example that can be used as a template:
custom_units <- data.frame(
  
  id = c('siemensPerMeter', 'decibar'),
  unitType = c('resistivity', 'pressure'),
  parentSI = c('ohmMeter', 'pascal'),
  multiplierToSI = c('1','10000'),
  abbreviation = c('S/m','decibar'),
  description = c('siemens per meter', 'decibar'),
  
  stringsAsFactors = FALSE)

# add custom units to additionalMetadata using the following command:
unitlist <- set_unitList(custom_units, as_metadata = TRUE)
doc$additionalMetadata <- list(metadata = list(unitList = unitlist))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.4.3 Edit factors
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# build factors by hand by using named character vectors 
Location <- c(CASC = "Cascade Lake", CHIK = "Chikumunik Lake", HEAR = "Heart Lake", NISH = "Nishlik Lake")
Region <- c(W_MTN = "West region, locations West of Eagle Mountain", E_MTN = "East region, locations East of Eagle Mountain")

# then convert them to a data.frame
factors <- rbind(data.frame(attributeName = "Location", code = names(Location), definition = unname(Location)),
                 data.frame(attributeName = "Region", code = names(Region), definition = unname(Region)))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.4.4 Finalize attributeList
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# once you have your attributes,factors, custom units, you can add them to EML projects; DOES NOT RUN
attributeList <- EML::set_attributes(attributes = attributes, 
                                     factors = factors)
# the attributeList must them be added to a dataTable

##############################
# Step 4.5 Set physical
##############################

# set physical aspects of the data object by building a physical object from a data PID that exists in your package; REMEMBER TO SET THE MEMBER NODE TO test.arcticdata.io!
physical <- arcticdatautils::pid_to_eml_physical(adc_test, pkg$data[[i]])

# or simply set the physical by inputting the data PID:
physical2 <- arcticdatautils::pid_to_eml_physical(adc_test, "urn:uuid:c04c42ec-f85c-46c2-957c-a81fdb6fe308")
# the physical must then be assigned to the data object

# or set the physical by hand (not recommended)
id <- 'urn:uuid:c04c42ec-f85c-46c2-957c-a81fdb6fe308' # this should be an actual PID
path <- 'data/' # path to data table
physical <- EML::set_physical(objectName = 'Exercise1_reformatted_table.csv',
                              size = as.character(file.size(path)),
                              sizeUnit = 'bytes',
                              authentication = digest(path, algo="sha1", serialize=FALSE, file=TRUE),
                              authMethod = 'SHA-1',
                              numHeaderLines = '1',
                              fieldDelimiter = ',',
                              url = paste0('https://cn.dataone.org/cn/v2/resolve/', id))

# A SUPERIOR WORKFLOW: publish or update your data first and then use `pid_to_eml_physical()` to set the physical

##############################
# Step 4.6 Edit dataTables
  # first edit/create an `attributeList` and set the physical; then create a new dataTable using `eml$dataTable()`
##############################

# create data table; DOES NOT RUN
dataTable <- eml$dataTable(entityName = "A descriptive name for the data (does not need to be the same as the data file)",
                           entityDescription = "A description of the data",
                           physical = physical,
                           attributeList = attributeList)

# add `dataTable` to the EML
doc$dataset$dataTable <- dataTable

# if you want need to add a second `dataTable` (bc of unpacking problems)
doc$dataset$dataTable <- list(doc$dataset$dataTable, dataTable)

# if there is more than one `dataTable` in your dataset, return to the more straightforward construction of:
doc$dataset$dataTable[[i]] <- dataTable # i is the index you with to insert your dataTable into

# to add a list of dataTables to avoid unpacking problems, first create a list of `dataTables`
dts <- list() # create an empty list
for(i in seq_along(tables_you_need)){
  dataTable <- eml$dataTable(entityName = dataTables$entityName,
                             entityDescription = dataTable$entityDescription,
                             physical = physical,
                             attributeList = attributeList)
  
  dts[[i]] <- dataTable # add to the list
}

# after getting list of `dataTables`, assign the resulting list to `dataTable` EML
doc$dataset$dataTable <- dts

# use `eml_otherEntity_to_dataTable()` to move items in `otherEntity` over to `dataTable` (by default, the online submission adds all entities as `otherEntity` even when they should probably be `dataTable`)
x <- eml_otherEntity_to_dataTable(doc,
                             1, # which otherEntities you want to conver, for multipleuse - 1:5
                             validate_eml = F) # set this to False if the physical or attribures are not added

##############################
# Step 4.7 Edit otherEntities
##############################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.7.1 Remove otherEntities
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# to remove an `otherEntity` (useful if a data object is originally listed as an otherEntity and then transferred to a `dataTable`)
doc$dataset$otherEntity[[i]] <- NULL

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.7.2 Creat otherEntities
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# first be sure to pubslih/update yoru data object first (if not already on DataONE MN); then build your otherEntity:
otherEntity <- arcticdatautils::pid_to_eml_entity(adc_test, pkg$data[[i]])

# OR build the`otherEntity` of a data object not in your package by inputting the data `PID`
otherEntity <- arcticdatautils::pid_to_eml_entity(adc_test, "urn:uuid:c04c42ec-f85c-46c2-957c-a81fdb6fe308", # mn, "your_data_pid"
                                                  entityType = "otherEntity", 
                                                  entityName = "Entity Name", 
                                                  entityDescription = "Description about entity")

# the `otherEntity` must then be set to the EML:
doc$dataset$otherEntity <- otherEntity

# if you have more than one `otherEntity` object in the EML already, you can add the new one like this:
doc$dataset$otherEntity[[i]] <- otherEntity # where i is set to the number of existing entities + 1

# REMEMBER: if you only have one `otherEntity` and you are trying to add another, you have to run:
doc$dataset$otherEntity <- list(otherEntity, doc$dataset$otherEntity)

##############################
# Step 4.8 Semantic annotations
##############################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.8.1 How annotations are used
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# no exercise here, but check out this dataset: https://arcticdata.io/catalog/view/doi%3A10.18739%2FA2KW57J9Q, which includes sementic annothations

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.8.2 Entity-level annotations
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# to add annotations to the `attributeList` you need info about the `propertyURI` and `valueURI`
doc$dataset$dataTable[[i]]$attributeList$attribute[[i]]$annotation # returns NULL bc attributeList not define

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4.8.3 Ontologies used/ 4.8.3.1 OBOE: The Extensible Observation Ontology
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# no exercise here, but check out the OBOE ontology, which covers: Overvations, Entities, Characteristics, and Protocols
