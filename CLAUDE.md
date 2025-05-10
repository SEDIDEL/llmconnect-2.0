# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LLMConnect 2.0 is a multiplatform application (iOS, iPadOS, macOS, watchOS, with optional visionOS support) built in Swift that provides users with a unified interface to interact with multiple AI language models. This is a complete rebuild of the original LLMConnect app with improved architecture, enhanced features, and better scalability.

## Development Setup

### Required Tools
- Xcode 16+ (minimum)
- Swift 6.0+
- SwiftFormat (configured in .swiftformat)
- SwiftLint (configured in .swiftlint.yml)

### Build Commands

```bash
# Open the project in Xcode
open LLMConnect2.0/LLMConnect2.0.xcodeproj

# Build the project
xcodebuild -project LLMConnect2.0/LLMConnect2.0.xcodeproj -scheme LLMConnect2.0 -configuration Debug build

# Run tests
xcodebuild -project LLMConnect2.0/LLMConnect2.0.xcodeproj -scheme LLMConnect2.0 -configuration Debug test

# Format code using SwiftFormat
swiftformat .

# Lint code using SwiftLint
swiftlint
```

## Project Architecture

LLMConnect 2.0 follows a Clean Architecture pattern with MVVM-C (Model-View-ViewModel with Coordinator) to ensure separation of concerns, testability, and maintainability.

### Architectural Layers

1. **Presentation Layer**: Views, ViewModels, Coordinators
2. **Application Layer**: Use Cases, Services
3. **Domain Layer**: Entities, Repository Interfaces
4. **Data Layer**: Repository Implementations, Data Sources
5. **Infrastructure Layer**: Networking, Persistence, External Providers

### Key Design Principles

- **Dependency Rule**: Inner layers know nothing about outer layers
- **Dependency Injection**: Dependencies are injected, not created
- **Repository Pattern**: Abstract data sources behind consistent interfaces
- **Use Case Pattern**: Encapsulate business logic in reusable components
- **Coordinator Pattern**: Handle navigation flow independent of views

## Core Components

### Data Persistence
- SwiftData for structured data (iOS 17+)
- FileManager for storing large blobs like generated images
- Keychain for sensitive data like API keys
- UserDefaults for user preferences

### Networking
- Protocol-based API client
- Support for both standard requests and streaming responses
- Middleware for retry, authentication, and logging

### Features
- Unified chat interface for multiple AI providers
- Custom AI bots with specialized personalities
- Prompt library for saving and reusing effective prompts
- Personal memory system for contextual information retrieval
- Image generation capabilities
- Comprehensive organization system

## Code Style Guidelines

- Use 4 spaces for indentation
- Line length limit of 120 characters
- Follow Swift naming conventions
- Method body length should not exceed 60 lines (warning) or 100 lines (error)
- Avoid force unwrapping (`!`) and prefer safe unwrapping
- Use SwiftLint and SwiftFormat for consistent code style

## Testing Approach

- Unit tests for all business logic
- Integration tests for component interactions
- UI tests for critical user flows
- Use dependency injection to facilitate testing
- Create mock implementations for testing
- Test for edge cases and error conditions

## Subscription System

The app implements a subscription model using StoreKit 2:
- Free tier with limited features
- Premium subscription ($4.99/month or $49.99/year)
- Lifetime premium ($99.99 one-time purchase)

## Performance Considerations

- Optimize memory usage, especially during streaming
- Minimize CPU usage and battery impact
- Ensure fast app startup times
- Use efficient networking and response handling