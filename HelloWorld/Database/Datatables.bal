package Database;

import ballerina.lang.system;
import ballerina.lang.datatables;
import ballerina.data.sql;

struct ResultDataType {
    string pqd_product_name;
    string pqd_product_id;
    string pqd_sonar_project_key;
}


function main (string[] args) {
    string dbURL = "jdbc:mysql://127.0.0.1:3306/WSO2_Product_Quality";
    string username = "root";
    string password = "mysql";
    map propertiesMap = {"jdbcUrl":dbURL, "username":username, "password":password};
    sql:ClientConnector dbConnector = create sql:ClientConnector(propertiesMap);

    system:println(dbConnector);
    sql:Parameter[] params = [];
    datatable dt = sql:ClientConnector.select(dbConnector, "SELECT pqd_product_name,pqd_product_id,pqd_sonar_project_key FROM pqd_product", params);

    while (datatables:hasNext(dt)) {
        any dataStruct = datatables:next(dt);
        var rs, _ = (ResultDataType)dataStruct;
        system:println("Result:" + rs.pqd_product_name + "|" + rs.pqd_product_id +"|" + rs.pqd_sonar_project_key);
    }

    sql:ClientConnector.close(dbConnector);
}

