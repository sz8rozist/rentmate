import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // kell, ha Riverpodot használsz
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/user_role.dart';
import 'package:rentmate/routing/router_notifier.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/views/add_invoice_view.dart';
import 'package:rentmate/views/chat_message_view.dart';
import 'package:rentmate/views/document_list_page.dart';
import 'package:rentmate/views/document_upload_page.dart';
import 'package:rentmate/views/flat_details_view.dart';
import 'package:rentmate/views/flat_form_view.dart';
import 'package:rentmate/views/flat_selector_view.dart';
import 'package:rentmate/views/invoice_details_view.dart';
import 'package:rentmate/views/landlord_invoices_view.dart';
import 'package:rentmate/views/profil_view.dart';
import 'package:rentmate/views/signin_view.dart';
import 'package:rentmate/views/signup_view.dart';
import 'package:rentmate/views/tenant_flat_screen.dart';
import 'package:rentmate/views/tenant_invoices_view.dart';
import 'package:rentmate/views/welcome_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/invoice_edit_view.dart';
import '../views/lease_contract_form_page.dart';
import '../views/splash_screen.dart';
import '../widgets/PDFViewPage.dart';
import '../widgets/shell_scaffold.dart';

// Enum az útvonalakhoz
enum AppRoute {
  welcome,
  signin,
  signup,
  home,
  profile,
  lakasom,
  alberleteim,
  createFlat,
  flatDetail,
  chatMessage,
  invoices,
  newInvoice,
  invoiceDetaul,
  editInvoice,
  pdfview,
  documents,
  uploadDocument,
  createBerletiSzerzodes,
  flatSelect,
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
        path: '/view-pdf',
        name: AppRoute.pdfview.name,
        builder: (context, state) {
          final filePath = state.uri.queryParameters['filePath'];
          if (filePath == null) {
            return const Scaffold(body: Center(child: Text("Hiányzó fájl")));
          }
          return PDFViewPage(filePath: filePath);
        },
      ),
      GoRoute(
        path: '/flats/:flatId/documents',
        name: AppRoute.documents.name,
        builder: (context, state) {
          final flatId = state.pathParameters['flatId']!;
          return DocumentListPage(flatId: flatId);
        },
      ),
      GoRoute(
        path: '/flats/documents/add',
        name: AppRoute.uploadDocument.name,
        builder: (context, state) {
          return DocumentUploadPage();
        },
      ),
      GoRoute(
        path: '/flats/lease-contract',
        name: AppRoute.createBerletiSzerzodes.name,
        builder: (context, state) {
          return LeaseContractFormPage();
        },
      ),
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
        path: '/flatSelect',
        name: AppRoute.flatSelect.name,
        pageBuilder:
            (context, state) => MaterialPage(child: ApartmentSelectorScreen()),
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
      GoRoute(
        path: '/createInvoice',
        name: AppRoute.newInvoice.name,
        builder: (context, state) {
          return AddInvoiceScreen();
        },
      ),
      GoRoute(
        path: '/invoiceDetail/:invoiceId',
        name: AppRoute.invoiceDetaul.name,
        builder: (context, state) {
          final invoiceId = state.pathParameters['invoiceId'];
          return InvoiceDetailsScreen(invoiceId: invoiceId as String);
        },
      ),
      GoRoute(
        path: '/editInvoice/:invoiceId',
        name: AppRoute.editInvoice.name,
        builder: (context, state) {
          final invoiceId = state.pathParameters['invoiceId'];
          return InvoiceEditView(invoiceId: invoiceId as String);
        },
      ),
      GoRoute(
        path: '/invoices',
        name: AppRoute.invoices.name,
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final asyncUser = ref.watch(currentUserProvider);

              return asyncUser.when(
                data: (user) {
                  if (user == null) {
                    return const Scaffold(
                      body: Center(
                        child: Text('Nincs bejelentkezett felhasználó'),
                      ),
                    );
                  } else {
                    if (user.role?.value == UserRole.tenant.value) {
                      return TenantInvoicesView(tenantUserId: user.id);
                    } else {
                      return LandlordInvoicesScreen(landlordUserId: user.id);
                    }
                  }
                },
                loading:
                    () => const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (err, stack) =>
                        Scaffold(body: Center(child: Text('Hiba: $err'))),
              );
            },
          );
        },
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
            path: '/flat',
            name: AppRoute.lakasom.name,
            builder: (context, state) => FlatDetailsView(),
          ),
          GoRoute(
            path: '/my-rental',
            name: AppRoute.alberleteim.name,
            builder: (context, state) => TenantFlatScreen(),
          ),
          GoRoute(
            path: '/profil',
            name: AppRoute.profile.name,
            builder: (context, state) => ProfilView(),
          ),
          GoRoute(
            path: '/chatMessage',
            name: AppRoute.chatMessage.name,
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final selectedFlat = ref.watch(selectedFlatProvider);
                  if (selectedFlat == null) {
                    return const Scaffold(
                      body: Center(child: Text('Nincs kiválasztott lakás.')),
                    );
                  }
                  return ChatMessageView(flatId: selectedFlat.id as String);
                },
              );
            },
          ),
        ],
      ),
    ],
  );
});
