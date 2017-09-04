package Ser;

import ballerina.lang.messages;
import ballerina.net.http;


service<http> helloWorld {
    resource sayHello (message m) {
        message response = {};
        messages:setStringPayload(response, "Hello, World!");
        reply response;
    }
}