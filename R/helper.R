# hash

#' Title
#'
#' @param alpha
#' @param numeric
#' @param length
#'
#' @return
#' @export
#'
#' @examples
job_hash <- function(alpha = TRUE, numeric = TRUE, length = 15) {

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
#' Title
#'
#' @param db_url
#' @param db_name
#'
#'
#' @examples
connect <- function(db_url, db_name) {

  mongolite::mongo(url = db_url, db = db_name)

}


##################
# check connection

check_con <- function(con) {

  if(!"mongo" %in% class(con) | !con$info()$server$ok == 1)
    stop("The connection provided via con must be an active connection to a Mongo database")

}
