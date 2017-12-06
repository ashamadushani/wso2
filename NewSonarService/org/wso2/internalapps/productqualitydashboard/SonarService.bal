package org.wso2.internalapps.productqualitydashboard;

import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.lang.jsons;
import ballerina.lang.time;
import ballerina.utils;
import ballerina.lang.system;
import ballerina.data.sql;
import ballerina.lang.errors;
import ballerina.lang.datatables;

struct Snapshots{
    int snapshot_id;
}

struct Areas{
    int pqd_area_id;
    string pqd_area_name;
}

struct Products{
    int pqd_product_id;
    string sonar_project_key;
}

struct Totals{
    int total;
}

struct SonarIssues{
    int sonar_component_issue_id;
    int snapshot_id;
    string project_key;
    int BLOCKER_BUG; int CRITICAL_BUG; int MAJOR_BUG; int MINOR_BUG; int INFO_BUG;
    int BLOCKER_CODE_SMELL; int CRITICAL_CODE_SMELL; int MAJOR_CODE_SMELL; int MINOR_CODE_SMELL; int INFO_CODE_SMELL;
    int BLOCKER_VULNERABILITY; int CRITICAL_VULNERABILITY; int MAJOR_VULNERABILITY; int MINOR_VULNERABILITY; int INFO_VULNERABILITY;
    int total;
}

struct Components{
    int pqd_component_id;
    string sonar_project_key;
}

json configData = getConfigData(CONFIG_PATH);

map propertiesMap = getSQLconfigData(configData);

string basicurl = jsons:getString(configData, "$.sonarUrl");
string version =  API_VERSION;

