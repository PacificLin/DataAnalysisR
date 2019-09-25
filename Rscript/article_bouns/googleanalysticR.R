browser()
library(googleAuthR)
library(googleAnalyticsR)
ga_auth()
# authorize the connection with Google Analytics servers.
MyView <- ga_account_list()
# setting ga account parameter.
myid <- 96873079
start_date <- "10daysAgo"
end_date <- "yesterday"

# If TRUE will split up the call to avoid sampling. It will export all data.
df1 <- dim_filter("landingPagePath", "REGEXP", "article", not = TRUE)
my_filter_clause <- filter_clause_ga4(list(df1))

f2 <- google_analytics(myid,
                       date_range = c(start_date, end_date), 
                       metrics = c("sessions","Users",
                                   "bounces"),
                       dimensions = c("source", "landingPagePath", "date"),
                       dim_filters = my_filter_clause,
                       anti_sample = T)