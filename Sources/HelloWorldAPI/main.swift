import AWSLambdaRuntime
import AWSLambdaEvents

#if DEBUG
try Lambda.withLocalServer {
    Lambda.run { (context, request: APIGateway.Request, callback: (Result<APIGateway.Response, Error>) -> Void) in
        let reponse = APIGateway.Response(statusCode: HTTPResponseStatus.ok, body: "OK")
        callback(.success(reponse))
    }
}
#else
Lambda.run { (context, request: APIGateway.Request, callback: (Result<APIGateway.Response, Error>) -> Void) in
    let reponse = APIGateway.Response(statusCode: HTTPResponseStatus.ok, body: "OK")
    callback(.success(reponse))
}
#endif
