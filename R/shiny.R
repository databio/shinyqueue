
###################
# parse_query
#' Title
#'
#'
#' @return
#' @export
#'
#' @examples
parse_query <- function() {
  
  session <- shiny::getDefaultReactiveDomain()

  shiny::reactive({ shiny::parseQueryString(session$clientData$url_search) })

}

##################
# retrieve job
#' Title
#'
#' @param con
#' @param cache_dir
#' @param encrypt
#'
#' @return
#' @export
#'
#' @examples
retrieve <- function(con,
                     cache_dir,
                     encrypt = TRUE) {

  check_con(con)
  
  session <- shiny::getDefaultReactiveDomain()
  
  # reactive for the url result param ... need to call it as query()
  query <- parse_query()

  shinyqueue <<- shiny::reactiveValues()
  
  shiny::observe({

    # is there a query and is it in the job db?
    if(length(query()) != 0 & any(query() %in% con$find()$job_id)) {

      # construct id query string for job db
      idstr <- paste0("{\"job_id\":\"", query(), "\"}")

      # is the job done?
      if(con$find(query = idstr)$status == "Completed") {

        shinyqueue$status <<- "Completed"

        
        # handle decryption if the job has been encrypted
        if (encrypt) {
          
          env <- new.env()
          
          simpleCache::simpleCache(cacheName = unlist(query()), 
                      assignToVariable = "cipher", 
                      cacheDir=cache_dir)
          
          cipher <- get("cipher", envir = env)
          
          # keyphrase
          key <- sodium::hash(charToRaw(unlist(query())))
          
          # decrypt results
          res <- unserialize(sodium::data_decrypt(cipher, key))
          
          shinyqueue$result <<- res
          
        } else {
          
          # read data
          simpleCache::simpleCache(cacheName = unlist(query()),
                                   cacheDir = cache_dir,
                                   assignToVariable = "res")
          
          shinyqueue$result <<- res
          
        }

        # focus on results tab
        shiny::updateNavbarPage(session, "mainmenu",
                                selected = "Results")

        # is the job queued
      } else if(con$find(query = idstr)$status == "Queued") {

        # set result object to "queued
        shinyqueue$status <<- "Queued"

        # force refresh every X seconds
        shiny::invalidateLater(5000, session)

      } else if(con$find(query = idstr)$status == "Running") {

        # set result object to "queued
        shinyqueue$status <<- "Running"

        # force refresh every X seconds
        shiny::invalidateLater(5000, session)

      }

      # and if the query is bad ... say so

    } else if (length(query() != 0)) {

      shinyqueue$bad <- "bad query"

    }

  })
}


# submit job
#' Title
#'
#' @param con
#' @param id
#' @param type
#' @param cache_dir
#' @param encrypt
#' @param status
#' @param time_queued
#' @param input
#'
#' @return
#' @export
#'
#' @examples
#'
submit <- function(con,
                   job_id,
                   job_type,
                   cache_dir,
                   encrypt = TRUE,
                   status = "Queued",
                   time_queued = Sys.time(),
                   input) {

  check_con(con)

  specs <- c(job_id = job_id,
             job_type = job_type,
             job_encrypted = encrypt,
             cache_dir = cache_dir,
             status = status,
             time_queued = time_queued,
             shiny::reactiveValuesToList(input))

  con$insert(specs)

}
