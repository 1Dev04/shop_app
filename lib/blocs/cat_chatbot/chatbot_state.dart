abstract class ChatbotState {}

class ChatbotInitial extends ChatbotState {}
class ChatbotLoading extends ChatbotState {}

class ChatbotSuccess extends ChatbotState {
  final String reply;
  final String action;
  ChatbotSuccess({required this.reply, this.action = ''});
}

class ChatbotFailure extends ChatbotState {
  final String error;
  ChatbotFailure(this.error);
}