@http:configuration {basePath:"/internal/product-quality/v1.0/sonar"}
service<http> SonarService {

    @http:GET {}
    @http:Path {value:"/get-total-issues"}
    resource SonarTotalIsuueCount (message m) {

        http:ClientConnector sonarcon = create http:ClientConnector(basicurl);

        message request = {};
        message requestH = {};
        message sonarResponse = {};
        json sonarJSONResponse = {};
        message response = {};

        string Path = "/api/issues/search?resolved=no";
        requestH = authHeader(request);
        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
        sonarJSONResponse = messages:getJsonPayload(sonarResponse);
        int total = jsons:getInt(sonarJSONResponse, "$.total");

        string tot = <string>total;
        time:Time currentTime = time:currentTime();
        string customTimeString = time:format(currentTime, "yyyy-MM-dd--HH:mm:ss");

        json sonarPayload = {"Date":customTimeString, "TotalIssues":tot};

        messages:setJsonPayload(response, sonarPayload);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;

    }

    @http:GET {}
    @http:Path {value:"/fetch-data"}
    resource saveIssuestoDB (message m) {
        message response = {};
        message request = {};
        message requestH = {};
        message sonarResponse = {};

        http:ClientConnector sonarcon = create http:ClientConnector(basicurl);
        string Path="/api/projects";
        requestH = authHeader(request);

        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
        json sonarJsonResponse = messages:getJsonPayload(sonarResponse);
        system:println(sonarJsonResponse);
        json projects=jsons:getJson(sonarJsonResponse,"$.[?(@.k)].k");
        saveIssues(projects);

        messages:setJsonPayload(response, projects);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/get-all-area-issues"}
    resource SonarAllAreaIssues (message m) {
        json data = allAreaSonars();
        message response = {};
        messages:setJsonPayload(response,data);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;

    }

    @http:GET {}
    @http:Path {value:"/get-issues/{category}/{selected}/{issueType}/{severity}"}
    resource SonarGetIssues (message m, @http:PathParam {value:"category"} string category,
                                            @http:PathParam {value:"selected"} int selected,
                                            @http:PathParam {value:"issueType"} int issueType,
                                            @http:PathParam {value:"severity"} int severity) {
        json data = getSelectionResult(category,selected,issueType,severity);
        message response = {};
        messages:setJsonPayload(response,data);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;

    }

}

function getSelectionResult(string category, int selected, int issueType , int severity)(json){
    json ret={};
    if(category=="all"){
        if(issueType!=0 && severity==0){
            ret=getAllAreaIssuesForType(issueType);
        }else if(issueType==0 && severity==0){
            ret=allAreaSonars();
        }
    }

    return ret;
}

function getAllAreaIssuesForType(int issueType)(json){
    json data = {"error":false};
    json allAreas = {"items":[],"severity":[]};

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    sql:Parameter[] params = [];

    datatable ssdt = sql:ClientConnector.select(dbConnector,GET_SNAPSHOT_ID,params);
    Snapshots ss;
    int snapshot_id;
    errors:TypeCastError err;
    while (datatables:hasNext(ssdt)) {
        any row = datatables:next(ssdt);
        ss, err = (Snapshots )row;

        snapshot_id= ss.snapshot_id;

    }
    datatables:close(ssdt);

    int BLOCKER=0;
    int CRITICAL=0;
    int MAJOR=0;
    int MINOR=0;
    int INFO=0;

    datatable dt = sql:ClientConnector.select(dbConnector,GET_ALL_AREAS, params);
    Areas area;
    while (datatables:hasNext(dt)) {
        any row1 = datatables:next(dt);
        area, err = (Areas)row1;

        string area_name = area.pqd_area_name;
        int area_id = area.pqd_area_id;

        int sonars=0;

        sql:Parameter pqd_area_id_para = {sqlType:"integer", value:area_id};
        params = [pqd_area_id_para];
        datatable pdt = sql:ClientConnector.select(dbConnector,GET_PRODUCTS_OF_AREA, params);
        Products product;
        while (datatables:hasNext(pdt)) {
            any rowp = datatables:next(pdt);
            product,err = (Products)rowp;

            int product_id = product.pqd_product_id;
            string product_sonar_key= product.sonar_project_key;

            sql:Parameter sonar_project_key_para = {sqlType:"varchar", value:product_sonar_key};
            sql:Parameter snapshot_id_para = {sqlType:"integer", value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable pidt = sql:ClientConnector.select(dbConnector, GET_ALL_OF_SONAR_ISSUES, params);
            SonarIssues si;
            while (datatables:hasNext(pidt)) {
                any row2 = datatables:next(pidt);
                si, err = (SonarIssues)row2;

                int bb = si.BLOCKER_BUG; int cb = si.CRITICAL_BUG; int mab = si.MAJOR_BUG; int mib = si.MINOR_BUG; int ib = si.INFO_BUG;
                int bc = si.BLOCKER_CODE_SMELL; int cc = si.CRITICAL_CODE_SMELL;int mac = si.MAJOR_CODE_SMELL;int mic = si.MINOR_CODE_SMELL;int ic = si.INFO_CODE_SMELL;
                int bv = si.BLOCKER_VULNERABILITY; int cv = si.CRITICAL_VULNERABILITY; int mav = si.MAJOR_VULNERABILITY; int miv = si.MINOR_VULNERABILITY;int iv = si.INFO_VULNERABILITY;
                int tot=0;
                if(issueType==1){
                    tot=bb+cb+mab+mib+ib;
                    BLOCKER = BLOCKER + bb;
                    CRITICAL = CRITICAL + cb;
                    MAJOR = MAJOR + mab;
                    MINOR = MINOR + mib;
                    INFO = INFO + ib;
                }else if(issueType==2){
                    tot=bc+cc+mac+mic+ic;
                    BLOCKER = BLOCKER + bc;
                    CRITICAL = CRITICAL + cc;
                    MAJOR = MAJOR + mac;
                    MINOR = MINOR + mic;
                    INFO = INFO + ic;
                }else if(issueType==3){
                    tot=bv+cv+mav+miv+iv;
                    BLOCKER = BLOCKER + bv;
                    CRITICAL = CRITICAL + cv;
                    MAJOR = MAJOR + mav;
                    MINOR = MINOR + miv;
                    INFO = INFO + iv;
                }
                sonars=sonars+tot;
            }
            datatables:close(pidt);
        }
        datatables:close(pdt);

        params = [pqd_area_id_para];
        datatable cdt = sql:ClientConnector.select(dbConnector,GET_COMPONENT_OF_AREA , params);
        Components comps;
        while (datatables:hasNext(cdt)) {
            any row0 = datatables:next(cdt);
            comps, err = (Components)row0;

            string project_key = comps.sonar_project_key;
            int component_id = comps.pqd_component_id;

            sql:Parameter sonar_project_key_para = {sqlType:"varchar", value:project_key};
            sql:Parameter snapshot_id_para = {sqlType:"integer", value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable idt = sql:ClientConnector.select(dbConnector,GET_ALL_OF_SONAR_ISSUES, params);
            SonarIssues si;
            while (datatables:hasNext(idt)) {
                any row2 = datatables:next(idt);
                si, err = (SonarIssues )row2;

                int bb = si.BLOCKER_BUG; int cb = si.CRITICAL_BUG; int mab = si.MAJOR_BUG; int mib = si.MINOR_BUG; int ib = si.INFO_BUG;
                int bc = si.BLOCKER_CODE_SMELL; int cc = si.CRITICAL_CODE_SMELL;int mac = si.MAJOR_CODE_SMELL;int mic = si.MINOR_CODE_SMELL;int ic = si.INFO_CODE_SMELL;
                int bv = si.BLOCKER_VULNERABILITY; int cv = si.CRITICAL_VULNERABILITY; int mav = si.MAJOR_VULNERABILITY; int miv = si.MINOR_VULNERABILITY;int iv = si.INFO_VULNERABILITY;
                int tot=0;
                if(issueType==1){
                    tot=bb+cb+mab+mib+ib;
                    BLOCKER = BLOCKER + bb;
                    CRITICAL = CRITICAL + cb;
                    MAJOR = MAJOR + mab;
                    MINOR = MINOR + mib;
                    INFO = INFO + ib;
                }else if(issueType==2){
                    tot=bc+cc+mac+mic+ic;
                    BLOCKER = BLOCKER + bc;
                    CRITICAL = CRITICAL + cc;
                    MAJOR = MAJOR + mac;
                    MINOR = MINOR + mic;
                    INFO = INFO + ic;
                }else if(issueType==3){
                    tot=bv+cv+mav+miv+iv;
                    BLOCKER = BLOCKER + bv;
                    CRITICAL = CRITICAL + cv;
                    MAJOR = MAJOR + mav;
                    MINOR = MINOR + miv;
                    INFO = INFO + iv;
                }else{
                    jsons:set(data,"$.error",true);
                    return data;
                }
                sonars=sonars+tot;
            }
            datatables:close(idt);
        }
        datatables:close(cdt);

        json area_issues = {"name":area_name, "id":area_id, "issues":sonars};
        jsons:addToArray(allAreas, "$.items", area_issues);


    }
    datatables:close(dt);
    dbConnector.close();
    json blocker = {"name":"BLOCKER", "issues":BLOCKER};
    jsons:addToArray(allAreas, "$.severity",blocker);
    json critical = {"name":"CRITICAL", "issues":CRITICAL};
    jsons:addToArray(allAreas, "$.severity",critical);
    json major = {"name":"MAJOR", "issues":MAJOR};
    jsons:addToArray(allAreas, "$.severity",major);
    json minor = {"name":"MINOR", "issues":MINOR};
    jsons:addToArray(allAreas, "$.severity",minor);
    json info = {"name":"INFO", "issues":INFO};
    jsons:addToArray(allAreas, "$.severity",info);

    jsons:addToObject(data, "$", "data",allAreas);
    return data;
}

function saveIssues (json projects)  {
    int ls=lengthof projects;
    system:println(ls);
    ls -> w1;

    worker w1 {
        int loopsize;
        loopsize<-default;

        sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);
        sql:Parameter[] params = [];

        string customStartTimeString = time:format(time:currentTime(), "yyyy-MM-dd--HH:mm:ss");
        system:println("Start time: " + customStartTimeString);

        sql:Parameter todayDate = {sqlType:"varchar", value:customStartTimeString};
        params = [todayDate];
        int ret = sql:ClientConnector.update(dbConnector, INSERT_SNAPSHOT_DETAILS , params);

        params = [];
        datatable dt = sql:ClientConnector.select(dbConnector,  GET_SNAPSHOT_ID, params);

        Snapshots ss;
        int snapshot_id;
        errors:TypeCastError err;
        while (datatables:hasNext(dt)) {
            any row = datatables:next(dt);
            ss, err = (Snapshots)row;

            snapshot_id = ss.snapshot_id;

        }
        datatables:close(dt);
        transaction {

            sql:Parameter snapshotid = {sqlType:"integer", value:snapshot_id};
            int i = 0;
            while (i < loopsize) {

                var project_key, er = (string)projects[i];
                system:println(i + "|" + project_key);
                json sumaryofProjectJson = componentIssueCount(project_key);
                system:println(sumaryofProjectJson);

                sql:Parameter projectkey = {sqlType:"varchar", value:project_key};

                int bb = jsons:getInt(sumaryofProjectJson, "$.bb");
                sql:Parameter bb1 = {sqlType:"integer", value:bb};

                int cb = jsons:getInt(sumaryofProjectJson, "$.cb");
                sql:Parameter cb1 = {sqlType:"integer", value:cb};

                int mab = jsons:getInt(sumaryofProjectJson, "$.mab");
                sql:Parameter mab1 = {sqlType:"integer", value:mab};

                int mib = jsons:getInt(sumaryofProjectJson, "$.mib");
                sql:Parameter mib1 = {sqlType:"integer", value:mib};

                int ib = jsons:getInt(sumaryofProjectJson, "$.ib");
                sql:Parameter ib1 = {sqlType:"integer", value:ib};

                int bc = jsons:getInt(sumaryofProjectJson, "$.bc");
                sql:Parameter bc1 = {sqlType:"integer", value:bc};

                int cc = jsons:getInt(sumaryofProjectJson, "$.cc");
                sql:Parameter cc1 = {sqlType:"integer", value:cc};

                int mac = jsons:getInt(sumaryofProjectJson, "$.mac");
                sql:Parameter mac1 = {sqlType:"integer", value:mac};

                int mic = jsons:getInt(sumaryofProjectJson, "$.mic");
                sql:Parameter mic1 = {sqlType:"integer", value:mic};

                int ic = jsons:getInt(sumaryofProjectJson, "$.ic");
                sql:Parameter ic1 = {sqlType:"integer", value:ic};

                int bv = jsons:getInt(sumaryofProjectJson, "$.bv");
                sql:Parameter bv1 = {sqlType:"integer", value:bv};

                int cv = jsons:getInt(sumaryofProjectJson, "$.cv");
                sql:Parameter cv1 = {sqlType:"integer", value:cv};

                int mav = jsons:getInt(sumaryofProjectJson, "$.mav");
                sql:Parameter mav1 = {sqlType:"integer", value:mav};

                int miv = jsons:getInt(sumaryofProjectJson, "$.miv");
                sql:Parameter miv1 = {sqlType:"integer", value:miv};

                int iv = jsons:getInt(sumaryofProjectJson, "$.iv");
                sql:Parameter iv1 = {sqlType:"integer", value:iv};

                int total = jsons:getInt(sumaryofProjectJson, "$.Total");
                sql:Parameter total1 = {sqlType:"integer", value:total};

                params = [snapshotid, projectkey, bb1, cb1, mab1, mib1, ib1, bc1, cc1, mac1, mic1, ic1, bv1, cv1, mav1, miv1, iv1,total1];
                int ret1 = sql:ClientConnector.update(dbConnector, INSERT_SONAR_ISSUES, params);
                i = i + 1;
            }
        }
        string customEndTimeString = time:format(time:currentTime(), "yyyy-MM-dd--HH:mm:ss");
        system:println("End time: " + customEndTimeString);
        dbConnector.close();
    }
}

function componentIssueCount(string project_key)(json) {
    http:ClientConnector sonarcon = create http:ClientConnector(basicurl);

    message request = {};
    message requestH = {};
    message sonarResponse = {};
    json sonarJSONResponse = {};
    int p=1;
    int ps = 500;

    string Path = "/api/issues/search?resolved=no&ps=500&projectKeys=" + project_key+"&p="+p;
    requestH = authHeader(request);
    system:println(basicurl+Path);
    sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);

    sonarJSONResponse = messages:getJsonPayload(sonarResponse);

    int total =jsons:getInt(sonarJSONResponse,"$.total");

    json blockerBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='BLOCKER')]");
    int totalBlockerBugs=jsons:getInt(blockerBugs,"$.length()");

    json criticalBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='CRITICAL')]");
    int totalCriticalBugs=jsons:getInt(criticalBugs,"$.length()");

    json majorBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='MAJOR')]");
    int totalMajorBugs=jsons:getInt(majorBugs,"$.length()");

    json minorBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='MINOR')]");
    int totalMinorBugs=jsons:getInt(minorBugs,"$.length()");

    json infoBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='INFO')]");
    int totalInfoBugs=jsons:getInt(infoBugs,"$.length()");

    json blockerCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='BLOCKER')]");
    int totalBlockerCodeSmells=jsons:getInt(blockerCodeSmells,"$.length()");

    json criticalCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='CRITICAL')]");
    int totalCriticalCodeSmells=jsons:getInt(criticalCodeSmells,"$.length()");

    json majorCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='MAJOR')]");
    int totalMajorCodeSmells=jsons:getInt(majorCodeSmells,"$.length()");

    json minorCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='MINOR')]");
    int totalMinorCodeSmells=jsons:getInt(minorCodeSmells,"$.length()");

    json infoCodeSmell = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='INFO')]");
    int totalInfoCodeSmell=jsons:getInt(infoCodeSmell,"$.length()");

    json blockerVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='BLOCKER')]");
    int totalBlockerVulnerabilities=jsons:getInt(blockerVulnerabilities,"$.length()");

    json criticalVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='CRITICAL')]");
    int totalCriticalVulnerabilities=jsons:getInt(criticalVulnerabilities,"$.length()");

    json majorVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='MAJOR')]");
    int totalMajorVulnerabilities=jsons:getInt(majorVulnerabilities,"$.length()");

    json minorVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='MINOR')]");
    int totalMinorVulnerabilities=jsons:getInt(minorVulnerabilities,"$.length()");

    json infoVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='INFO')]");
    int totalInfoVulnerabilities=jsons:getInt(infoVulnerabilities,"$.length()");


    while (total>ps){
        p=p+1;
        total=total-500;
        system:println(total+"|"+p);
        Path = "/api/issues/search?resolved=no&ps=500&projectKeys=" + project_key+"&p="+p;
        system:println(basicurl+Path);
        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);

        sonarJSONResponse = messages:getJsonPayload(sonarResponse);

        blockerBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='BLOCKER')]");
        totalBlockerBugs=totalBlockerBugs+jsons:getInt(blockerBugs,"$.length()");

        criticalBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='CRITICAL')]");
        totalCriticalBugs=totalCriticalBugs+jsons:getInt(criticalBugs,"$.length()");

        majorBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='MAJOR')]");
        totalMajorBugs=totalMajorBugs+jsons:getInt(majorBugs,"$.length()");

        minorBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='MINOR')]");
        totalMinorBugs=totalMinorBugs+jsons:getInt(minorBugs,"$.length()");

        infoBugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')][?(@.severity=='INFO')]");
        totalInfoBugs=totalInfoBugs+jsons:getInt(infoBugs,"$.length()");

        blockerCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='BLOCKER')]");
        totalBlockerCodeSmells=totalBlockerCodeSmells+jsons:getInt(blockerCodeSmells,"$.length()");

        criticalCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='CRITICAL')]");
        totalCriticalCodeSmells=totalCriticalCodeSmells+jsons:getInt(criticalCodeSmells,"$.length()");

        majorCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='MAJOR')]");
        totalMajorCodeSmells=totalMajorCodeSmells+jsons:getInt(majorCodeSmells,"$.length()");

        minorCodeSmells = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='MINOR')]");
        totalMinorCodeSmells=totalMinorCodeSmells+jsons:getInt(minorCodeSmells,"$.length()");

        infoCodeSmell = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')][?(@.severity=='INFO')]");
        totalInfoCodeSmell=totalInfoCodeSmell+jsons:getInt(infoCodeSmell,"$.length()");

        blockerVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='BLOCKER')]");
        totalBlockerVulnerabilities=totalBlockerVulnerabilities+jsons:getInt(blockerVulnerabilities,"$.length()");

        criticalVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='CRITICAL')]");
        totalCriticalVulnerabilities=totalCriticalVulnerabilities+jsons:getInt(criticalVulnerabilities,"$.length()");

        majorVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='MAJOR')]");
        totalMajorVulnerabilities=totalMajorVulnerabilities+jsons:getInt(majorVulnerabilities,"$.length()");

        minorVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='MINOR')]");
        totalMinorVulnerabilities=totalMinorVulnerabilities+jsons:getInt(minorVulnerabilities,"$.length()");

        infoVulnerabilities = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')][?(@.severity=='INFO')]");
        totalInfoVulnerabilities=totalInfoVulnerabilities+jsons:getInt(infoVulnerabilities,"$.length()");


    }
    total=jsons:getInt(sonarJSONResponse,"$.total");

    json returnJson={"Total":total,"bb":totalBlockerBugs,"cb":totalCriticalBugs,"mab":totalMajorBugs,"mib":totalMinorBugs,"ib":totalInfoBugs,"bc":totalBlockerCodeSmells,
                        "cc":totalCriticalCodeSmells,"mac":totalMajorCodeSmells,"mic":totalMinorCodeSmells,"ic":totalInfoCodeSmell,"bv":totalBlockerVulnerabilities,"cv":totalCriticalVulnerabilities,
                        "mav":totalMajorVulnerabilities,"miv":totalMinorVulnerabilities,"iv":totalInfoVulnerabilities};
    return returnJson;
}

