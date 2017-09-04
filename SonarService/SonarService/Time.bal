package SonarService;
import ballerina.lang.time;

import ballerina.lang.system;

function main (string[] args) {
    time:Time currentTime = time:currentTime();
    string customeTimeString = time:format(currentTime, "yyyy-MM-dd--HH:mm:ss");
    system:println("Current system time in custom format:" + customeTimeString);
}
