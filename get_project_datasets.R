# download_rds.R
# Cross-platform (Mac / Linux / Windows) downloader for a public GitHub .rds file
get_project_datasets <- function(
  name = "project",
  data_files = c(
    park_visits = "1980_2025_park_visits_irma_nps_gov.Rds",
    state_of_cal_salary = "state_of_california_salary_2011_2024.Rds",
    univ_of_cal_salary = "university_of_california_salary_2015_2024.Rds",
    cal_state_salary = "california_state_university_salary_2015_2024.Rds",
    la_county_salary = "los-angeles-county-salary-2021-2025.Rds",
    claremont_salary = "claremont_salary_2016_2025.Rds"
  ),
  #github_user = "slicesofdata",
  #github_repo = "dataviz-data",
  #branch = "main",

  url = "https://raw.githubusercontent.com/slicesofdata/dataviz-data/main"
) {
  # Install here if needed
  if (!requireNamespace("here", quietly = TRUE)) {
    install.packages("here")
  }
  if (!requireNamespace("fs", quietly = TRUE)) {
    install.packages("fs")
  }

  library(here)
  library(fs)

  # Check for directory (as typed or lowercase)
  dir_path <- here("pages", "project", "data")

  # Check for project type
  if (!fs::dir_exists(dir_path)) {
    stop(
      "pages/project/data/ directory not found. Are you in the correct RStudio project?"
    )
  }
  message("Gathering files...")

  if (dir.exists(dir_path)) {
    output_dir <- dir_path
  } else {
    stop("Directory not found: ", dir_path)
  }

  ##########################################################################
  ##########################################################################
  # Resolve friendly names to actual filenames

  resolve_file <- function(f) {
    key <- tolower(f)
    if (key %in% tolower(names(data_files))) {
      match_idx <- which(tolower(names(data_files)) == key)
      return(data_files[[match_idx]])
    } else if (grepl("\\.Rds$", f, ignore.case = TRUE)) {
      # Already looks like a real filename — use as-is
      return(f)
    } else {
      stop(
        "Unknown dataset: '",
        f,
        "'. Available options are: ",
        paste(names(data_files), collapse = ", ")
      )
    }
  }

  files <- vapply(files, resolve_file, character(1), USE.NAMES = FALSE)

  ############################################################################
  ############################################################################
  # Save as RDS — loop through each requested file

  # Ensure every filename ends in .rds
  data_files <- ifelse(
    grepl("\\.Rds$", data_files, ignore.case = FALSE),
    data_files,
    paste0(data_files, ".Rds")
  )

  results <- vector("list", length(data_files))
  names(results) <- data_files

  # now get the data file(s)
  for (file_name in data_files) {
    local_path <- path(output_dir, file_name)
    temp_path <- path(output_dir, paste0(file_name, ".tmp"))

    # Files sit at the top level of the branch — no subfolder remotely
    #raw_url <- sprintf(
    #  "https://raw.githubusercontent.com/%s/%s/%s/%s",
    #  github_user,
    #  github_repo,
    #  branch,
    #  file_name
    #)
    raw_url <- url

    result <- tryCatch(
      {
        download.file(
          url = raw_url,
          destfile = temp_path,
          mode = "wb",
          method = "libcurl",
          quiet = TRUE
        )

        # fs::file_move() overwrites the destination consistently on
        # Mac, Linux, AND Windows — no manual fallback needed
        file_move(temp_path, local_path)

        #message("Downloaded: ", file_name, " -> ", local_path)
        "success"
      },
      error = function(e) {
        if (file_exists(temp_path)) {
          file_delete(temp_path)
        }
        warning("Failed to download ", file_name, ": ", conditionMessage(e))
        "failed"
      }
    )

    results[[file_name]] <- result
  }

  # Summary
  failed <- names(results)[results == "failed"]
  if (length(failed) > 0) {
    message(
      "\nCompleted with ",
      length(failed),
      " failure(s): ",
      paste(failed, collapse = ", ")
    )
  } else {
    message("\nData file(s) downloaded successfully.")
    #message("\nAll ", length(data_files), " file(s) downloaded successfully.")
  }

  invisible(results)
}
