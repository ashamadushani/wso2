package org.wso2.internalapps.productqualitydashboard;

const string CONFIG_PATH = "config.json";

const string API_VERSION = "v1.0";

const string INSERT_SNAPSHOT_DETAILS="INSERT INTO sonar_issues_date_table (date) VALUES (?)";

const string GET_SNAPSHOT_ID="SELECT snapshot_id FROM sonar_issues_date_table  ORDER BY snapshot_id DESC LIMIT 1";

const string INSERT_SONAR_ISSUES="INSERT INTO sonar_issues_table(snapshot_id,project_key,BLOCKER_BUG,CRITICAL_BUG,MAJOR_BUG,MINOR_BUG,INFO_BUG,BLOCKER_CODE_SMELL,CRITICAL_CODE_SMELL,MAJOR_CODE_SMELL,MINOR_CODE_SMELL,INFO_CODE_SMELL,BLOCKER_VULNERABILITY,CRITICAL_VULNERABILITY,MAJOR_VULNERABILITY,MINOR_VULNERABILITY,INFO_VULNERABILITY,total) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

const string GET_ALL_AREAS="SELECT pqd_area_id,pqd_area_name FROM pqd_area";

const string GET_PRODUCTS_OF_AREA="SELECT pqd_product_id,sonar_project_key FROM pqd_product WHERE pqd_area_id=?";

const string GET_TOTAL_OF_SONAR_ISSUES= "SELECT total FROM sonar_issues_table WHERE project_key=? and snapshot_id=?";

const string GET_ALL_OF_SONAR_ISSUES= "SELECT * FROM sonar_issues_table WHERE project_key=? and snapshot_id=?";

const string GET_COMPONENT_OF_AREA="SELECT pqd_component_id,sonar_project_key FROM pqd_component WHERE pqd_area_id=?";