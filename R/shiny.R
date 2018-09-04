
###################
# parse_query
parse_query <- function(session = getSession()) {

  shiny::reactive({ shiny::parseQueryString(session$clientData$url_search) })

}

##################
# retrieve job
retrieve <- function(session = getSession(),
                     cacheDir = "cache/",
                     db_url,
                     db_name) {

  con <- connect(db_url, db_name)

  query <- reactive({ shiny::parseQueryString(session$clientData$url_search) })

  dat <<- reactiveValues()

  observe({

    # is there a query and is it in the job db?
    if(length(query()) != 0 & any(query() %in% con$find()$id)) {

      # construct id query string for job db
      idstr <- paste0("{\"id\":\"", query(), "\"}")

      # is the job done?
      if(con$find(query = idstr)$status == "Completed") {

        dat$status <<- "Completed"

        # read data
        dat$rdist <<- readRDS(file = paste0(cacheDir, query(), ".rds"))

        # focus on results tab
        updateNavbarPage(session, "mainmenu",
                         selected = "Results")

        # is the job queued
      } else if(con$find(query = idstr)$status == "Queued") {

        # set result object to "queued
        dat$status <<- "Queued"

        # force refresh every X seconds
        invalidateLater(5000, session)

      } else if(con$find(query = idstr)$status == "Running") {

        # set result object to "queued
        dat$status <<- "Running"

        # force refresh every X seconds
        invalidateLater(5000, session)

      }

      # and if the query is bad ... say so

    } else if (length(query() != 0)) {

      dat$bad <- "bad query"

    }

  })
}
