###############################
# lurk
# runs in background to process incoming jobs
#' Title
#'
#' @param running
#' @param process
#' @param con
#' @param cache_dir
#' @param interval
#'
#' @return
#' @export
#'
#' @examples
#'
lurk <- function(running = TRUE,
                 process,
                 con,
                 cache_dir = "cache/",
                 interval = 10) {

  check_con(con)

  while(running) {

    # check queue depth
    queued <- '{"status":"Queued"}'
    qdepth <- con$count(queued)

    if (qdepth > 0) {

      for (i in 1:qdepth) {

        # get job at iterator
        input <<- con$find(queued)[i,]

        # get id json string for updating db
        idstr <- paste0("{\"id\":\"", input$job_id, "\"}")

        # message
        message(paste0("Running job ", input$job_id))

        # set status to running
        con$update(idstr,
                   update = '{"$set":{"status":"Running"}}')

        # evaluate function passed in the process argument via job_type
        res <- eval(substitute(process[[unlist(input$job_type)]]))

        # create file pointer and save cache
        fp <- paste0(cache_dir, input$job_id, ".rds")
        saveRDS(res, file = fp)

        # set status to completed
        con$update(idstr,
                   update = '{"$set":{"status":"Completed"}}')

        # check queue depth
        qdepth <- con$count(queued)

        # cleanup
        rm(input, envir = .GlobalEnv)

      }

    } else {

      # print message, write to log, etc
      message("Waiting for next job ... ")
      # wait a moment  ...
      Sys.sleep(interval)
      # check if there's a new job yet
      qdepth <- con$count(queued)

    }

  }

}
