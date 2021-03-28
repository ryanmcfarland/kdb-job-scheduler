// \l scripts/q/schema/scheduler.q

\d .scheduler

schema.workerTable:([] 
    handle:`int$();
    name:`$();
    host:`$();
    port:`int$());

schema.workerJobs:([] 
    id:`long$();
    name:`$();
    sTime:`timestamp$();
    cmd:();
    logname:();
    status:`$());

schema.jobs:([]
    id:`long$();
    name:`$();
    host:`$();
    sTime:`timestamp$();
    interval:`time$();
    dependant:`$();
    status:`$();
    reason:`$();
    cmd:());

schema.history:([]
    date:`date$();
    id:`long$();
    name:`$();
    sTime:`timestamp$();
    eTime:`timestamp$();
    result:`$();
    logname:());

// hacky way to keep original schemas without creating complex init 
{[x] (` sv ``scheduler,x) set .scheduler.schema[x]} each (key `.scheduler.schema) except `;
