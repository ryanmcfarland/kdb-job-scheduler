// Internal functions and variables for the kdb job scheduler

.scheduler.jobId:0j;

/ Loop through all files found in config/jobs and update events
/ create current day table of jobs to run on the timer
/ set .z.ts to .scheduler.run[] to run every 100 seconds
.scheduler.main.init:{[]
    .scheduler.i.readJsonFiles[];
    .scheduler.i.connectToWorkers[];
    .scheduler.i.reconnectStartup[];
    `.z.pc set .scheduler.i.pc;
    `.z.ts set {.scheduler.run[]};
    system "t 1000";
    };

/ Set-up Worker Internal Timer
.scheduler.worker.init:{[]
    `.z.pc set .scheduler.i.pc;
    `.z.ts set {.scheduler.jobCheck[]};
    system "t 1000";
    };

////////// ** INTERNAL MAIN COMMANDS **

/ Main scheduler function that is called via .z.ts, this is executed on the main process
.scheduler.run:{[]
    .scheduler.i.reconnect[];
    ids:exec id from .scheduler.jobs where sTime <= .z.P, status in `TODO`SUCCESS`FAILED, null dependant;
    ids,:exec id from .scheduler.jobs where status = `JOB_UP_SUCCESS;
    .scheduler.runJob each distinct ids;
    };

/ Run a sp
.scheduler.runJob:{[jid]
    job:exec id,name,host,cmd from .scheduler.jobs where id = jid;
    job:first each job;
    .log.info["Running Job: ",string[job`name]];
    handle:.scheduler.connTable[job[`host];`handle];
    $[null handle;
        [.log.error["No handle obtained for: ",string[job[`host]]];
        update sTime:.z.P+interval, status:`FAILED, reason:`HANDLE from `.scheduler.jobs where id in job[`id];
        `.scheduler.history upsert (.z.D;job[`id];job[`name];.z.P;.z.P;`FAILED;"HANDLE")];
        [update status:`RUNNING, reason:` from `.scheduler.jobs where id in job[`id];
        @[neg handle;(`.scheduler.i.runWrkCmd;job)]]];
    };

/ job is sent from the worker process 
.scheduler.i.jobStatus:{[job;status]
    .log.info["Job Status Update Recieved: ",string[job`name]," - ",string[status]];
    $[status=`SUCCESS;
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

.scheduler.i.connectToWorkers:{
    workers:("SSI";enlist ",") 0: hsym `$(getenv`SCH_HOME),"/config/env/workers.cfg";
    .scheduler.i.connectToProcess each workers;    
    };

////////// ** INTERNAL WORKER COMMANDS **

/ Connect to the main kdb process and grab details
.scheduler.i.updateWorker:{[port]
    :`.scheduler.connTable upsert (`main;.z.w;.Q.host .z.a;port);
    };

/ Timed command to check all currently running jobs on the worker
.scheduler.jobCheck:{[]
    .scheduler.i.reconnect[];
    .scheduler.i.checkRunningJob each select from .scheduler.workerJobs;
    }

/ Main will send command to be run which will be executed by this function
.scheduler.i.runWrkCmd:{[job]
    .log.info["Job Receieved: ",string[job[`name]]];
    // use string[.z.Z] except ".T:"
    logname:string[job[`name]],"-",(string[.z.Z] except ".T:"),".log";
    `.scheduler.workerJobs upsert (job[`id];job[`name];.z.P;job[`cmd];logname;`RUNNING);
    cmd:(getenv`SCH_BASH),"/execute.sh -c \"",job[`cmd],"\" > ",(getenv`SCH_LOGS_JOB),"/",logname," 2>&1 &";
    .log.info["Running: ",cmd];
    @[system;cmd;{[x;y].log.error["Job Start Failure - ",x," - ",y]}[cmd;]];
    };

/ Wrapper function to check status of all current jobs tracked by worker
/ Grep for Job Success or Failue (See execute.sh)
/ Sends message to main based on result 
.scheduler.i.checkRunningJob:{[job]
    filename:(getenv`SCH_LOGS_JOB),"/",job[`logname];
    $[() ~ key hsym `$filename;
        [.log.error["Job Failure - ",string[job[`name]]," - missing log file"];
        @[neg .scheduler.connTable[`main;`handle];(`.scheduler.i.jobStatus;job;`FAILED)];
        delete from `.scheduler.workerJobs where id = job[`id]];
    @[{system x;:1b};"grep \"JOB SUCCESS\" ",filename;{x;:0b}];
        [.log.info["Job Success - ",string[job[`name]]," - sending status update"];
        @[neg .scheduler.connTable[`main;`handle];(`.scheduler.i.jobStatus;job;`SUCCESS)];
        delete from `.scheduler.workerJobs where id = job[`id]];
    @[{system x;:1b};"grep \"JOB FAILURE\" ",filename;{x;:0b}];
        [.log.error["Job Failure - ",string[job[`name]]," - sending status update"];
        @[neg .scheduler.connTable[`main;`handle];(`.scheduler.i.jobStatus;job;`FAILED)];
        delete from `.scheduler.workerJobs where id = job[`id]];
        "Still Running"];
    };

//////// ** IPC Functions **

/ Update conn tab if a worker or main disconnects
.scheduler.i.pc:{
    .log.info["Handle Closed: ",string[x]," | Host: ",string[.Q.host .z.a]," | User: ",string[.z.u]];
    update handle:0Ni from `.scheduler.connTable where handle=x;
    };

/ reconnect to main or worker if any handle is null
/ @return True if all connectiosn established 
.scheduler.i.reconnect:{
    res:0!select from .scheduler.connTable where null handle;
    if[count res;res:.scheduler.i.connectToProcess each res;:not any null res];
    :1b
    };

/ Reconnect with a while loop, will attempt to reconnect 3 times and sleep for 10 seconds
/ func returns either 1b or 0b,{x+1} adds 1 to x and /1 is the over adverb to start with x:1
/ Only activates if res is > 0;
.scheduler.i.reconnectStartup:{
    res:0!select from .scheduler.connTable where null handle;
    func:{.log.info["Attempting to reconnect - Run No: ",string[x]];(.scheduler.i.reconnect[]) | x < 3};
    if[count res;func{system "sleep 10";x+1}\1];
    };

/ Attempt to connect to input worker / main process
/ @param (dict) required keys: `name`host`port
/ @return (int) returns handle of process
 .scheduler.i.connectToProcess:{[dict]
    .log.info["Connecting: ",string[dict`name]," | Host: ",string[dict`host]," | Port: ",string[dict`port]];
    conn:hsym `$":" sv string dict[`host],dict[`port];
    handle:@[hopen;conn;{0Ni}];
    if[(not null handle) & `main <> dict[`name];
        neg[handle](`.scheduler.i.updateWorker;system "p")];
    `.scheduler.connTable upsert (dict[`name];handle;dict[`host];dict[`port]);
    :handle;
    };