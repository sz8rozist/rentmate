import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // kell, ha Riverpodot használsz
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/router_notifier.dart';
import 'package:rentmate/viewmodels/auth_viewmodel.dart';
import 'package:rentmate/views/flat_form_view.dart';
import 'package:rentmate/views/lakasaim_view.dart';
import 'package:rentmate/views/profil_view.dart';
import 'package:rentmate/views/signin_view.dart';
import 'package:rentmate/views/signup_view.dart';
import 'package:rentmate/views/welcome_screen.dart';

import '../views/splash_screen.dart';
import '../widgets/shell_scaffold.dart';

// Enum az útvonalakhoz
enum AppRoute { welcome, signin, signup, home, profile, lakasaim, alberleteim, createFlat }

// Riverpod provider a RouterNotifierhoz
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// GoRouter provider, ami a redirecttel kezeli az auth állapotot
final goRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final asyncUser = ref.read(currentUserProvider);
      final user = asyncUser.asData?.value;
      final loggedIn = user != null;
      final goingToAuth =
          state.matchedLocation == '/signin' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/welcome';

      if (!loggedIn && !goingToAuth) {
        return '/welcome';
      }

      if (loggedIn && goingToAuth) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => SplashScreen()),
      GoRoute(
        path: '/welcome',
        name: AppRoute.welcome.name,
        pageBuilder: (context, state) => MaterialPage(child: WelcomeScreen()),
      ),
      GoRoute(
        path: '/signin',
        name: AppRoute.signin.name,
        pageBuilder: (context, state) => MaterialPage(child: SignInScreen()),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signup.name,
        pageBuilder: (context, state) => MaterialPage(child: SignUpScreen()),
      ),
      GoRoute(
        path: '/createFlat',
        name: AppRoute.createFlat.name,
        builder: (context, state) => FlatFormView(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          // Például a flats (lakasaim) oldalon gomb kell:
          List<Widget>? actions;
          if (state.matchedLocation == '/flats') {
            actions = [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Új lakás hozzáadása',
                onPressed: () {
                  context.pushNamed(AppRoute.createFlat.name);
                },
              ),
            ];
          }
          return ShellScaffold(actions: actions, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoute.home.name,
            builder: (context, state) => const Center(child: Text('Home Page')),
          ),
          GoRoute(
            path: '/flats',
            name: AppRoute.lakasaim.name,
            builder: (context, state) => LakasaimView(),
          ),
          GoRoute(
            path: '/my-rental',
            name: AppRoute.alberleteim.name,
            builder:
                (context, state) =>
                    const Center(child: Text('Albérleteim Page')),
          ),
          GoRoute(
            path: '/profil',
            name: AppRoute.profile.name,
            builder: (context, state) => ProfilView(),
          ),
        ],
      ),
    ],
  );
});
