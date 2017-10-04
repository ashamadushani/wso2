package MySonarService;


import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.lang.jsons;
import ballerina.data.sql;
import ballerina.lang.errors;
import ballerina.lang.datatables;
import ballerina.lang.system;
import ballerina.lang.time;
import ballerina.utils;


struct ResultDataType{
    string pqd_product_name;
    string pqd_sonar_project_key;
}

struct Snapshots{
    int snapshot_id;
}

struct Sonar_Issues{
    int sonar_component_issue_id;
    int snapshot_id;
    string project_key;
    int BLOCKER_BUG; int CRITICAL_BUG; int MAJOR_BUG; int MINOR_BUG; int INFO_BUG;
    int BLOCKER_CODE_SMELL; int CRITICAL_CODE_SMELL; int MAJOR_CODE_SMELL; int MINOR_CODE_SMELL; int INFO_CODE_SMELL;
    int BLOCKER_VULNERABILITY; int CRITICAL_VULNERABILITY; int MAJOR_VULNERABILITY; int MINOR_VULNERABILITY; int INFO_VULNERABILITY;
}

struct Product_Names{
    string pqd_product_name;
    string pqd_sonar_project_key;
}

struct Component_Keys{
    string pqd_component_id;
    string pqd_sonar_project_key;
}

struct Area_Names{
    string pqd_area_name;
}

string basicurl="https://wso2.org/sonar";

string dbURL = "jdbc:mysql://127.0.0.1:3306";
string mysqlusername = "root";
string mysqlpassword = "mysql";
map propertiesMap = {"jdbcUrl":dbURL, "username":mysqlusername, "password":mysqlpassword};



@http:configuration {basePath:"/sonarissuestodb"}
service<http> SonarIssuestoDB{
    @http:GET {}
    @http:Path {value:"/fetchdata"}
    resource sayHello (message m) {
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
        componentIssues(projects);

        messages:setJsonPayload(response, projects);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;


    }
}

