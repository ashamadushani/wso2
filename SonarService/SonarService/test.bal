package SonarService;

import ballerina.net.http;
import ballerina.lang.messages;

@http:configuration {basePath:"/hello"}
service<http> HelloService {

    @http:resourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource sayHello (message m) {
        message response = {};
        messages:setStringPayload(response, "Hello World !!!");
        reply response;
    }
}
