get_data <- function(name, files, ...) {
  url <- "https://raw.githubusercontent.com/slicesofdata/data-viz-data/main/sync_data.R"

  tmp <- tempfile(fileext = ".R")
  download.file(url, destfile = tmp, method = "libcurl", quiet = TRUE)
  source(tmp)
  file.remove(tmp)

  sync_data(name = name, files = files, ...)
}
