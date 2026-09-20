# download_rds.R
# Cross-platform (Mac / Linux / Windows) downloader for a public GitHub .rds file
get_datasets <- function(
  name,
  data_files = c(
    #"coffee_shop.Rds",
    #"fitness_tracking.Rds",
    #"restaurant_dining.Rds",
    #"escape_room.Rds",
    "women_clothing.Rds",
    "medical_insurance.Rds",
    "ai_student_impact.Rds",
    "tech_startup.Rds"
  ),
  github_user = "slicesofdata",
  github_repo = "dataviz-data",
  branch = "main"
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
  message("Gathering files...")

  # Check for project file
  if (!file.exists(here("dataviz-exercises-26.Rproj"))) {
    stop("Project file not found. Are you in the correct RStudio project?")
  }

  # Check for directory (as typed or lowercase)
  dir_path <- here("pages", name, "data")
  dir_path_lower <- here("pages", tolower(name), "data")

  if (dir.exists(dir_path)) {
    output_dir <- dir_path
  } else if (dir.exists(dir_path_lower)) {
    output_dir <- dir_path_lower
  } else {
    stop("Directory not found: ", dir_path, " or ", dir_path_lower)
  }

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

  for (file_name in data_files) {
    local_path <- path(output_dir, file_name)
    temp_path <- path(output_dir, paste0(file_name, ".tmp"))

    # Files sit at the top level of the branch — no subfolder remotely
    raw_url <- sprintf(
      "https://raw.githubusercontent.com/%s/%s/%s/%s",
      github_user,
      github_repo,
      branch,
      file_name
    )

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

# --- Auto-run when sourced ---
# If `name` already exists in the environment that sourced this file,
# call sync_data() using it. If `files` is also predefined, use that;
# otherwise fall back to the function's own default.
if (exists("name", inherits = TRUE)) {
  if (exists("data_files", inherits = TRUE)) {
    get_datasets(name = name, data_files = data_files)
  } else {
    get_datasets(name = name)
  }
}
