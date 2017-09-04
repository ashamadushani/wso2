package SonarService;


import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.lang.jsons;
import ballerina.data.sql;
import ballerina.lang.datatables;
import ballerina.lang.errors;



struct ResultDataType {
string Product;
string Component;
string project_key;

}


@http:configuration{basePath:"/sonar-issues"}
service<http> SonarService {

    string dbURL = "jdbc:mysql://127.0.0.1:3306/Issues_DB";
    string username = "root";
    string password = "mysql";
    map propertiesMap = {"jdbcUrl":dbURL, "username":username, "password":password};
    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);



    @http:GET {}
    @http:Path {value:"/getProductIssues/{Product}/summary"}
    resource SonarProductIssueCount (message m, @http:PathParam {value:"Product"} string product) {
        sql:Parameter[] params = [];
        datatable dt = sql:ClientConnector.select(dbConnector, "SELECT p.Product, c.Component, c.project_key FROM JNKS_COMPONENTPRODUCT p INNER JOIN COMPONENTS c ON p.Product=c.Product", params);
        message response = {};
        json sonarPayload = {};
        ResultDataType rs;
        errors:TypeCastError err;
        while (datatables:hasNext(dt)) {
            any row = datatables:next(dt);
            rs, err = (ResultDataType)row;

            string product_name = rs.Product;
            string component_name = rs.Component;
            string project_key = rs.project_key;

            sonarPayload = issuesCount(project_key, product_name, component_name);
            messages:setJsonPayload(response, sonarPayload);
            reply response;

        }

    }
    @http:GET {}
    @http:Path {value:"/product-issues/{Product}/details"}
    resource SonarProductIssueDetails (message m, @http:PathParam {value:"Product"} string product) {

        sql:Parameter[] params = [];
        datatable dt = sql:ClientConnector.select(dbConnector, "SELECT p.Product, c.Component, c.project_key FROM JNKS_COMPONENTPRODUCT p INNER JOIN COMPONENTS c ON p.Product=c.Product", params);
        message response = {};
        json sonarPayload = {};
        json Sonar = {};
        ResultDataType rs;
        errors:TypeCastError err;
        while (datatables:hasNext(dt)) {
            any row = datatables:next(dt);
            rs, err = (ResultDataType)row;

            string product_name = rs.Product;
            string component_name = rs.Component;
            string project_key = rs.project_key;
            sonarPayload = issuesDetails(project_key, product_name, component_name);

            messages:setJsonPayload(response, sonarPayload);
            reply response;



        }

    }
    @http:GET {}
    @http:Path {value:"/component-issue/summary"}
    resource SonarComponentissueCount (message m) {
        http:ClientConnector sonarcon = create http:ClientConnector("http://sonarstg.wso2.com:9000");

        message request = {};
        message requestH = {};
        message sonarResponse = {};
        json sonarJSONResponse = {};
        message response = {};
        string Path = "/sonar/api/issues/search";
        requestH = authHeader(request);

        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
        sonarJSONResponse = messages:getJsonPayload(sonarResponse);

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
        json sonarPayload = {"componentId":component_Id, "Bugs":Bugs, "Total_Bugs":Total_Bugs, "Code_smell":Code_smell, "Total_Code_smell":Total_Code_smell, "Vulnerability":Vulnerability, "Total_Vulnerability":Total_Vulnerability};
        messages:setJsonPayload(response, sonarPayload);
        reply response;
    }
    @http:GET {}
    @http:Path {value:"/component-issue/details"}
    resource SonarComponentissueDetails (message m) {
        http:ClientConnector sonarcon = create http:ClientConnector("http://sonarstg.wso2.com:9000");

        message request = {};
        message requestH = {};
        message sonarResponse = {};
        json sonarJSONResponse = {};
        message response;
        string Path = "/sonar/api/issues/search";

        requestH = authHeader(request);

        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
        sonarJSONResponse = messages:getJsonPayload(sonarResponse);

        int objects = jsons:getInt(sonarJSONResponse, "$.length()");
        json Bugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')]");
        json Code_smell = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')]");
        json Vulnerability = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')]");
        json component_Id = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.componentId)]");
        json sonarPayload = {"componentId":component_Id, "Bugs":Bugs, "Code_smell":Code_smell, "Vulnerability":Vulnerability};
        messages:setJsonPayload(response, sonarPayload);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"authors/{+author}"}

    resource sonarAuthorDetails (message m, @http:PathParam {value:"author"} string authorName) {

        http:ClientConnector sonarcon = create http:ClientConnector("http://sonarstg.wso2.com:9000");
        message request = {};
        message requestH = {};
        message sonarResponse = {};
        json sonarJSONResponse = {};
        message response = {};
        string Path = "/sonar/api/issues/search?authors=" + authorName;
        requestH = authHeader(request);


        sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
        sonarJSONResponse = messages:getJsonPayload(sonarResponse);
        messages:setJsonPayload(response, sonarJSONResponse);
        reply response;

    }
}
function issuesCount (string project_key, string product, string component) (json) {
    http:ClientConnector sonarcon = create http:ClientConnector("http://sonarstg.wso2.com:9000");

    message request = {};
    message requestH = {};
    message sonarResponse = {};
    json sonarJSONResponse = {};

    string Path = "/sonar/api/issues/search?projectKeys=" + project_key;
    requestH = authHeader(request);

    sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
    sonarJSONResponse = messages:getJsonPayload(sonarResponse);

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
    json sonarPayload = {"componentId":component_Id, "Bugs":Bugs, "Total_Bugs":Total_Bugs, "Code_smell":Code_smell, "Total_Code_smell":Total_Code_smell, "Vulnerability":Vulnerability, "Total_Vulnerability":Total_Vulnerability};
    return sonarPayload;
}
function issuesDetails (string project_key, string product, string component) (json) {
    http:ClientConnector sonarcon = create http:ClientConnector("http://sonarstg.wso2.com:9000");

    message request = {};
    message requestH = {};
    message sonarResponse = {};
    json sonarJSONResponse = {};

    string Path = "/sonar/api/issues/search?projectKeys=" + project_key;
    requestH = authHeader(request);

    sonarResponse = http:ClientConnector.get(sonarcon, Path, requestH);
    sonarJSONResponse = messages:getJsonPayload(sonarResponse);
    int objects = jsons:getInt(sonarJSONResponse, "$.length()");
    json Bugs = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='BUG')]");
    json Code_smell = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='CODE_SMELL')]");
    json Vulnerability = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.type=='VULNERABILITY')]");
    json component_Id = jsons:getJson(sonarJSONResponse, "$.issues.[?(@.componentId)]");
    json sonarPayload = {"componentId":component_Id, "Bugs":Bugs, "Code_smell":Code_smell, "Vulnerability":Vulnerability};
    return sonarPayload;

}


function authHeader (message req) (message) {
    messages:setHeader(req, "Authentication:", "token cac8359a1fca77b86c2960b389482fa1d9cca197d");
    messages:setHeader(req, "Content-Type", "application/json");
    return req;

}
