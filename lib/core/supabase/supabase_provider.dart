import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

part 'supabase_provider.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => SupabaseInit.client;
