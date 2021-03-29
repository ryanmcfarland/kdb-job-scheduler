/ KDB Start-up script, loads in all files possible within q/code and q/schema
/ Attempts to execute init provided through the cmd line
/ load files but will not run init if -debug is not provided

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
    // hacky way to keep original schemas without creating complex init 
    {[x] (` sv ``scheduler,x) set .scheduler.schema[x]} each (key `.scheduler.schema) except `;
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