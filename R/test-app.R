#' Run tests for a Shiny application
#'
#' @param appDir Path to the Shiny application to be tested.
#' @param files Test script(s) to run. The .R extension of the filename is
#'   optional. For example, \code{"mytest"} or \code{c("mytest", "mytest2.R")}.
#'   If \code{NULL} (the default), all scripts in the tests/ directory will be
#'   run.
#' @param quiet Should output be suppressed? This is useful for automated
#'   testing.
#'
#' @export
testApp <- function(appDir = ".", files = NULL, quiet = FALSE) {
  testsDir <- file.path(appDir, "tests")

  found_files <- list.files(testsDir, pattern = "\\.[r|R]$")
  if (!is.null(files)) {
    # Strip .R extension from supplied filenames and found filenames
    files_no_ext <- sub("\\.[rR]$", "", files)
    found_files_no_ext <- sub("\\.[rR]$", "", found_files)

    # Keep only specified files
    idx <- match(files_no_ext, found_files_no_ext)

    if (any(is.na(idx))) {
      stop("Test files do not exist: ",
        paste0(files[is.na(idx)], collapse =", ")
      )
    }

    # Keep only specified files
    found_files <- found_files[idx]
  }

  # Run all the test scripts.
  if (!quiet) {
    message("Running ", appendLF = FALSE)
  }
  lapply(found_files, function(file) {
    name <- sub("\\.[rR]$", "", file)

    # Run in test directory, and pass the (usually relative) path as an option,
    # so that the printed output can print the relative path.
    withr::with_dir(testsDir, {
      withr::with_options(list(shinytest.app.dir = appDir), {
        env <- new.env(parent = .GlobalEnv)
        if (!quiet) {
          message(file, " ", appendLF = FALSE)
        }
        source(file, local = env)
      })
    })
  })

  if (!quiet) message("")  # New line

  # Compare all results
  results <- lapply(found_files, function(file) {
    name <- sub("\\.[rR]$", "", file)
    if (!quiet) {
      message("====== Comparing ", name, " ======")
    }
    snapshotCompare(appDir, name, quiet = quiet)
  })

  invisible(list(
    appDir = appDir,
    results = results
  ))
}
