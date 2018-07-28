# shinyDepot

shinyDepot makes it easy to deploy computation-intensive shiny apps. It decouples heavy processing tasks from interactive visualization tasks. There  are two types of containers: interactive containers, and processing containers.

Since shiny is mostly useful for interactivity, and most effective interactivity happens quickly and therefore doesn't require large computational resources. But we find we want to build apps that provide interactive visualization of results of a more computationally intensive processing. For example, in LOLAweb, we require 1-2 minutes of processing to prepare the results, which we will then 

For a standalone shiny app that a user runs locally, this isn't a problem -- the user just runs the compute process, waits for a few minutes, and they interacts with the results. But it becomes an issue for servers because when shiny server is processing the heavy computation, the R process will be using all available CPUs, compromising the lower-intensity interactivity for all other users.

shinyDepot solves this problem by decoupling the heavy processing step from the interactive steps. It acts like an ultralight job queuing system, all written in R and interconnected with shiny.

## Explanation

You need two types of process (or container): interactive ones (which will run shiny) and computation ones (which prepare the results shiny will display).

1. interactive container
	task 1: collect job inputs
		shinyDepot::submitJob()
	task 2: run results visualization
		shinyDepot::retrieveJob()
2. process container
	task: heavy processing
		shinyDepot::lurk()


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

