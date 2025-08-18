class AiResponse {
  final String text; // transcript / LLM reply
  final String audioUrl; // relative or absolute URL to mp3
  const AiResponse({required this.text, required this.audioUrl});
}