function allAreaSonars()(json){
    json data = {"error":false};
    json allAreas = {"items":[], "issuetype":[], "severity":[]};

    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    sql:Parameter[] params = [];

    datatable ssdt = sql:ClientConnector.select(dbConnector,GET_SNAPSHOT_ID,params);
    Snapshots ss;
    int snapshot_id;
    errors:TypeCastError err;
    while (datatables:hasNext(ssdt)) {
        any row = datatables:next(ssdt);
        ss, err = (Snapshots )row;

        snapshot_id= ss.snapshot_id;

    }
    datatables:close(ssdt);

    int BUGS=0;
    int CODESMELLS=0;
    int VULNERABILITIES=0;
    int CRITICAL=0;
    int BLOCKER=0;
    int MAJOR=0;
    int MINOR=0;
    int INFO=0;

    datatable dt = sql:ClientConnector.select(dbConnector,GET_ALL_AREAS, params);
    Areas area;
    while (datatables:hasNext(dt)) {
        any row1 = datatables:next(dt);
        area, err = (Areas)row1;

        string area_name = area.pqd_area_name;
        int area_id = area.pqd_area_id;


        int sonars=0;

        sql:Parameter pqd_area_id_para = {sqlType:"integer", value:area_id};
        params = [pqd_area_id_para];
        datatable pdt = sql:ClientConnector.select(dbConnector,GET_PRODUCTS_OF_AREA, params);
        Products product;
        while (datatables:hasNext(pdt)) {
            any rowp = datatables:next(pdt);
            product,err = (Products)rowp;

            int product_id = product.pqd_product_id;
            string product_sonar_key= product.sonar_project_key;

            sql:Parameter sonar_project_key_para = {sqlType:"varchar", value:product_sonar_key};
            sql:Parameter snapshot_id_para = {sqlType:"integer", value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable pidt = sql:ClientConnector.select(dbConnector, GET_ALL_OF_SONAR_ISSUES, params);
            SonarIssues si;
            while (datatables:hasNext(pidt)) {
                any row2 = datatables:next(pidt);
                si, err = (SonarIssues )row2;


                int bb = si.BLOCKER_BUG; int cb = si.CRITICAL_BUG; int mab = si.MAJOR_BUG; int mib = si.MINOR_BUG; int ib = si.INFO_BUG;
                int bc = si.BLOCKER_CODE_SMELL; int cc = si.CRITICAL_CODE_SMELL;int mac = si.MAJOR_CODE_SMELL;int mic = si.MINOR_CODE_SMELL;int ic = si.INFO_CODE_SMELL;
                int bv = si.BLOCKER_VULNERABILITY; int cv = si.CRITICAL_VULNERABILITY; int mav = si.MAJOR_VULNERABILITY; int miv = si.MINOR_VULNERABILITY;int iv = si.INFO_VULNERABILITY;
                int tot = si.total;
                BUGS= BUGS +bb+cb+mab+mib+ib;
                CODESMELLS= CODESMELLS +bc+cc+mac+mic+ic;
                VULNERABILITIES= VULNERABILITIES +bv+cv+mav+miv+iv;
                BLOCKER = BLOCKER + bb+bc+bv;
                CRITICAL = CRITICAL + cb+cc+cv;
                MAJOR = MAJOR + mab+mac+mav;
                MINOR = MINOR + mib+mic+miv;
                INFO = INFO + ib+ic+iv;
                sonars=sonars+tot;
            }
            datatables:close(pidt);
        }
        datatables:close(pdt);

        params = [pqd_area_id_para];
        datatable cdt = sql:ClientConnector.select(dbConnector,GET_COMPONENT_OF_AREA , params);
        Components comps;
        while (datatables:hasNext(cdt)) {
            any row0 = datatables:next(cdt);
            comps, err = (Components)row0;

            string project_key = comps.sonar_project_key;
            int component_id = comps.pqd_component_id;

            sql:Parameter sonar_project_key_para = {sqlType:"varchar", value:project_key};
            sql:Parameter snapshot_id_para = {sqlType:"integer", value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable idt = sql:ClientConnector.select(dbConnector,GET_ALL_OF_SONAR_ISSUES, params);
            SonarIssues si;
            while (datatables:hasNext(idt)) {
                any row2 = datatables:next(idt);
                si, err = (SonarIssues )row2;

                int bb = si.BLOCKER_BUG; int cb = si.CRITICAL_BUG; int mab = si.MAJOR_BUG; int mib = si.MINOR_BUG; int ib = si.INFO_BUG;
                int bc = si.BLOCKER_CODE_SMELL; int cc = si.CRITICAL_CODE_SMELL;int mac = si.MAJOR_CODE_SMELL;int mic = si.MINOR_CODE_SMELL;int ic = si.INFO_CODE_SMELL;
                int bv = si.BLOCKER_VULNERABILITY; int cv = si.CRITICAL_VULNERABILITY; int mav = si.MAJOR_VULNERABILITY; int miv = si.MINOR_VULNERABILITY;int iv = si.INFO_VULNERABILITY;
                int tot = si.total;

                BUGS= BUGS +bb+cb+mab+mib+ib;
                CODESMELLS= CODESMELLS +bc+cc+mac+mic+ic;
                VULNERABILITIES= VULNERABILITIES +bv+cv+mav+miv+iv;
                BLOCKER = BLOCKER + bb+bc+bv;
                CRITICAL = CRITICAL + cb+cc+cv;
                MAJOR = MAJOR + mab+mac+mav;
                MINOR = MINOR + mib+mic+miv;
                INFO = INFO + ib+ic+iv;
                sonars=sonars+tot;
            }
            datatables:close(idt);
        }
        datatables:close(cdt);

        json area_issues = {"name":area_name, "id":area_id, "issues":sonars};
        jsons:addToArray(allAreas, "$.items", area_issues);


    }
    datatables:close(dt);
    dbConnector.close();
    json bugs = {"name":"BUG", "issues":BUGS};
    jsons:addToArray(allAreas, "$.issuetype",bugs );
    json codesmells = {"name":"CODE SMELL", "issues":CODESMELLS};
    jsons:addToArray(allAreas, "$.issuetype",codesmells );
    json vulnerabilities = {"name":"VULNERABILITY", "issues":VULNERABILITIES};
    jsons:addToArray(allAreas, "$.issuetype",vulnerabilities);
    json blocker = {"name":"BLOCKER", "issues":BLOCKER};
    jsons:addToArray(allAreas, "$.severity",blocker);
    json critical = {"name":"CRITICAL", "issues":CRITICAL};
    jsons:addToArray(allAreas, "$.severity",critical);
    json major = {"name":"MAJOR", "issues":MAJOR};
    jsons:addToArray(allAreas, "$.severity",major);
    json minor = {"name":"MINOR", "issues":MINOR};
    jsons:addToArray(allAreas, "$.severity",minor);
    json info = {"name":"INFO", "issues":INFO};
    jsons:addToArray(allAreas, "$.severity",info);

    jsons:addToObject(data, "$", "data",allAreas);
    return data;
}

function authHeader (message req) (message) {
    string sonarAccessToken=jsons:getString(configData,"$.sonarAccessToken");
    string token=sonarAccessToken+":";
    string encodedToken = utils:base64encode(token);
    string passingToken = "Basic "+encodedToken;
    messages:setHeader(req, "Authorization", passingToken);
    messages:setHeader(req, "Content-Type", "application/json");
    return req;

}