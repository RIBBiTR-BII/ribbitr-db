# ribbitr_dbcon_test_script.R
# Author: Cob Staines
# Purpose: Diagnostic script for ribbitr DB connection and query testing

# ----------------------
# Setup Logging
# ----------------------
log_file <- "ribbitr_dbcon_test_log.txt"
log_con <- file(log_file, open = "wt")
sink(log_con, type = "output")
sink(log_con, type = "message")

log <- function(msg) {
  message("\n* ", msg)
}

log_error <- function(e) {
  message("\nError: ", e$message)
}

test_query <- function(conn) {
  tryCatch({
    log("Running test query...")
    data_qpcr <- tbl(conn, Id("survey_data", "bd_qpcr_results")) %>%
      filter(qpcr_plate_name == "RIBBiTR_PanamaSwabs2022_10022023_Plate1") %>%
      collect()
    
    print(head(data_qpcr))
    return(data_qpcr)
  }, error = log_error)
}

# ----------------------
# Install & Load Packages
# ----------------------
log("Installing and loading required packages...")
tryCatch({
  if (!requireNamespace("librarian", quietly = TRUE)) {
    install.packages("librarian")
  }
  
  librarian::shelf(
    tidyverse, dbplyr, RPostgres, DBI,
    update_all = TRUE
  )
  
  log("Base packages loaded successfully.")
}, error = log_error)

# ----------------------
# Force update ribbitrrr
# ----------------------
log("Attempting to install/update ribbitrrr...")
tryCatch({
  librarian::shelf("RIBBiTR-BII/ribbitrrr", update_all = TRUE)
  log("ribbitrrr package loaded and updated.")
}, error = log_error)

# ----------------------
# Session Info
# ----------------------
log("Session Info:")
tryCatch({
  print(sessionInfo())
}, error = log_error)

# ----------------------
# Direct SSL DB Connection
# ----------------------
log("Attempting direct SSL connection...")
tryCatch({
  dbcon_ssl <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("ribbitr.host"),
    port = Sys.getenv("ribbitr.port"),
    dbname = Sys.getenv("ribbitr.dbname"),
    user = Sys.getenv("ribbitr.user"),
    password = Sys.getenv("ribbitr.password"),
    sslmode = "require",
    gssencmode = "disable"
  )
  log("SSL connection successful.")
  
  data_ssl <- test_query(dbcon_ssl)
}, error = log_error)

# ----------------------
# hopToDB() Connection
# ----------------------
log("Attempting hopToDB() connection...")
tryCatch({
  dbcon <- hopToDB("ribbitr")  # Replace with "ribbitr" if this was a typo
  log("hopToDB connection successful.")
  
  data_hop <- test_query(dbcon)
}, error = log_error)

# ----------------------
# Clean Up and Close Log
# ----------------------
log("Diagnostics complete. Closing log.")
sink(type = "message")
sink(type = "output")
close(log_con)
