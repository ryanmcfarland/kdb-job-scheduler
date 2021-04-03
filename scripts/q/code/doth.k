/ https://github.com/timeseries/kdb/blob/master/cserve/doth.k
/ k code, $ doesn't use colons for ifelse statememt
/ TODO - to be changed at a later date - want to only return jobs table with host:port
/ TODO line 9: if x is "", change x to whatever the default html template is

\d .h

getPageParamPair:{$[0N=a:*: &: "?"=x; (`$x;""); (`$x@ !:a;(a+1)_x)]};
LOGQUERIES:1b; / log to console query details
FRAMESET:{}[];	

/ return the HTML for this link or null if no page found
getPage:{ [pagename] 
	logg "pagename = ",pagename;
	ttmp:getPageParamPair@pagename;
    logg "ttmp= ",.Q.s ttmp;
	logg "  keypage = ",($:ttmp 0),/ "  args = ",$:ttmp 0;
	$[100h=@:page:pageDict[ttmp 0]; ,/htmlForDataTable@page@parseQ@ttmp 1; ""] };

.z.ph:{
    isHtml:{".html" ~ x (-1 + #:x) - |: !: 5};
	x:uh$[@x;x;*x];
    $[~#x;x:"basic.html";];
    pp:@[getPageParamPair;x;(`;"")];
	$[LOGQUERIES;1 "\n----.z.ph ",.Q.s x; ::];
	doFrameset:{hy[`htm]FRAMESET};
	$[~#x; doFrameset[x]
    #r:@[1::;0N!`$":",p:HOME,"/",$pp 0;""]; $[isHtml[$pp 0]; hy;] [0N!`$(1+x?".")_$pp 0; "c"$r]
    hn["404 Not Found";`txt]p,": not found"]};

\d .

/ handle the simplest posts by replacing the space with ampersand
.z.pp:{ 0N!x[0]:(p#x 0),"&",.q.ssr[;,"+";," "]  (1+p:last ss[x 0;," "])_x 0; .z.ph x};
