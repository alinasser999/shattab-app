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

  Future<PortfolioProject> update({
    required String projectId,
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
        .update({
          'title': title,
          'description': description,
          'cover_photo_url': coverPhotoUrl,
          'photo_urls': photoUrls,
          'category': category,
          'location': location,
          'year_completed': yearCompleted,
        })
        .eq('id', projectId)
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
    // Fetch project to clean up storage files before deleting the DB row.
    final project = await fetchById(projectId);
    if (project != null) {
      await _removeStoragePhotos(project.photoUrls);
    }
    await _client.from('portfolio_projects').delete().eq('id', projectId);
  }

  /// Best-effort cleanup of storage files for removed/updated photos.
  Future<void> _removeStoragePhotos(List<String> urls) async {
    final storage = _client.storage.from('portfolio-photos');
    for (final url in urls) {
      final path = _storagePathFromUrl(url);
      if (path != null) {
        try {
          await storage.remove([path]);
        } catch (_) {
          // Non-critical: storage file removal is best-effort.
        }
      }
    }
  }

  /// Extract the storage object path from a public URL.
  /// URL format: {baseUrl}/storage/v1/object/public/portfolio-photos/{path}
  static String? _storagePathFromUrl(String url) {
    const prefix = '/portfolio-photos/';
    final idx = url.indexOf(prefix);
    if (idx == -1) return null;
    final path = url.substring(idx + prefix.length);
    return path.isEmpty ? null : path;
  }
}

@Riverpod(keepAlive: true)
PortfolioRepository portfolioRepository(Ref ref) =>
    PortfolioRepository(ref.watch(supabaseClientProvider));
