# shinyqueue

shinyqueue makes it easy to deploy computation-intensive shiny apps. It decouples heavy processing tasks from interactive visualization tasks. 

Shiny is mostly useful for interactivity, and most effective interactivity happens quickly and therefore doesn't require large computational resources. But we find we want to build apps that provide interactive visualization of results of a more computationally intensive processing, which leads to a problem: "when Shiny performs long-running calculations or tasks on behalf of one user, it stalls progress for all other Shiny users that are connected to the same process" ([R Studio Blog](http://blog.rstudio.com/2018/06/26/shiny-1-1-0/)).

For a standalone shiny app that a user runs locally, this isn't a problem -- the user just runs the compute process, waits for a few minutes, and they interacts with the results. But it becomes an issue for servers because when shiny server is processing the heavy computation, the R process will be using all available CPUs, compromising the lower-intensity interactivity for all other users. Shiny 1.1.0 (from 06/2018) address this issue by enabling [asynchronous operations](http://blog.rstudio.com/2018/06/26/shiny-1-1-0/) using the `future` and `promises` package. This decouples the heavy processing step from the interactive steps and goes a long way toward improving user experience for heavy-computation multi-user shiny apps. But it leaves a few more advanced problems; for example: dealing with duplicated high-memory processes, deploying across server hardware, interfacing with non-R processes, running multiple shiny apps with different requirements, and retaining and sharing results.

shinyqueue is an alternative way to implement asynchronous operations that addresses these issues. It does not rely on using the `future` or `promises` package, making it straightforward to use. It completely decouples the interactive and computation R processes, acting like an ultralight job queuing system, all written in R and interconnected with shiny.

## How shinyqueue works

To understand how shinyqueue works, let's divide our web app into tasks. A computationally intensive app that will benefit from shinyqueue is one that needs to do 3 things: 1) collect the job request from the user; 2) process the request (heavy computation); and 3) render the results, typically with something reactive. In a typical shiny framework, you would use just a single R process to do all 3 of these tasks. Instead, we can divide them, and then use `shinyqueue` to help the tasks communicate with one another. Here's how each task would use `shinyqueue`:

- Task 1: collect job request from user
	Use `shinyqueue::submitJob()` to register a job in the `shinyqueue`. The app should then forward the user to the results page for the job.

- Task 2: heavy computation
	In the background, the computation  uses `shinyqueue::lurk()` to check for submitted jobs, and then runs them when they are found. The user never needs to interact directly with this process, so the high processor use never makes the shiny server unresponsive. This process needs to `load(shinyqueue)` for the `lurk()` function, but it does not depend on `shiny` because the user never interacts with it.

- Task 3: render results visualization
	The results page uses `shinyqueue::retrieveJob()` to retrieve job metadata, which will indicate the status of the job (`queued`, `running`, or `complete`), along with a pointer to the actual results when a job is complete. The process can then read in these results and render them in shiny.

Though there are 3 tasks, in practice, we really only need 2 different types of R process, because Task 1 and Task 3 are both pretty low resource use. Because they both have fairly low resource requirements, they can live in the same process without a major hit to performance. Therefore, all we need to do is divide our app into two types of R process: interactive processes (which will run shiny), and computation processes (which prepare the results shiny will render). In a minimal use case, you could have just one of each type of process, but on a busy server, it's also possible to imagine multiple process of each type. As a bonus, each process can also live in its own container, dividing responsibilities and allowing multiple different apps to use the same `shinyqueue`.

Both process types will `load(shinyqueue)` and use `shinyqueue` functions that will enable these processes to really easily communicate with one another.


## Example of task 1: submit job

```
job = list()
job$uploadedFile = "path/to/file"
job$referenceGenome = "hg38"
job$universe = "blah"
shinyqueue::submitJob(depotQueueDir, datalist=job)
```

## Example of task 2: retrieve job and interactive results viewer

```
# parse URL
jobID = getJobIDFromURL()
jobStatus = shinyqueue::retrieveJob(jobID)

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
shinyqueue::lurk("/path/to/job/folder", processFunctions)
```

