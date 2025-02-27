import ballerina/http;
import ballerina/log;

type ClientRoute record {|
    readonly string clientID;
    string clientURL;
|};

isolated table<ClientRoute> key(clientID) routes = table [
    {clientID: "uat", clientURL: "https://rt1-uat.raintreeinc.com/uat/api/"},
    {clientID: "sqa", clientURL: "https://rt1-sqa.raintreeinc.com/sqa/api/"}
];

service /proxy on new http:Listener(8086) {

    resource isolated function 'default [string... path](http:Request request) returns error|http:Response {
        string clientUniqueId = request.hasHeader("clientId")?  check request.getHeader("clientId") : "";
        string bearerToken = request.hasHeader("BackEndToken")? check request.getHeader("BackEndToken") : "";

        string dynamicHost = "";
        ClientRoute? dynamicClientRoute;
        lock {
            dynamicClientRoute = routes[clientUniqueId].clone();
        }
        if dynamicClientRoute is ClientRoute {
            dynamicHost = dynamicClientRoute["clientURL"];
        } else {
            log:printDebug("Dynamic route path not found");
        }
        string resourcePath = request.rawPath.substring(6);
    
        http:Client newRoute = check new (dynamicHost);
        if (bearerToken.length()>0){
            request.setHeader("Authorization", bearerToken);
        }
        http:Response response = check newRoute->forward(resourcePath, request);
        return response;
   
    }
}