// Worker Script 

.main.init:{
    .scheduler.main.init[];
    };

.worker.args:{
    .args.addReq[`sport;0ni;"Main Port"];
    .args.addReq[`shost;`;"Main host"];
    .args.addOpt[`wname;`;"Worker name"];
    args:.args.buildDict[];
    if[`=args[`wname];args[`wname]:.z.h];
    :args
    }

.worker.init:{
    args:.worker.args[];
    conn:hsym `$":" sv string args[`shost],args[`sport];
    .scheduler.connect[conn;args[`wname];system "p"];
    .scheduler.worker.init[];
    };