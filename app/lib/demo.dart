import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const bool demoMode = bool.fromEnvironment('DEMO_MODE');

enum DemoPersona { citizen, staff, district }

final demoPersona = ValueNotifier(DemoPersona.citizen);

Future<String> ensureDemoWorkspace(SupabaseClient client) async {
  if (client.auth.currentUser == null) await client.auth.signInAnonymously();
  if (client.auth.currentUser?.isAnonymous != true)
    throw const AuthException('Use a separate anonymous demo session.');
  return await client.rpc('start_demo') as String;
}

Future<String> resetDemoWorkspace(SupabaseClient client) async =>
    await client.rpc('reset_demo') as String;
