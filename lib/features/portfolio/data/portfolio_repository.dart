import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/portfolio_project.dart';

part 'portfolio_repository.g.dart';

class PortfolioRepository {
  PortfolioRepository(this._client);
  final SupabaseClient _client;

  Future<List<PortfolioProject>> fetchForContractor(String contractorId) async {
    final rows = await _client
        .from('portfolio_projects')
        .select()
        .eq('contractor_id', contractorId)
        .order('position', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(PortfolioProject.fromJson).toList();
  }

  Future<PortfolioProject?> fetchById(String projectId) async {
    final row = await _client
        .from('portfolio_projects')
        .select()
        .eq('id', projectId)
        .maybeSingle();
    if (row == null) return null;
    return PortfolioProject.fromJson(row);
  }

  Future<PortfolioProject> create({
    required String contractorId,
    required String title,
    String? description,
    required String coverPhotoUrl,
    List<String> photoUrls = const [],
    String? category,
    String? location,
    int? yearCompleted,
  }) async {
    final row = await _client
        .from('portfolio_projects')
        .insert({
          'contractor_id': contractorId,
          'title': title,
          'description': description,
          'cover_photo_url': coverPhotoUrl,
          'photo_urls': photoUrls,
          'category': category,
          'location': location,
          'year_completed': yearCompleted,
        })
        .select()
        .single();
    return PortfolioProject.fromJson(row);
  }

  Future<String> uploadPhoto({
    required String contractorId,
    required String draftId,
    required int seq,
    File? file,
    Uint8List? bytes,
  }) async {
    final path = '$contractorId/$draftId/$seq.jpg';
    final storage = _client.storage.from('portfolio-photos');
    if (file != null) {
      await storage.upload(path, file,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'));
    } else if (bytes != null) {
      await storage.uploadBinary(path, bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'));
    } else {
      throw ArgumentError('uploadPhoto needs file or bytes');
    }
    return storage.getPublicUrl(path);
  }

  Future<void> delete(String projectId) async {
    await _client.from('portfolio_projects').delete().eq('id', projectId);
  }
}

@Riverpod(keepAlive: true)
PortfolioRepository portfolioRepository(Ref ref) =>
    PortfolioRepository(ref.watch(supabaseClientProvider));
