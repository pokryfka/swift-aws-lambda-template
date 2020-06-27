//  This file was automatically generated and should not be edited.

import AWSAppSync

public final class HelloQuery: GraphQLQuery {
    public static let operationString =
        "query Hello($secondsFromGMT: Int) {\n  hello(secondsFromGMT: $secondsFromGMT) {\n    __typename\n    hour\n    message\n  }\n}"

    public var secondsFromGMT: Int?

    public init(secondsFromGMT: Int? = nil) {
        self.secondsFromGMT = secondsFromGMT
    }

    public var variables: GraphQLMap? {
        ["secondsFromGMT": secondsFromGMT]
    }

    public struct Data: GraphQLSelectionSet {
        public static let possibleTypes = ["Query"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("hello", arguments: ["secondsFromGMT": GraphQLVariable("secondsFromGMT")], type: .nonNull(.object(Hello.selections))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
            self.snapshot = snapshot
        }

        public init(hello: Hello) {
            self.init(snapshot: ["__typename": "Query", "hello": hello.snapshot])
        }

        public var hello: Hello {
            get {
                Hello(snapshot: snapshot["hello"]! as! Snapshot)
            }
            set {
                snapshot.updateValue(newValue.snapshot, forKey: "hello")
            }
        }

        public struct Hello: GraphQLSelectionSet {
            public static let possibleTypes = ["Greeting"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("hour", type: .scalar(Int.self)),
                GraphQLField("message", type: .nonNull(.scalar(String.self))),
            ]

            public var snapshot: Snapshot

            public init(snapshot: Snapshot) {
                self.snapshot = snapshot
            }

            public init(hour: Int? = nil, message: String) {
                self.init(snapshot: ["__typename": "Greeting", "hour": hour, "message": message])
            }

            public var __typename: String {
                get {
                    snapshot["__typename"]! as! String
                }
                set {
                    snapshot.updateValue(newValue, forKey: "__typename")
                }
            }

            public var hour: Int? {
                get {
                    snapshot["hour"] as? Int
                }
                set {
                    snapshot.updateValue(newValue, forKey: "hour")
                }
            }

            public var message: String {
                get {
                    snapshot["message"]! as! String
                }
                set {
                    snapshot.updateValue(newValue, forKey: "message")
                }
            }
        }
    }
}
