# hash

hash <- function(alpha = TRUE, numeric = TRUE, length = 15) {

  if (alpha & !numeric) {

    string <- sample(LETTERS, length)

  } else if (!alpha & numeric) {

    string <- sample(1:9, length)

  } else if (alpha & numeric) {

    string  <- sample(c(LETTERS,1:9), length)

  } else if (!alpha & !numeric) {

    stop("Hash must be include letters, numbers, or both")

  }

  paste0(string, collapse = "")

}

# connect
connect <- function(db_url, db_name) {

  mongolite::mongo(url = db_url, db = db_name)

}


##################
# get session
# helper function from shinyFiles

getSession <- function() {
  session <- shiny::getDefaultReactiveDomain()

  if (is.null(session)) {
    stop(paste(
      "could not find the Shiny session object. This usually happens when a",
      "shinyjs function is called from a context that wasn't set up by a Shiny session."
    ))
  }

  session
}

