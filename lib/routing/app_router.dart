import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/views/signin_view.dart';
import 'package:rentmate/views/signup_view.dart';
import 'package:rentmate/views/welcome_screen.dart';

import '../views/splash_screen.dart';
import '../widgets/shell_scaffold.dart';

enum AppRoute{
  welcome,
  signin,
  signup,
  home,
  profile,
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      name: AppRoute.welcome.name,
      pageBuilder: (context, state) => MaterialPage(
        child: WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/signin',
      name: AppRoute.signin.name,
      pageBuilder: (context, state) => MaterialPage(
        //fullscreenDialog: true, -> akkor kell ha nem akarok bal fent nyilat amivel vissza lehet navigálni
        child: SignInScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      name: AppRoute.signup.name,
      pageBuilder: (context, state) => MaterialPage(
        child: SignUpScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: AppRoute.home.name,
          builder: (context, state) => const Center(child: Text('Home Page')),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const Center(child: Text('Search Page')),
        ),
      ],
    ),
  ],
);