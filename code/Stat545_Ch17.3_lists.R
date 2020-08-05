##############################
# create a list
##############################

a <- list("cabbage", pi, TRUE, 4.3)

##############################
# change list components
##############################

# create names for list componenets
names(a) <- c("veg", "dessert", "myAim", "number")

# change names
a <- list(veg = "cabbage", dessert = pi, myAim = TRUE, number = 4.3)
names(a)

##############################
# Indexing: if you request a single element from a list, do you want: 
  # (a) a list of length 1 containing only that element, or 
  # (b) the element itself

# (a) use square brackets []
# (b) use dollar sign $ or double square brackets [[]]
##############################

# example list to index 
b <- list(veg = c("cabbage", "eggplant"),
           tNum = c(pi, exp(1), sqrt(2)),
           myAim = TRUE,
           joeNum = 2:6)

str(b)
length(b)
class(b)
mode(b)

##############################
# ways to get a single list element (i.e. option b)
##############################

b[[2]] # index with positive integer

str(b$myAim) # use dollar sign and element name

b[["tNum"]] # index with length 1 logical vector

str(b[["tNum"]]) # we want tNum itself, a length 3 numeric vector

iWantThis <- "joeNum" # indexing with length 1 character object
b[[iWantThis]] # we get joeNum itself, a length 4 integer vector

b[[c("joeNum", "veg")]] # does not work! can't get > 1 elements!

##############################
# ways to get more than one element: 
# index vector-style with single square brackets (the returned value will always be a list)
##############################

names(b)

str(b[c("tNum", "veg")]) # returns list of length 2

b["veg"] # indexing by length 1 character vector

str(b["veg"]) # returns list of length 1

length(b["veg"]) # verify list of 1

length(b["veg"][[1]]) # contrast with the length of the veg vector itself
