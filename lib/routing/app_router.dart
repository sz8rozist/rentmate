import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // kell, ha Riverpodot használsz
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/user_role.dart';
import 'package:rentmate/routing/router_notifier.dart';
import 'package:rentmate/viewmodels/apartman_provider.dart';
import 'package:rentmate/views/flat_details_view.dart';
import 'package:rentmate/views/flat_form_view.dart';
import 'package:rentmate/views/landlord_home_view.dart';
import 'package:rentmate/views/profil_view.dart';
import 'package:rentmate/views/signin_view.dart';
import 'package:rentmate/views/signup_view.dart';
import 'package:rentmate/views/tenant_flat_screen.dart';
import 'package:rentmate/views/welcome_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/chat_message_view.dart';
import '../views/splash_screen.dart';
import '../widgets/shell_scaffold.dart';

// Enum az útvonalakhoz
enum AppRoute {
  welcome,
  signin,
  signup,
  home,
  profil,
  flat,
  myRental,
  createFlat,
  flatDetail,
  chatMessage,
  invoices,
  newInvoice,
  invoiceDetaul,
  editInvoice,
  notFound;

  String title() {
    switch (this) {
      case AppRoute.home:
        return 'Továbbiak';
      case AppRoute.chatMessage:
        return 'Chat';
      case AppRoute.flat:
      case AppRoute.myRental:
        return 'Lakásom';
      case AppRoute.profil:
        return 'Profil';
      case AppRoute.createFlat:
        return "Lakás hozzáadása";
      case AppRoute.flatDetail:
        return "Lakás adatai";
      case AppRoute.invoices:
        return "Számlák";
      case AppRoute.newInvoice:
        return "Számla hozzáadása";
      case AppRoute.invoiceDetaul:
        return "Számla részletei";
      case AppRoute.editInvoice:
        return "Számla szerkesztése";
      case AppRoute.notFound:
        return "Ismeretlen oldal";
      case AppRoute.welcome:
      case AppRoute.signin:
      case AppRoute.signup:
        return "";
    }
  }
}

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
          return ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoute.home.name,
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authViewModelProvider);

                  return authState.when(
                    data: (auth) {
                      final payload = auth.payload;
                      print("router token payload: $payload");

                      if (payload?.role == UserRole.tenant) {
                        return const Text("Home");
                      } else {
                        return const LandlordHomeView();
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text("Error: $err")),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/flat',
            name: AppRoute.flat.name,
            builder: (context, state) => FlatDetailsView(),
          ),
          GoRoute(
            path: '/myRental',
            name: AppRoute.myRental.name,
            builder: (context, state) => TenantFlatScreen(),
          ),
          GoRoute(
            path: '/profil',
            name: AppRoute.profil.name,
            builder: (context, state) => ProfilView(),
          ),
          GoRoute(
            path: '/chatMessage',
            name: AppRoute.chatMessage.name,
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final apartmanProvder = ref.watch(apartmentProvider);
                  if (apartmanProvder.active == null) {
                    return const Scaffold(
                      body: Center(child: Text('Nincs kiválasztott lakás.')),
                    );
                  }
                  return ChatMessageView(flatId: apartmanProvder.active?.id as int);
                },
              );
            },
          ),
        ],
      ),
    ],
  );
});
