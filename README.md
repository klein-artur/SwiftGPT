# GPTConnector

A small wrapper around the OpenAI Api for chat completions. Simple said, it's a wrapper to use GPT models in a chat manner.

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

var currentChat = Chat(messages: [
    .system("You are a helpful assistant.")
])

// You have to provide at least one message. Either a system or a user message. You can also prefill the chat if you want to give context.

currentChat = connector.chat(context: currentChat).first! // chat will return an array of possible chat outcomes that will fit `numberOfChoices` which is by default 1.

let userInput = getTheUserInput()

currentChat = currentChat.byAddingMessage(.user(userInput())

// get the next message from the model:

currentChat = connector.chat(context: currentChat).first!

```

### The Chat model:

The `Chat` is the basic instance you will work on. It is the given context window for the model and also the return value. So you can iteratively work on the chat model.
The model has some default values, so usually you just have to fill it with messages.

```
Parameters:
model: String = "gpt-4",
messages: [Message],
temperature: Float = 0.7,
functions: [Function] = [],
functionCall: FunctionCallInstruction = .auto
```

By default the context will be using the model GPT4 but you can use any chat model OpenAI is providing.

### Function Calling:

Some models like gpt-4 are able to call functions if they are provided:

```swift
Chat(
    messages: [
        .system("Test Message")
    ],
    functions: [
        Function(
            name: "some_function",
            description: "The description for the model.",
            parameters: [
                Function.Property(
                    name: "property_name",
                    type: .boolean,
                    description: "The description of the parameter.",
                    required: true
                ),
                Function.Property(
                    name: "property_name",
                    type: .integer,
                    description: "The description of the parameter.",
                    required: false
                ),
                Function.Property(
                    name: "property_name",
                    type: .string,
                    description: "The description of the parameter.",
                    required: true
                )
            ]
        )
    ]
)
```

In this example we pass three functions to the model. If it decides to call a function you have to pass at least the callback `onFunctionCall` to handle the call and return the a result to the model.

```swift

currentChat = connector.chat(
    context: currentChat,
    onFunctionCall: { functionName, arguments in
        switch functionName {
        case "some_function": return "some function result"
        default: throw .functionNotKnown
        }
    }
).first!

```

If `numberOfChoices` was set to more than one, you also might want to pass the parameter `onChoiceSelect` to select which choice should be taken. It's possible that not every choice is a function call. If you select a choice that is no functionc all the method will return the choices as a result.

```swift
chat(
    context: initialChat,
    onChoiceSelect: { messages, currentContext in
        /// currentContext is the Chat at the moment the choice needs to be done.
        return messages[2]
    },
    onFunctionCall: { functionName, arguments in
        return "the function result"
    }
)
```
