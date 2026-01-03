import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/prompt_list_screen.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/prompt_detail_screen.dart';
import 'package:prompt_memo/features/prompt-management/presentation/screens/create_prompt_screen.dart';
import 'package:prompt_memo/features/search/presentation/screens/search_screen.dart';

/// App routes
enum AppRoute {
  home,
  promptDetail,
  createPrompt,
  editPrompt,
  search,
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
      builder: (context, state) => const CreatePromptScreen(),
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
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