@http:configuration {basePath:"/sonarissues"}
service<http> MySonarService{

    @http:GET {}
    @http:Path {value:"/getTotalIssues"}
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
        sonarJSONResponse =messages:getJsonPayload(sonarResponse);
        int total = jsons:getInt(sonarJSONResponse, "$.total");

        string tot=<string >total;

        time:Time currentTime = time:currentTime();
        string customTimeString = time:format(currentTime, "yyyy-MM-dd--HH:mm:ss");

        json sonarPayload = {"Date":customTimeString,"TotalIssues":tot};

        messages:setJsonPayload(response, sonarPayload);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;

    }

    @http:GET {}
    @http:Path {value:"/getAllIssues"}
    resource SonarAllIssue (message m) {
        json rspns=[];
        json areas=[];
        json products=[];
        json pns=[];
        int i=0;int n=0;

        sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

        sql:Parameter[] params = [];

        datatable ssdt = sql:ClientConnector.select(dbConnector,"SELECT snapshot_id FROM sonar_issue_db.sonar_component_issue_table ORDER BY snapshot_id DESC LIMIT 1",params);
        Snapshots ss;
        int snapshot_id;
        errors:TypeCastError err;
        while (datatables:hasNext(ssdt)) {
            any row = datatables:next(ssdt);
            ss, err = (Snapshots )row;

            snapshot_id= ss.snapshot_id;

        }
        datatables:close(ssdt);

        int j=0;
        datatable dt = sql:ClientConnector.select(dbConnector, "SELECT pqd_area_name FROM WSO2_Product_Quality.pqd_area", params);
        Area_Names an;
        while (datatables:hasNext(dt)) {
            any row1 = datatables:next(dt);
            an, err = (Area_Names)row1;

            string area_name = an.pqd_area_name;
            areas[j] = area_name;
            j = j + 1;

            json productNames=[];
            json productIssues=[];
            datatable pdt = sql:ClientConnector.select(dbConnector, "SELECT pqd_product_name,pqd_sonar_project_key FROM WSO2_Product_Quality.pqd_product WHERE pqd_area_name='" + area_name + "'", params);
            Product_Names pn;
            int k=0;
            int l=0;
            while (datatables:hasNext(pdt)) {
                any rowp = datatables:next(pdt);
                pn,err = (Product_Names)rowp;

                string product_name = pn.pqd_product_name;
                string product_sonar_key= pn.pqd_sonar_project_key;
                productNames[k] = product_name;
                k = k+1;

                datatable pidt = sql:ClientConnector.select(dbConnector, "SELECT * FROM sonar_issue_db.sonar_component_issue_table WHERE project_key='" + product_sonar_key + "' and snapshot_id=" + snapshot_id, params);
                Sonar_Issues si;

                while (datatables:hasNext(pidt)) {
                    any row2 = datatables:next(pidt);
                    si, err = (Sonar_Issues)row2;

                    string pk = si.project_key;

                    int bb = si.BLOCKER_BUG; int cb = si.CRITICAL_BUG; int mab = si.MAJOR_BUG; int mib = si.MINOR_BUG; int ib = si.INFO_BUG;
                    int bc = si.BLOCKER_CODE_SMELL; int cc = si.CRITICAL_CODE_SMELL;int mac = si.MAJOR_CODE_SMELL;int mic = si.MINOR_CODE_SMELL;int ic = si.INFO_CODE_SMELL;
                    int bv = si.BLOCKER_VULNERABILITY; int cv = si.CRITICAL_VULNERABILITY; int mav = si.MAJOR_VULNERABILITY; int miv = si.MINOR_VULNERABILITY;int iv = si.INFO_VULNERABILITY;

                    json comp = {"area":area_name, "pk":product_name, "bb":bb, "cb":cb, "mab":mab, "mib":mib, "ib":ib, "bc":bc, "cc":cc, "mac":mac, "mic":mic, "ic":ic, "bv":bv, "cv":cv, "mav":mav, "miv":miv, "iv":iv};
                    productIssues[l] = comp;
                    l = l + 1;
                }

                datatables:close(pidt);



                datatable cdt = sql:ClientConnector.select(dbConnector, "SELECT pqd_component_id,pqd_sonar_project_key FROM WSO2_Product_Quality.pqd_component WHERE pqd_product_name='" + product_name + "'", params);
                Component_Keys ck;
                while (datatables:hasNext(cdt)) {
                    any row0 = datatables:next(cdt);
                    ck, err = (Component_Keys)row0;

                    string project_key = ck.pqd_sonar_project_key;
                    string component_id = ck.pqd_component_id;

                    datatable idt = sql:ClientConnector.select(dbConnector, "SELECT * FROM sonar_issue_db.sonar_component_issue_table WHERE project_key='" + project_key + "' and snapshot_id=" + snapshot_id, params);

                        while (datatables:hasNext(idt)) {
                            any row2 = datatables:next(idt);
                            si, err = (Sonar_Issues)row2;

                            string pk = si.project_key;

                            int bb = si.BLOCKER_BUG; int cb = si.CRITICAL_BUG; int mab = si.MAJOR_BUG; int mib = si.MINOR_BUG; int ib = si.INFO_BUG;
                            int bc = si.BLOCKER_CODE_SMELL; int cc = si.CRITICAL_CODE_SMELL;int mac = si.MAJOR_CODE_SMELL;int mic = si.MINOR_CODE_SMELL;int ic = si.INFO_CODE_SMELL;
                            int bv = si.BLOCKER_VULNERABILITY; int cv = si.CRITICAL_VULNERABILITY; int mav = si.MAJOR_VULNERABILITY; int miv = si.MINOR_VULNERABILITY;int iv = si.INFO_VULNERABILITY;

                            json comp = {"area":area_name,"product":product_name, "pk":component_id, "bb":bb, "cb":cb, "mab":mab, "mib":mib, "ib":ib, "bc":bc, "cc":cc, "mac":mac, "mic":mic, "ic":ic, "bv":bv, "cv":cv, "mav":mav, "miv":miv, "iv":iv};
                            rspns[i] = comp;

                            i = i + 1;
                        }
                        datatables:close(idt);
                }
                datatables:close(cdt);
            }
            datatables:close(pdt);
            pns[n]=productNames;
            products[n]=productIssues;
            n=n+1;

        }
        datatables:close(dt);
        dbConnector.close();
        json returnJson={"areas":areas,"pns":pns,"products":products,"components":rspns};
        message response = {};
        messages:setJsonPayload(response,returnJson);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        reply response;

    }

    @http:GET {}
    @http:Path {value:"/getProductIssues/{Product}/summary"}
    resource SonartIssueCountSummary (message m, @http:PathParam {value:"Product"} string product) {

        sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

        sql:Parameter[] params = [];
        datatable dt = sql:ClientConnector.select(dbConnector, "SELECT pqd_product_name,pqd_sonar_project_key FROM WSO2_Product_Quality.pqd_product where pqd_product_id='"+product+"'", params);
        message response = {};
        json sonarPayload = {};
        ResultDataType rs;
        errors:TypeCastError err;
        while (datatables:hasNext(dt)) {
            any row = datatables:next(dt);
            rs, err = (ResultDataType)row;

            string product_name = rs.pqd_product_name;
            string project_key = rs.pqd_sonar_project_key;
            sonarPayload = issuesCount(project_key, product_name); messages:setJsonPayload(response, sonarPayload);
            reply response;

        }
        datatables:close(dt);
        dbConnector.close();

    }

    @http:GET {}
    @http:Path {value:"/getEngineerIssues/{Author}/summary"}
    resource SonarProductIssueCountPerEngineer (message m, @http:PathParam {value:"Author"} string authorName) {

        http:ClientConnector sonarcon = create http:ClientConnector(basicurl);
        message request = {};
        message requestH = {};
        message sonarResponse = {};
        json sonarJSONResponse = {};
        message response = {};
        string Path = "/api/issues/search?authors=" + authorName+"@wso2.com";
        requestH = authHeader(request);


        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
        sonarJSONResponse = messages:getJsonPayload(sonarResponse);
        messages:setJsonPayload(response, sonarJSONResponse);
        reply response;


        }

    }

