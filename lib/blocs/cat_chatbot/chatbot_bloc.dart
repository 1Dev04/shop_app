import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'chatbot_event.dart';
import 'chatbot_state.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  static const _baseUrl = 'https://cat-chatbot-backend.up.railway.app';

  ChatbotBloc() : super(ChatbotInitial()) {
    on<ChatbotMessageSent>(_onMessageSent);
    on<ChatbotReset>((_, emit) => emit(ChatbotInitial()));
  }

  Future<void> _onMessageSent(
    ChatbotMessageSent event,
    Emitter<ChatbotState> emit,
  ) async {
    emit(ChatbotLoading());
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': event.message}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        emit(ChatbotSuccess(
          reply: data['reply'] ?? '',
          action: data['action'] ?? '',
        ));
      } else {
        emit(ChatbotFailure('เซิร์ฟเวอร์มีปัญหา'));
      }
    } catch (e) {
      emit(ChatbotFailure('เชื่อมต่อไม่ได้'));
    }
  }
}