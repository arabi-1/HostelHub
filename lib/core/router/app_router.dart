import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/env.dart';
import '../strings.dart';
import '../widgets/missing_config_screen.dart';
import '../../data/models/resident.dart';
import '../../data/models/room.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/residents/resident_detail_screen.dart';
import '../../features/residents/resident_form_screen.dart';
import '../../features/residents/residents_screen.dart';
import '../../features/rooms/properties_screen.dart';
import '../../features/rooms/room_form_screen.dart';
import '../../features/rooms/rooms_screen.dart';
import '../../features/rent/rent_screen.dart';
import '../../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepoProvider);
  final refreshNotifier = GoRouterRefreshStream(authRepo.authStateChanges);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      if (!Env.isConfigured) {
        if (state.uri.path != '/missing-config') {
          return '/missing-config';
        }
        return null;
      }
      if (state.uri.path == '/missing-config') {
        return '/';
      }

      final currentUser = authRepo.currentUser;
      final isAuthRoute = state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/reset-password';

      // Unauthenticated users must stay on auth routes
      if (currentUser == null) {
        return isAuthRoute ? null : '/login';
      }

      // Authenticated users on auth routes are redirected to home
      if (isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/missing-config',
        builder: (context, state) => const MissingConfigScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/properties',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: '/rooms/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final propId = state.uri.queryParameters['propertyId'];
          return RoomFormScreen(initialPropertyId: propId);
        },
      ),
      GoRoute(
        path: '/rooms/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final room = state.extra as Room?;
          return RoomFormScreen(room: room);
        },
      ),
      GoRoute(
        path: '/residents/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ResidentFormScreen(),
      ),
      GoRoute(
        path: '/residents/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ResidentDetailScreen(residentId: id);
        },
      ),
      GoRoute(
        path: '/residents/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final resident = state.extra as Resident?;
          return ResidentFormScreen(resident: resident);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: AppStrings.navDashboard,
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: AppStrings.navResidents,
                ),
                NavigationDestination(
                  icon: Icon(Icons.hotel_outlined),
                  selectedIcon: Icon(Icons.hotel_rounded),
                  label: AppStrings.navRooms,
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: AppStrings.navRent,
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: AppStrings.navSettings,
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/residents',
                builder: (context, state) => const ResidentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (context, state) => const RoomsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rent',
                builder: (context, state) => const RentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
