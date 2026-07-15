import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = 'https://smqoknnftgjyhrnzugar.supabase.co';
  static const anonKey = 'sb_publishable_IFaGjUFwiBeBH_M-GYrSZA_Fywg9Tk9';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
