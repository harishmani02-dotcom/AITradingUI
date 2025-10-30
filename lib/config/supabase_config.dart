import 'package:flutter_dotenv/flutter_dotenv.dart';
 
class SupabaseConfig {
  static String get url => dotenv.env['https://bqeypsiegeoxzrlxrpee.supabase.co'] ?? '';
  static String get anonKey => dotenv.env['eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZXlwc2llZ2VveHpybHhycGVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMTg5MTIsImV4cCI6MjA3Njc5NDkxMn0.rgSkURPwqcgjGVUlqlTdvUoQPM7p5MbbAzWkdMjsF4Q'] ?? '';
}
