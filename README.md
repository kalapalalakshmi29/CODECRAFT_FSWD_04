# CODECRAFT_FSWD_04

## Real-time Chat Application - Purple Edition

A Flutter-based real-time chat application using WebSocket technology for instant messaging with a beautiful purple/pink color theme.

## Features

- **User Authentication**: Simple username-based login system
- **Real-time Messaging**: Instant message delivery using WebSockets
- **User Presence**: Online user indicators
- **Chat Rooms**: Support for group conversations
- **Message History**: Local message storage during session
- **Responsive UI**: Clean and intuitive chat interface with purple/pink theme
- **Dark Mode**: Toggle between light and dark themes
- **File Sharing**: Support for images, videos, and documents
- **Emoji Support**: Built-in emoji picker
- **Typing Indicators**: See when others are typing

## Color Scheme

This version features a beautiful purple and pink color palette:
- Primary colors: Deep Purple (#4A148C) and Pink (#880E4F)
- Accent colors: Purple shades for buttons and highlights
- Message bubbles: Purple for sent messages, grey for received
- Gradients: Purple to pink transitions in backgrounds

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
4. **Create Rooms**: Start new chat rooms for group conversations
5. **Share Files**: Attach images, videos, and documents
6. **Use Emojis**: Express yourself with the built-in emoji picker

## Architecture

- **Models**: User, Message, ChatRoom data structures
- **Services**: WebSocket communication, authentication, and notifications
- **Screens**: Login, Main Chat, and various UI components
- **Widgets**: Reusable UI components for messages, inputs, and indicators
- **Real-time Communication**: WebSocket-based messaging with typing indicators

## Dependencies

- `web_socket_channel`: WebSocket connectivity
- `uuid`: Unique ID generation
- `shared_preferences`: Local data persistence
- `intl`: Internationalization support

## Customization

The app uses a purple/pink color scheme that can be easily customized by modifying the color constants in:
- `lib/main.dart` - Main theme colors
- `lib/screens/login_screen.dart` - Login screen colors
- `lib/screens/advanced_main_screen.dart` - Chat interface colors

## Version

This is the Purple Edition (task_04) - a customized version with enhanced UI and purple/pink color theme.