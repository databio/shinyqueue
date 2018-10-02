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
                 interval = 10) {

  check_con(con)

  while(running) {

    # check queue depth
    queued <- '{"status":"Queued"}'
    qdepth <- con$count(queued)

    if (qdepth > 0) {

      for (i in 1:qdepth) {

        # get job at iterator
        # input <<- con$find(queued)[i,]
        pos <- 1
        envir = as.environment(pos)
        
        assign("input", 
               con$find(queued)[i,], 
               envir = envir)

        # get id json string for updating db
        idstr <- paste0("{\"job_id\":\"", input$job_id, "\"}")

        # message
        message(paste0("Running job ", input$job_id))

        # set status to running
        con$update(idstr,
                   update = '{"$set":{"status":"Running"}}')

        # evaluate function passed in the process argument via job_type
        res <- eval(substitute(process[[unlist(input$job_type)]]))
        
        cache_dir <- unlist(input$cache_dir)
        
        
        # should the result be encrypted?
        if (unlist(input$job_encrypted)) {
          
          # set up key and hash for encryption
          key <- sodium::hash(charToRaw(unlist(input$job_id)))
          msg <- serialize(res,connection = NULL)
          
          cipher <- sodium::data_encrypt(msg, key)
          
          simpleCache::simpleCache(cacheName = unlist(input$job_id), 
                                   instruction = { cipher },
                                   noload = TRUE,
                                   cacheDir = cache_dir)
        } else {
          
          # cache result
          simpleCache::simpleCache(cacheName = unlist(input$job_id), 
                                   instruction = res,
                                   cacheDir = cache_dir)
          
        }
        
        # set status to completed
        con$update(idstr,
                   update = '{"$set":{"status":"Completed"}}')

        # check queue depth
        qdepth <- con$count(queued)

        # cleanup
        rm(input, envir = envir)

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
