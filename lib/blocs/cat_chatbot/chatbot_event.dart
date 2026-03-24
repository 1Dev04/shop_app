abstract class ChatbotEvent {}

class ChatbotMessageSent extends ChatbotEvent {
  final String message;
  ChatbotMessageSent(this.message);
}

class ChatbotReset extends ChatbotEvent {}