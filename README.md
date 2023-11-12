# GPTConnector

A small wrapper around the OpenAI Api for chat completions.

## Usage

### Basic Chat
Add the package to your project and import the GPTConnector:

```swift
import GPTConnector
```

Then create a connector instance with your API Key from the OpenAI api.

```swift
let connector = GPTConnectorFactory.create(apiKey: YOUR_API_KEY)

// alternatively you can also pass the number of choices you want to receive, default is 1.

let connector = GPTConnectorFactory.create(apiKey: YOUR_API_KEY, numberOfChoices: 5)
```

Number of choices is the alternative results the api will return.

Now if you have your instance you can start to chat with GPT.

```swift

var currentChat = Chat(
    messages: [
        .system("You are a helpful assistant.")
    ],
    tools: []
)

// You have to provide at least one message. Either a system or a user message. You can also prefill the chat if you want to give context.

currentChat = connector.chat(context: currentChat) // chat will return an updated chat object with the messages added while running the chat.

let userInput = getTheUserInput()

currentChat = currentChat.byAddingMessage(.user(userInput())

// get the next message from the model:

currentChat = connector.chat(context: currentChat)

```

### The Chat model:

The `Chat` is the basic instance you will work on. It is the given context window for the model and also the return value. So you can iteratively work on the chat model.
The model has some default values, so usually you just have to fill it with messages.

```
Parameters:
model: String = "gpt-4-1106-preview",
messages: [Message],
temperature: Float = 0.7,
functions: [Function] = [],
functionCall: FunctionCallInstruction = .auto
```

By default the context will be using the model "gpt-4-1106-preview" but you can use any chat model OpenAI is providing.

### Tools Calling:

Some models like gpt-4 are able to call tools if they are provided:

```swift
let chat = Chat(
    messages: [.system("Test Message")],
    tools: [
        Tool(
            function: Function(
                name: "some_function",
                description: "The description for the model.",
                parameters: [
                    Function.Property(
                        name: "boolean_name",
                        type: .boolean,
                        description: "The description of the parameter.",
                        required: true
                    ),
                    Function.Property(
                        name: "integer_name",
                        type: .integer,
                        description: "The description of the parameter.",
                        required: false
                    ),
                    Function.Property(
                        name: "string_name",
                        type: .string,
                        description: "The description of the parameter.",
                        required: true
                    )
                ]
            )
        )
    ]
)
```

In this example we pass three functions to the model. If it decides to call a function you have to pass at least the callback `onToolCall` to handle the call and return the a result to the model.

```swift

currentChat = connector.chat(
    context: currentChat,
    onToolCall: { call in
        switch call.function.name {
        case "some_function": return "some function result"
        default: throw .functionNotKnown
        }
    }
)

```

If `numberOfChoices` was set to more than one, you also might want to pass the parameter `messageReceivedCallback` to select which choice should be taken.
The callback is called on every chat interaction but if not passed it will by default always choose the first choice.

```swift
chat(
    context: initialChat,
    messageReceivedCallback: { messages, currentContext in
        /// currentContext is the Chat at the moment the choice needs to be done.
        return messages[2]
    },
    onToolCall: { call in
        return "the function result"
    }
)
```
