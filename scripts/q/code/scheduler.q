// Internal functions and variables for the kdb job scheduler

.scheduler.jobId:0j;

/ Loop through all files found in config/jobs and update events
/ create current day table of jobs to run on the timer
/ set .z.ts to .scheduler.run[] to run every 100 seconds
.scheduler.main.init:{[]
    .scheduler.i.readJsonFiles[];
    /delete from `.scheduler.jobs where null interval;
    .z.ts:{.scheduler.run[]};
    system "t 100";
    };

/ Set-up Worker Internal Timer
.scheduler.worker.init:{[]
    .z.ts:{.scheduler.jobCheck[]};
    system "t 100";
    };

////////// ** INTERNAL MAIN COMMANDS **

/ Main scheduler function that is called via .z.ts, this is executed on the main process
.scheduler.run:{[]
    jobs:select id, name, host, cmd from .scheduler.jobs where sTime <= .z.P, status in `TODO`SUCCESS`FAILED;
    jobs:distinct jobs uj select id, name, host, cmd from .scheduler.jobs where name in dependant, status = `JOB_UP_SUCCESS;
    .scheduler.runJob each jobs;
    };

/ Run a sp
.scheduler.runJob:{[job]
    handle:first exec handle from .scheduler.workerTable where name=job[`host];
    $[(null handle) | not count handle;
        [.log.error["No handle obtained for: ",string[job[`host]]];
        update sTime:.z.P+interval, status:`FAILED, reason:`HANDLE from `.scheduler.jobs where id in job[`id];
        `.scheduler.history upsert (.z.D;job[`id];job[`name];.z.P;.z.P;`FAILED;"HANDLE")];
        [update status:`RUNNING, reason:` from `.scheduler.jobs where id in job[`id];
        @[neg handle;(`.scheduler.i.runWrkCmd;job)]]];
    };

/ job is sent from the worker process 
.scheduler.i.jobStatus:{[job;status]
    .debug.job:job;
    $[status=`success;
        [update sTime:.z.P+interval, status:`SUCCESS, reason:`  from `.scheduler.jobs where id = job`id;
        update status:`JOB_UP_SUCCESS, reason:` from `.scheduler.jobs where dependant = job`name];
        update sTime:.z.P+interval, status:`FAILED,reason:`$job[`logname] from `.scheduler.jobs where id = job`id];
    `.scheduler.history upsert (.z.D;job[`id];job[`name];job[`sTime];.z.P;status;job[`logname]);
    };

/ Loop through all files found in config/jobs and update events
.scheduler.i.readJsonFiles:{
    dir:(hsym `$getenv[`SCH_HOME],"/config/jobs");
    files:{` sv x,y}[dir;]each key dir;
    {[x] @[.scheduler.i.readJson;x;{[x;y] show[raze "Error with file - ",y," - ",string[x]]}[x]]} each files;
    };

/ JSON Parse each config stored in config/jobs
/ .Q.def applies defaults from events schema onto the parsed config
/ Remove all keys that aren't part of the schema - maybe error check this instead?
/ @param file (Symbol) filepath to json path 
.scheduler.i.readJson:{[file]
    default:`id`sTime`interval!(.scheduler.jobId+:1;.z.P;00:00:00.000);
    res:.j.k raze read0 file;
    res:.Q.def[first .scheduler.schema.jobs] res;
    res:default ^ res;
    res:.scheduler.schema.jobs uj enlist ((key res) except cols .scheduler.schema.jobs) _ res;
    res:update status:`TODO from res where null dependant;
    `.scheduler.jobs upsert res;
    };

.scheduler.i.updateWorkerTab:{[handle;name;host;port]
    `.scheduler.workerTable upsert (handle;name;host;port);
    };

.scheduler.i.updateWorkerTabConn:{[host;port]
    .scheduler.i.updateWorkerTab[.z.w;host;.Q.host .z.a;port];
    :`handle`host`port!(.z.w;.z.h;system "p");
    };

////////// ** INTERNAL WORKER COMMANDS **

/ Connect to the main kdb process and grab details
.scheduler.connect:{[conn;name;port]
    .scheduler.main.handle:hopen conn;
    .scheduler.main.details:.scheduler.main.handle(`.scheduler.i.updateWorkerTabConn;name;port);
    };

/ Timed command to check all currently running jobs on the worker
.scheduler.jobCheck:{[]
    .scheduler.i.checkRunningJob each select from .scheduler.workerJobs;
    }

/ Main will send command to be run which will be executed by this function
.scheduler.i.runWrkCmd:{[job]
    .debug.job:job;
    logname:string[job[`name]],"-",({ssr[x;y;""]}/[string[.z.Z];".T:"]),".log";
    `.scheduler.workerJobs upsert (job[`id];job[`name];.z.P;job[`cmd];logname;`RUNNING);
    cmd:(getenv`SCH_BASH),"/execute.sh -c ",job[`cmd]," > ",(getenv`SCH_LOGS),logname," 2>&1 &";
    .log.info["Running: ",cmd];
    @[system;cmd;{[x;y].log.error["Job Start Failure - ",x," - ",y]}[cmd;]];
    };

/ Wrapper function to check status of all current jobs tracked by worker
/ Grep for Job Success or Failue (See execute.sh)
/ Sends message to main based on result 
.scheduler.i.checkRunningJob:{[job]
    $[@[{system x;:1b};"grep \"JOB SUCCESS\" ",(getenv`SCH_LOGS),job[`logname];{x;:0b}];
        [.log.info["Job Success - ",string[job[`name]]," - sending status update"];
        @[neg .scheduler.main.handle;(`.scheduler.i.jobStatus;job;`success)];
        delete from `.scheduler.workerJobs where id = job[`id]];
    @[{system x;:1b};"grep \"JOB FAILURE\" ",(getenv`SCH_LOGS),job[`logname];{x;:0b}];
        [.log.error["Job Failure - ",string[job[`name]]," - sending status update"];
        @[neg .scheduler.main.handle;(`.scheduler.i.jobStatus;job;`failure)];
        delete from `.scheduler.workerJobs where id = job[`id]];
        delete from `.scheduler.workerJobs where id = job[`id]];
    };
