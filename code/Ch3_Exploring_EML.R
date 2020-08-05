### Ch. 3 Exploring EML

##############################
# Step 0: load packages
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
# Step 1: Need to be in member node to explore file
##############################

cn_staging <- CNode('STAGING')
adc_test <- getMNode(cn_staging, 'urn:node:mnTestARCTIC')

##############################
# Step 2: read in and view doc for crude view of the EML file
##############################

doc <- read_eml(getObject(adc_test, "urn:uuid:558eabf1-1e91-4881-8ba3-ef8684d8f6a1"))
View(doc)

# explore further
doc$dataset # view data set element
doc$dataset$creator # view data set creator

# pressing tab now will bring up a list since creator is a series-type of object
#doc$dataset$creator[[1]]$

##############################
# Step 3: use the eml_get() function to explore EML
# takes any chunk of EML and returns all instances of the specified element (examples below)
# eml_get(doc, "entity")
##############################

doc <- read_eml(system.file("example-eml.xml", package = "arcticdatautils"))

eml_get(doc, "creator")
eml_get(doc, "boundingCoordinates")
eml_get(doc, "url")

##############################
# Step 3: or use the eml_get_simple() function as a simplified alternative 
# eml_get_simple(doc$dataset$otherEntity, "entityName")
##############################

# Practice question: Which creators have a surName "Mecum"?

# example using which_in_eml():
n <- which_in_eml(doc$dataset$creator, "surName", "Mecum")
doc$dataset$creator[[n]] # answer

# example using combo of eml_get_simple() and which(): 
ent_names <- eml_get_simple(doc$dataset$creator, "surName")
i <- which(ent_names == "Mecum")
doc$dataset$creator[[i]] # answer
