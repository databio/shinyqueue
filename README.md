# shinyDepot

shinyDepot makes it easy to deploy computation-intensive shiny apps. It decouples heavy processing tasks from interactive visualization tasks. There  are two types of containers: interactive containers, and processing containers.

Since shiny is mostly useful for interactivity, and most effective interactivity happens quickly and therefore doesn't require large computational resources. But we find we want to build apps that provide interactive visualization of results of a more computationally intensive processing. For example, in LOLAweb, we require 1-2 minutes of processing to prepare the results, which we will then 

For a standalone shiny app that a user runs locally, this isn't a problem -- the user just runs the compute process, waits for a few minutes, and they interacts with the results. But it becomes an issue for servers because when shiny server is processing the heavy computation, the R process will be using all available CPUs, compromising the lower-intensity interactivity for all other users.

shinyDepot solves this problem by decoupling the heavy processing step from the interactive steps. It acts like an ultralight job queuing system, all written in R and interconnected with shiny.

## Explanation

In a typical shiny framework, you would use just a single R process to read, process, and display your results. To make shinyDepot work, we divide the work into two types of R process: interactive processes (which will run shiny), and computation processes (which prepare the results shiny will render). In a minimal use case, you could have just one of each type of process, but on a busy server, it's also possible to imagine multiple process of each type. Each process can live in its own container. 

The interactive process really has two tasks: first, to receive the request from the user (which will tell us how to run the actual computation); and second, to render results. These two tasks can be further separated, but because they both have fairly low resource requirements, they can also live in the same process without a major hit to performance.

The computation process has only a single task: to take the user request (which was received by the interactive process) and run it!

Both process types will `load(shinyDepot)` and use `shinyDepot` functions that will enable these processes to really easily communicate with one another. Let's break that down:

1. Process type 1: interactive
	- Task 1: collect job request from user
		Use `shinyDepot::submitJob()` to register a job in the `shinyDepot`. The app should then forward the user to the results page for their job.
	- Task 2: render results visualization
		The results page uses `shinyDepot::retrieveJob()` to retrieve job metadata, which will indicate the status of the job (`queued`, `running`, or `complete`), along with a pointer to the actual results when a job is complete. The process can then read in these results and render them in shiny.
2. Process type 2: computation
	- Task: heavy computation
		In the background, the computation process uses `shinyDepot::lurk()` to check for submitted jobs, and then runs them when they are found. The user never needs to interact directly with this process, so the high processor use never makes the shiny server unresponsive. This process needs to `load(shinyDepot)` for the `lurk()` function, but it does not depend on `shiny` because the user never interacts with it.


## Example of task 1: submit job

```
job = list()
job$uploadedFile = "path/to/file"
job$referenceGenome = "hg38"
job$universe = "blah"
shinyDepot::submitJob(depotQueueDir, datalist=job)
```

## Example of task 2: retrieve job and interactive results viewer

```
# parse URL
jobID = getJobIDFromURL()
jobStatus = shinyDepot::retrieveJob(jobID)

#display results viewer...
```

## Example of task 3: process jobs


```
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
```

