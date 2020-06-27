import AnyCodable

// https://docs.amplify.aws/cli/graphql-transformer/directives#usage-1

// event
// {
//   "typeName": "Query", /* Filled dynamically based on @function usage location */
//   "fieldName": "me", /* Filled dynamically based on @function usage location */
//   "arguments": { /* GraphQL field arguments via $ctx.arguments */ },
//   "identity": { /* AppSync identity object via $ctx.identity */ },
//   "source": { /* The object returned by the parent resolver. E.G. if resolving field 'Post.comments', the source is the Post object. */ },
//   "request": { /* AppSync request object. Contains things like headers. */ },
//   "prev": { /* If using the built-in pipeline resolver support, this contains the object returned by the previous function. */ },
// }

// TODO: create Identity struct

// TODO: use @dynamicMemberLookup for arguments?

struct Amplify {
    enum RequestType: String, Decodable {
        case query = "Query"
        case mutation = "Mutation"
    }
    
    struct Request: Decodable {
        typealias Arguments = [String: AnyDecodable]
        
        let typeName: RequestType
        let fieldName: String
        let arguments: Arguments?
        let identity: AnyDecodable?
        let source: AnyDecodable?
        let request: AnyDecodable?
        let prev: AnyDecodable?
    }
}
