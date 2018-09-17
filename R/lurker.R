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
                 process = "process.R",
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
        inprocess <- con$find(queued)[i,]

        # get id json string for updating db
        idstr <- paste0("{\"id\":\"", inprocess$id, "\"}")

        # message
        message(paste0("Running job ", inprocess$id))

        # set status to running
        con$update(idstr,
                   update = '{"$set":{"status":"Running"}}')

        source(process, local = TRUE)

        # create file pointer and save cache
        fp <- paste0(cache_dir, inprocess$id, ".rds")
        saveRDS(res, file = fp)

        # set status to completed
        con$update(idstr,
                   update = '{"$set":{"status":"Completed"}}')

        # check queue depth
        qdepth <- con$count(queued)

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
