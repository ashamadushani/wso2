package MySonarService;

import ballerina.lang.files;
import ballerina.lang.blobs;
import ballerina.lang.system;
import ballerina.lang.strings;
import ballerina.lang.jsons;

function main (string[] args) {

    files:File target = {path:"tmp/result.txt"};
    files:open(target, "w");

    json j1={name:"Asha",age:23};
    string js=jsons:toString(j1);
    blob content = strings:toBlob(js, "utf-8");
    files:write(content, target);

    files:close(target);

    files:open(target, "r");
    var content, n = files:read(target, 100000);
    string s = blobs:toString(content, "utf-8");
    system:println("file content: " + s);
    files:close(target);


}