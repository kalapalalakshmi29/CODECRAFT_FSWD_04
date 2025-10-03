# Real-time Chat Application

A Flutter-based real-time chat application using WebSocket technology for instant messaging.

## Features

- **User Authentication**: Simple username-based login system
- **Real-time Messaging**: Instant message delivery using WebSockets
- **User Presence**: Online user indicators
- **Chat Rooms**: Support for group conversations
- **Message History**: Local message storage during session
- **Responsive UI**: Clean and intuitive chat interface

## Setup Instructions

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the Application**:
   ```bash
   flutter run
   ```

## Usage

1. **Login**: Enter a username to join the chat
2. **Send Messages**: Type and send messages in real-time
3. **View Online Users**: Tap the users icon to see who's online
4. **Auto-responses**: The app includes a ChatBot that responds to messages

## Architecture

- **Models**: User, Message, ChatRoom data structures
- **Services**: WebSocket communication and authentication
- **Screens**: Login and Chat UI components
- **Real-time Communication**: WebSocket-based messaging

## Dependencies

- `web_socket_channel`: WebSocket connectivity
- `uuid`: Unique ID generation
- `shared_preferences`: Local data persistence
- `intl`: Internationalization support

## Project Structure

```
lib/
├── models/
│   ├── user.dart
│   ├── message.dart
│   └── chat_room.dart
├── services/
│   ├── auth_service.dart
│   ├── websocket_service.dart
│   └── chat_history_service.dart
├── screens/
│   ├── login_screen.dart
│   ├── chat_screen.dart
│   └── user_list_screen.dart
├── widgets/
│   ├── message_bubble.dart
│   ├── chat_input_field.dart
│   └── typing_indicator.dart
└── main.dart
```

## Getting Started

This project is a starting point for a Flutter application with real-time chat capabilities.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.