library(sparklyr)
sc <- spark_connect(master = "local")

iris_tbl <- copy_to(sc, iris)
flights_tbl <- copy_to(sc, nycflights13::flights, "flights")
batting_tbl <- copy_to(sc, Lahman::Batting, "batting")
src_tbls(sc)
flights_tbl %>% filter(dep_delay == 2)

mtcars_tbl <- copy_to(sc, mtcars)
partitions <- mtcars_tbl %>%
  filter(hp >= 100) %>%
  mutate(cyl8 = cyl == 8) %>%
  sdf_random_split(training = 0.5, test = 0.5, seed = 1099)

fit <- partitions$training %>%
  ml_linear_regression(response = "mpg", features = c("wt", "cyl"))
fit

spark_disconnect_all() # Disconnect spark