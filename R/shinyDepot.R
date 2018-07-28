
# shinyDepot makes it easy to deploy computation-intensive shiny apps. It
# decouples heavy processing tasks from interactive visualization tasks. There
# are two types of containers: interactive containers, and processing
# containers.

1. interactive container
	task 1: collect job inputs
		shinyDepot::submitJob()
	task 2: run results visualization
		shinyDepot::retrieveJob()
2. process container
	task: heavy processing
		shinyDepot::lurk()

#' Function that monitors a folder and runs a function when a file arrives in the
#' monitored folder. Run by lurker containers to check for new jobs to process.
#'
#' @param depotQueueDir The folder to watch for new job files
#' @param processFunctions A list that maps process classes to functions that process them.
 # the function to run on a new job file when found. 
 # Should take the absolulte file name as the sole argument.

lurk = function(depotQueueDir, processFunctions) {
	# list of process classes I process:
	names(processFunctions)
	processesRegex = paste0("[", paste0(names(processFunctions), collapse="|"), "]")
	while(TRUE) {
		jobFiles = lapply(names(processFunctions), function(x) {
			list.files(pattern="*.yaml", depotQueueDir, x)
		}
		processFunctions[[processName]]
		unlist(jobFiles)

		# If no new jobs were found, just wait a minute
		if (len(jobs) < 1) {
			Sys.sleep(60)
			continue
		}
		# If new jobs were found, process in time order
		details = file.info(jobs)
		jobs = jobs[order(as.POSIXct(details$mtime))]

		for (job in jobs) {
			# Run the function that will process that job
			setJobStatus(job$jobID, "initialized")
			processFunctions[[processName]](job)
			setJobStatus(job$jobID, "completed")
		}
	}
}

# @depotQueueDir The folder used by shinyDepot to hold the job queue. This
# folder must match the folder used by lurker containers that process new
# jobs

# @jobInfo a list of any information required to run the job
# @processName A key that specifies the type of job
# @container Name of or location of container that will proccess this 
#	 type of job
# @function The name of the function that will process the jobMeta object
# 	containing all the submitted job details

submitJob = function(depotQueueDir, datalist, processName) {
	jobMeta = list()
	jobMeta$jobID = #generate temp job has
	jobMeta$depotQueueDir = depotQueueDir
	jobMeta$processName = processName
	jobMeta$datalist = datalist
	jobMeta$status = "queued"
	# etc

	# Create a yaml config file to 'submit' the job.
	write.yaml(depotQueueDir, jobMeta)
	return(jobMeta$jobID)
}

# Given a specific jobID, retrieve the metadata for that job
retrieveJob = function(jobID) {
	# First, if the job has been processed, return the data
	# 
	resultsCache = paste0(depotResultsDir, jobID, ".Rdata")
	if (resultsCache) {
		load(resultsCache)
		return(resultsCache)
	}
	# if not, then check the results for status flags
	jobStatusFile = paste0(depotResultsDir, jobID, ".txt")
	status = read(jobStatusFile)
	return(status)

	# finally, if no status flags exist, the job has not initiated yet;
	# check to make sure such a job exists in the queue.
	jobMeta = paste0(depotQueueDir, jobID, ".yaml")
	return("Job is queued")

}

setJobStatus(jobID, status) {
		jobStatusFile = paste0(depotResultsDir, jobID, ".txt")
		write(jobStatusFile, status)
}








# task 1: submit job

job = list()
job$uploadedFile = "path/to/file"
job$referenceGenome = "hg38"
job$universe = "blah"
shinyDepot::submitJob(depotQueueDir, datalist=job)

# task 2: retrieve job and interactive results viewer

# parse URL
jobID = getJobIDFromURL()
jobStatus = shinyDepot::retrieveJob(jobID)

#display results viewer...



# task 3: process jobs



# A function that will run the LOLAweb process for a given "job" file.
# The job file should specify the path to the user uploaded file and
# any other user-selections provided

processLOLAwebJob = function(file, outfolder="/path/to/results/", resources=LWResources) {

	job = yaml::yaml.load(file)

	# Access the pre-loaded data
	regionDB = resources$regionDBs[jobs$genome]
	
	result = runLOLA(job$query, regionDB)

	# Now, store that result in the output folder,
	# which should then render correctly
	save(result, outfolder)
}

# Register any job class this container knows how to handle,
# and map those jobs to the function that can handle it.
processFunctions = list("LOLAweb" = "processLOLAwebJob")




# First, load up some data to save in this container
LWResources = list()
LWResources$regionDBs = list()
for (genome in genomes) {
	LWResources$regionDBs[[genome]] = LOLA::loadRegionDB("/path/to/genome")
}
LWResources$universes = list()

for (universe in universes) {
	LWResources$universes[[universe]] = LOLA::readbed("/path/to/universe")
}



# Now, just lurk, waiting for new jobs:
shinyDepot::lurk("/path/to/job/folder", processFunctions)


