package MySonarService;

import ballerina.lang.system;
import ballerina.lang.jsons;
function main (string[] args) {
    int i = 100;
    float k = 2.34;
    system:println("[default -> w1] i: " + i + " k: " + k);
    i, k -> w1;
    json j = {};
    j <- w1;
    system:println("[default <- w1] j: " + jsons:toString(j));
    worker w1 {
        int iw;
        float kw;
        iw, kw <- default;
        system:println("[w1 <- default] iw: " + iw + " kw: " + kw);
        json jw = {"name":"Ballerina"};
        system:println(add());
        system:println("[w1 -> default] jw: " + jsons:toString(jw));
        jw -> default;
    }
}
function add()(int a){
    int i=1;
    int j=2;
    i,j -> w1;
    int t;
    t<-w1;
    return t;
    worker w1{
        int iw;int jw;
        iw,jw <- default;
        int total=iw+jw;
        total->default;
    }

}