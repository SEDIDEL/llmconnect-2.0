# LLMConnect 2.0

> *"Ship fast, scale safely, delight always."*

LLMConnect 2.0 is a multiplatform application (iOS, iPadOS, macOS, watchOS, with visionOS support) that provides users with a unified interface to interact with multiple AI language models. This is a complete rebuild of the original LLMConnect app with improved architecture, enhanced features, and better scalability.

## Features

- **Unified Chat Interface**: Seamlessly interact with multiple AI providers (OpenAI, Anthropic, Groq, etc.)
- **Custom AI Bots**: Create specialized AI assistants with custom personalities and knowledge bases
- **Prompt Library**: Save and reuse effective prompts
- **Memory System**: Store and retrieve contextual information for more relevant AI responses
- **Image Generation**: Create images through multiple AI models
- **Organization System**: Comprehensive system for managing chats and bots
- **Cross-Platform**: Consistent experience across Apple platforms

## Requirements

- iOS 17+
- iPadOS 17+
- macOS 14+
- watchOS 10+
- visionOS 1.0+ (experimental)
- Xcode 16+
- Swift 6.0+

## Architecture

LLMConnect 2.0 follows a Clean Architecture pattern with MVVM-C (Model-View-ViewModel with Coordinator) to ensure separation of concerns, testability, and maintainability.

### Layers

```
+---------------------+
|     Presentation    |   Views, ViewModels, Coordinators
+---------------------+
|     Application     |   Use Cases, Services
+---------------------+
|       Domain        |   Entities, Repository Interfaces
+---------------------+
|        Data         |   Repository Implementations, Data Sources
+---------------------+
|    Infrastructure   |   Networking, Persistence, External Providers
+---------------------+
```

## Getting Started

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/llmconnect2.0.git
cd llmconnect2.0
```

2. Open the project in Xcode
```bash
open LLMConnect2.0/LLMConnect2.0.xcodeproj
```

3. Build and run the project

### Configuration

You'll need to provide API keys for the AI providers you wish to use:

- OpenAI API key
- Anthropic API key
- Groq API key
- Other provider keys as needed

These can be configured in the app's settings.

## Development

### Prerequisites

- Xcode 16+
- SwiftFormat
- SwiftLint

### Code Style

This project uses SwiftFormat and SwiftLint to maintain code quality and consistency.

To format the code:
```bash
swiftformat .
```

To lint the code:
```bash
swiftlint
```

### Testing

```bash
# Run unit tests
xcodebuild -project LLMConnect2.0/LLMConnect2.0.xcodeproj -scheme LLMConnect2.0 -configuration Debug test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [OpenAI](https://openai.com) - For their GPT models
- [Anthropic](https://anthropic.com) - For Claude models
- [Groq](https://groq.com) - For fast LLM inference
- And all other AI providers integrated in the app