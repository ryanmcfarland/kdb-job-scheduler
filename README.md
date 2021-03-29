# kdb-job-scheduler

q/KDB+ -> App to mimic a job scheduler across multiple hosts / machines similer to Autosys.

## Motivation

I wanted to make this job-scheduler app as on the projects I have worked on in the past, most either use only an internal cron kdb system or the internal crontab. I wanted to try and make an app that could be used across multiple hosts / worker agents to perform batch jobs.

Note: It's not perfect but it gives a good baseline for something I want to work on in the future.

## How-To - (Still a work in progress)

1. Set envirnoment variables
2. Create job json configs within the config/jobs subfolder.
3. These configs get picked up on runtime and upserted into an internal jobs table on the main process.
4. The main process will send commands to the worker processes on the various connected hosts based on the sTime or job condition. 
5. Worker process will run the command via a subprocess, grep for SUCCESS or FAILURE in the logname and report back to the main process on completion.
6. Any jobs dependant on completed job will then be ready to run on the next loop.

## Example - Schuduler RunTime

```
Start all process -> /home/ryanm/code/kdb-scheduler/scripts/bash/startup.sh

Connect to main (localhost:5001): .scheduler.jobs
```

**id**|**name**|**host**|**sTime**|**interval**|**dependant**|**status**|**reason**|**cmd**
:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
1|test-1-a|test1|2021.03.29D15:34:06.114197000|00:01:00.000| |SUCCESS| |"/home/ryanm/test1.sh"
2|test-1-b|test1|2021.03.29D15:33:06.313308000|00:00:00.000|test-1-a|SUCCESS| |"/home/ryanm/test1.sh"
3|test-2|test2|2021.03.29D15:34:45.815369000|00:02:00.000| |FAILED|test-2-20210329153245707.log|"/home/ryanm/test2.sh"

### Example Job Logs
- Success
```
Checking log: test-1-a

[2021.03.29 15:36:06.611 DESKTOP-IBII84O ryanm] INFO: Running: /home/ryanm/test1.sh

hello

[2021.03.29 15:36:06.617 DESKTOP-IBII84O ryanm] INFO: JOB SUCCESS
```
- Failure
```
Checking log: test-2-20210329152739707.log

[2021.03.29 15:30:45.586 DESKTOP-IBII84O ryanm] INFO: Running: /home/ryanm/test2.sh

/home/ryanm/code/kdb-scheduler//scripts/bash//execute.sh: 1: eval: /home/ryanm/test2.sh: not found

[2021.03.29 15:30:45.589 DESKTOP-IBII84O ryanm] ERROR: JOB FAILURE - EXITING WITH ERROR 7
```
- Job History
```
Connect to main (localhost:5001): .scheduler.history
```

**date**|**id**|**name**|**sTime**|**eTime**|**result**|**logname**
:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
2021.03.29|2|test-1-b|2021.03.29D15:42:08.007580000|2021.03.29D15:42:08.112835000|success|"test-1-b-20210329154208007.log"
2021.03.29|3|test-2|2021.03.29D15:42:46.707637000|2021.03.29D15:42:46.813971000|failure|"test-2-20210329154246707.log"
2021.03.29|1|test-1-a|2021.03.29D15:43:08.007646000|2021.03.29D15:43:08.112847000|success|"test-1-a-20210329154308007.log"
2021.03.29|2|test-1-b|2021.03.29D15:43:08.207632000|2021.03.29D15:43:08.313481000|success|"test-1-b-20210329154308207.log"

## Dependancies

- qArguments to be loaded at start-up -> [ryanmcfarland/kdb-qArguments](https://github.com/ryanmcfarland/kdb-qArguments)

## Improvements-To-Be-Made
- Current flaw is that workers connect to main process, this should be other way round
- A web interface to run jobs on command
- Better id & name mapping within schuduler, hard to run an individual job.
- Smarter logic regarding sTime, eTime & job-dependancies
- Smarter logic to source unix envirnoment variables
- Send history to potential tp,rdb,hdb set-up so not tracked within scheudler main process.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details