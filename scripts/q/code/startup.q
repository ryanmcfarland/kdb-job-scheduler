/

export SCH_HOME=/home/ryanm/code/kdb-scheduler/

q scripts/q/code/startup.q -init main -debug 1 -p 5001
q scripts/q/code/startup.q -init worker -debug 1 -p 5002 -sport 5001 -shost localhost -wname test1


q)a:raze (system "pwd")
q)setenv[`SCH_HOME;a]
system "l ",(getenv`SCH_HOME),"/scripts/q/code/scheduler.q"
system "l ",(getenv`SCH_HOME),"/scripts/q/schema/scheduler.q"
\

.kdb.startup.args:{
    .args.addReq[`init;`;"Check namespace to load in"];
    .args.addOpt[`debug;0b;"Debug mode"];
    args:.args.buildDict[];
    .args.resetArgDict[];
    :args;
    };

.kdb.startup.loadfiles:{
    qfiles:{string ` sv x,y}[dir;] each (key dir:hsym `$(getenv`SCH_HOME),"/scripts/q/code/") except `startup.q;
    schemafiles:{string ` sv x,y}[dir;] each (key dir:hsym `$(getenv`SCH_HOME),"/scripts/q/schema/");
    {[x] @[{show x; system "l ",x};x;{[x;y]'y,"Issue loading file - ",x}[x]]} each qfiles,schemafiles;
    };

.kdb.startup.runProcessInit:{[args]
    initFunc:` sv `,args[`init],`init;
    .log.info["Attempting to Run Init Function - ",string[initFunc]];
    initFunc:@[value;initFunc;{'"Init not found - ",x}];
    @[initFunc;();{[x]'"Error with init - ",x}];
    };

.kdb.startup.init:{
    args:.kdb.startup.args[];
    .kdb.startup.loadfiles[];
    $[not args[`debug];
        .kdb.startup.runProcessInit[args];
        .log.info["Debug mode, init not ran"]];
    };

.kdb.startup.init[];