function issuesCount (string project_key, string product) (json) {

    http:ClientConnector sonarcon = create http:ClientConnector(basicurl);

    message request = {};
    message requestH = {};
    message sonarResponse = {};
    json sonarJSONResponse = {};

    string Path = "/api/issues/search?resolved=no&projectKeys=" + project_key;
    requestH = authHeader(request);
    system:println(basicurl+Path);
    sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
    system:println(sonarResponse);
    sonarJSONResponse = messages:getJsonPayload(sonarResponse);

    int total =jsons:getInt(sonarJSONResponse,"$.total");
    int objects = jsons:getInt(sonarJSONResponse, "$.length()");
    json Bugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')]");
    int Total_Bugs = jsons:getInt(Bugs, "$.length()");
    json Code_smell = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')]");
    int Total_Code_smell = jsons:getInt(Code_smell, "$.length()");
    json Vulnerability = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')]");
    int Total_Vulnerability = jsons:getInt(Vulnerability, "$.length()");
    json component_Id = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.componentId)].componentId");
    json Authors = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.author)].author");

    json msg = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.message)].message");
    json creation_date = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.creationDate)].creationDate");
    json update_date_date = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.updateDate)].updateDate");
    json sonarPayload = {"total":total,"componentId":component_Id, "Bugs":Bugs, "Total_Bugs":Total_Bugs, "Code_smell":Code_smell, "Total_Code_smell":Total_Code_smell, "Vulnerability":Vulnerability, "Total_Vulnerability":Total_Vulnerability};
    return sonarPayload;
}

function componentIssues(json projects){
    int lz=lengthof projects;
    system:println(lz);
    lz -> w1;

    worker w1 {
        int loopsize;
        loopsize<-default;

        sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);
        sql:Parameter[] params = [];

        string customStartTimeString = time:format(time:currentTime(), "yyyy-MM-dd--HH:mm:ss");
        system:println("Start time: " + customStartTimeString);

        sql:Parameter todayDate = {sqlType:"varchar", value:customStartTimeString};
        params = [todayDate];
        int ret = sql:ClientConnector.update(dbConnector, "INSERT INTO sonar_issue_db.date_table (date) VALUES (?)", params);

        params = [];
        datatable dt = sql:ClientConnector.select(dbConnector, "SELECT snapshot_id FROM sonar_issue_db.date_table  ORDER BY snapshot_id DESC LIMIT 1", params);

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

                params = [snapshotid, projectkey, bb1, cb1, mab1, mib1, ib1, bc1, cc1, mac1, mic1, ic1, bv1, cv1, mav1, miv1, iv1];
                int ret1 = sql:ClientConnector.update(dbConnector, "INSERT INTO sonar_issue_db.sonar_component_issue_table(snapshot_id,project_key,BLOCKER_BUG,CRITICAL_BUG,MAJOR_BUG,MINOR_BUG,INFO_BUG,BLOCKER_CODE_SMELL,CRITICAL_CODE_SMELL,MAJOR_CODE_SMELL,MINOR_CODE_SMELL,INFO_CODE_SMELL,BLOCKER_VULNERABILITY,CRITICAL_VULNERABILITY,MAJOR_VULNERABILITY,MINOR_VULNERABILITY,INFO_VULNERABILITY) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", params);
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

function authHeader (message req) (message) {
    string token="f83a37e2ee709f7f2dd55c7c311632fe309d14fd"+":";
    string encodedToken = utils:base64encode(token);
    string passingToken = "Basic "+encodedToken;
    messages:setHeader(req, "Authorization", passingToken);
    messages:setHeader(req, "Content-Type", "application/json");
    return req;

}



