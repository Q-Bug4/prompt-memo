import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/prompt_list_screen.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/prompt_detail_screen.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/create_prompt_screen.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/collection_detail_screen.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/create_edit_collection_screen.dart';
import 'package:prompt_memo/features/search/presentation/screens/search_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/settings_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/about_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/update_screen.dart';
import 'package:prompt_memo/features/settings/presentation/screens/data_management_screen.dart';

/// App routes
enum AppRoute {
  home,
  promptDetail,
  createPrompt,
  editPrompt,
  search,
  collectionDetail,
  createCollection,
  editCollection,
  settings,
  about,
  update,
  dataManagement,
}

/// App router configuration
final routerConfig = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: AppRoute.home.name,
      builder: (context, state) => const PromptListScreen(),
    ),
    GoRoute(
      path: '/search',
      name: AppRoute.search.name,
      builder: (context, state) {
        final query = state.uri.queryParameters['q'];
        return SearchScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/prompt/new',
      name: AppRoute.createPrompt.name,
      builder: (context, state) {
        final collectionId = state.uri.queryParameters['collectionId'];
        return CreatePromptScreen(initialCollectionId: collectionId);
      },
    ),
    GoRoute(
      path: '/prompt/:id/edit',
      name: AppRoute.editPrompt.name,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreatePromptScreen(key: ObjectKey(id), promptId: id);
      },
    ),
    GoRoute(
      path: '/prompt/:id',
      name: AppRoute.promptDetail.name,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        // Make sure 'new' is not treated as an ID
        if (id == 'new') return const CreatePromptScreen();
        return PromptDetailScreen(key: ObjectKey(id), promptId: id);
      },
    ),
    GoRoute(
      path: '/collection/new',
      name: AppRoute.createCollection.name,
      builder: (context, state) => const CreateEditCollectionScreen(),
    ),
    GoRoute(
      path: '/collection/:id/edit',
      name: AppRoute.editCollection.name,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreateEditCollectionScreen(key: ObjectKey(id), collectionId: id);
      },
    ),
    GoRoute(
      path: '/collection/:id',
      name: AppRoute.collectionDetail.name,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CollectionDetailScreen(key: ObjectKey(id), collectionId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      name: AppRoute.settings.name,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      name: AppRoute.about.name,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/settings/update',
      name: AppRoute.update.name,
      builder: (context, state) => const UpdateScreen(),
    ),
    GoRoute(
      path: '/settings/data',
      name: AppRoute.dataManagement.name,
      builder: (context, state) => const DataManagementScreen(),
    ),
  ],
  errorBuilder:
      (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
