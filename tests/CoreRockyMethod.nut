// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

@include "github:electricimp/Rocky/Rocky.class.nut"

// CoreRockyMethod
// Tests for Rocky.on, Rocky.VERB
// Should be included into file, witch contains getVerb() function
class CoreRockyMethod extends ImpTestCase {

    @include __PATH__+"/Core.nut"
    @include __PATH__+"/CoreHandlers.nut"
  
    function setUp() {
        this.info("Test for VERB: " + getVerb());
    }

    function testSimple() {
        return createTest({
            "signature": "/testSimple", 
            "method": getVerb()
        });
    }

    function testSimpleStrict() {
        return createTest({
            "signature": "/testSimple", 
            "method": getVerb(),
            "methodStrictUsage": true
        });
    }

    function testFull() {
        return createTest({
            "signature": "/testFull", 
            "method": getVerb(),
            "headers": {
                "testFull": "testFull", 
                "GenericVerbCompatibilityTest": true
            },
            "body": "testFull body"
        });
    }

    function testSimpleWOSignature() {
        return createTest({
            "signature": "/", 
            "method": getVerb()
        });
    }

    function testWOSignatureFull() {
        return createTest({
            "signature": "/", 
            "method": getVerb(),
            "headers": {
                "testWOSignatureFull": 35, 
                "GenericVerbCompatibilityTest": false
            },
            "body": "testWOSignatureFull body"
        });
    }

    function testTimeout() {
        return createTest({
            "signature": "/testTimeout", 
            "method": getVerb(),
            "headers": {
                "testTimeout": 35, 
                "GenericVerbCompatibilityTest": "testTimeout"
            },
            "body": "testTimeout body",
            "timeoutRoute": 15
        });
    }

    function testSimpleRegexp_1() {
        return createTest({
            "signature": ".*", 
            "signatureOverride": "/testSimpleRegexp_1",
            "method": getVerb()
        });
    }

    function testSimpleRegexp_2() {
        return createTest({
            "signature": "/test1(.*/test\\d.*)", 
            "signatureOverride": "/test1/test2/test3",
            "method": getVerb(),
            "callback": function(context) {
                try {
                    if (context.matches.len() != 2) {
                        throw "Wrong context.matches.len()=" + context.matches.len() + ", should be 2";
                    } else if ("/test2/test3" != context.matches[1]) {
                        throw "Wrong context.matches[1]=" +  context.matches[1]+ ", should be /test2/test3";
                    }
                    context.send(200, {"message": "OK"});
                } catch (ex) {
                    this.info(ex);
                    context.send(500, {"error": ex});
                }
            }.bindenv(this)
        });
    }

    function testContentTypeJson() {
        return contentType({
            "contentType": "contentType", 
            "content-type": "application/json"
        }, "application/json", http.jsonencode({"contentType": "body"}));
    }

    function testContentTypeForm() {
        return contentType({
            "contentType": "contentType", 
            "content-type": "application/x-www-form-urlencoded"
        }, "application/x-www-form-urlencoded", "contentType=body");
    }

    function testContentTypeMultipart() {
        local body = "--ff4ed67396bc8e1d6dbf19d65b6c6348\r\nContent-Disposition: form-data; name=\"contentType\"\r\n\r\nbody\r\n--ff4ed67396bc8e1d6dbf19d65b6c6348\r\nContent-Disposition: form-data; name=\"tmp\"\r\n\r\nContent file\r\n--ff4ed67396bc8e1d6dbf19d65b6c6348";
        return contentType({
            "contentType": "contentType", 
            "content-type": "multipart/form-data; boundary=--ff4ed67396bc8e1d6dbf19d65b6c6348",
            "Content-Length": body.len()
        }, "multipart/form-data; boundary=--ff4ed67396bc8e1d6dbf19d65b6c6348", body);
    }

    function contentType(headers, contentType, body) {
        return createTest({
            "signature": "/contentType", 
            "method": getVerb(),
            "headers": headers,
            "body": body,
            "callback": function(context) {
                try {
                    local tmp = context.req.headers;
                    if ("content-type" in tmp) {
                        if (contentType != tmp["content-type"]) {
                            throw "Wrong content-type=" + tmp["content-type"] + ", should be " + contentType;
                        }
                        tmp = context.req.body;
                        if ("table" != type(tmp)) {
                            throw "Wrong type of context.req.body " + type(tmp) + ", should be table";
                        } else if (!("contentType" in tmp) || "body" != tmp["contentType"]) {
                            this.info("---------actual body----------");
                            deepLog(tmp);
                            throw "Wrong context.req.body";
                        }
                    } else {
                        throw "content-type is absent in headers";
                    }
                    context.send(200, body);
                } catch (ex) {
                    this.info(ex);
                    context.send(500, {"error": ex});
                }
            }.bindenv(this),
            "callbackVerify": function(res) {
                return body == res.body;
            }.bindenv(this)
        });
    }

    function testQuery() {
        return createTest({
            "signature": "/testQuery", 
            "signatureOverride": "/testQuery?first=1&second=2", 
            "method": getVerb(),
            "callback": function(context) {
                try {
                    if (!("first" in context.req.query && context.req.query["first"] == "1")) {
                        throw "Invalid context.req.query. Should contain 'first' with value '1'";
                    }
                    if (!("second" in context.req.query && context.req.query["second"] == "2")) {
                        throw "Invalid context.req.query. Should contain 'second' with value '2'";
                    }
                    context.send(200, {"message": "OK"});
                } catch (ex) {
                    this.info(ex);
                    context.send(500, {"error": ex});
                }
            }.bindenv(this)
        });
    }
}
