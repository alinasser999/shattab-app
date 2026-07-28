import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_project.dart';

part 'portfolio_providers.g.dart';

@riverpod
Future<List<PortfolioProject>> portfolioForContractor(
  Ref ref,
  String contractorId,
) => ref.watch(portfolioRepositoryProvider).fetchForContractor(contractorId);

@riverpod
Future<PortfolioProject?> portfolioProject(Ref ref, String projectId) =>
    ref.watch(portfolioRepositoryProvider).fetchById(projectId);
