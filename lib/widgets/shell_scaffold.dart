import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';
import 'package:sidebarx/sidebarx.dart';
import '../models/user_role.dart';
import '../viewmodels/auth_viewmodel.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final List<Widget>? actions;

  const ShellScaffold({super.key, required this.child, this.actions});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  // SidebarXController a navigáció kezeléséhez
  late final SidebarXController _sidebarXController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    // Kezdetben a "home" oldalra mutató index legyen kiválasztva.
    // A pontos indexet dinamikusan kell beállítani, de itt alapértelmezetten 0.
    _sidebarXController = SidebarXController(selectedIndex: 0, extended: true);
  }

  @override
  void dispose() {
    _sidebarXController.dispose();
    super.dispose();
  }

  String getTitleFromState(BuildContext context, UserRole role) {
    final location = GoRouter.of(context).state.matchedLocation;
    final routeNameString = location.split('/').where((e) => e.isNotEmpty).firstOrNull ?? 'notFound';
print(location);
print(routeNameString);
    final route = AppRoute.values.firstWhere(
          (r) => r.name == routeNameString,
      orElse: () => AppRoute.notFound,
    );
    print(route);
    return route.title(role);
  }

  // SidebarX téma beállítások
  SidebarXTheme _getSidebarXTheme(BuildContext context) {
    return SidebarXTheme(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Kártya háttérszín
        borderRadius: BorderRadius.circular(20),
      ),
      hoverColor: Theme.of(context).hoverColor,
      itemMargin: const EdgeInsets.all(5),
      itemPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      selectedItemDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.2), // Kiválasztott elem háttérszíne
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        size: 22,
      ),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontSize: 16,
      ),
      selectedTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // SidebarX kiterjesztett téma beállítások
  SidebarXTheme _getSidebarXExtendedTheme(BuildContext context) {
    return SidebarXTheme(
      width: 300,
      // Kiterjesztett szélesség
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      itemPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemTextPadding: const EdgeInsets.only(left: 12),
      // Itt növeljük a bal oldali paddinget, hogy legyen hely az ikon és a szöveg közt
      selectedItemTextPadding: const EdgeInsets.only(left: 12),
      selectedItemDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        size: 22,
      ),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontSize: 17,
      ),
      selectedTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<SidebarXItem> _getSidebarXItems(UserRole role, String flatId) {
    final List<SidebarXItem> items = [
      SidebarXItem(
        icon: FontAwesome.house,
        label: 'Kezdőlap',
        onTap: () {
          context.goNamed(AppRoute.home.name);
          // Használd a GlobalKey-t a drawer bezárásához
          if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
            _scaffoldKey.currentState!.closeDrawer();
          }
        },
      ),
      SidebarXItem(
        icon: FontAwesome.message,
        label: 'Chat',
        onTap: () {
          context.goNamed(AppRoute.chatMessage.name);
          if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
            _scaffoldKey.currentState!.closeDrawer();
          }
        },
      ),
    ];

    if (role == UserRole.landlord) {
      items.addAll([
        SidebarXItem(
          icon: FontAwesome.house_user,
          label: 'Lakásom',
          onTap: () {
            context.goNamed(AppRoute.flat.name);
            if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
              _scaffoldKey.currentState!.closeDrawer();
            }
          },
        ),
      ]);
    } else {
      // tenant vagy más szerep
      items.addAll([
        SidebarXItem(
          icon: Icons.house,
          label: 'Albérletem',
          onTap: () {
            context.goNamed(AppRoute.myRental.name);
            if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
              _scaffoldKey.currentState!.closeDrawer();
            }
          },
        ),
        SidebarXItem(
          icon: Icons.payments,
          label: 'Számlák',
          onTap: () {
            context.goNamed(AppRoute.invoices.name);
            if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
              _scaffoldKey.currentState!.closeDrawer();
            }
          },
        ),
        SidebarXItem(
          icon: Icons.folder,
          label: 'Dokumentumok',
          onTap: () {
            context.goNamed(
              AppRoute.documents.name,
              pathParameters: {"flatId": flatId},
            );
            if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
              _scaffoldKey.currentState!.closeDrawer();
            }
          },
        ),
      ]);
    }
    items.addAll([
      SidebarXItem(
        icon: Icons.account_box,
        label: 'Profil',
        onTap: () {
          context.goNamed(
            AppRoute.profil.name,
          );
          if (_scaffoldKey.currentState != null && _scaffoldKey.currentState!.isDrawerOpen) {
            _scaffoldKey.currentState!.closeDrawer();
          }
        },
      ),
    ]);

    return items;
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;
    final selectedFlat = ref.watch(selectedFlatProvider);
    if(selectedFlat == null){
      return const SizedBox();
    }
    final flatId = selectedFlat.id;
    final isSmallScreen =
        MediaQuery.of(context).size.width <
        768; // Definiáljuk a reszponzivitáshoz

    return Scaffold(
      key: _scaffoldKey,
      appBar:
          isSmallScreen
              ? PreferredSize(
            preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
            child: Container(
                  width: double.infinity,
                  height:  80 + MediaQuery.of(context).padding.top,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/header-image.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color:
                        ref.watch(themeModeProvider) == ThemeMode.dark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black.withOpacity(0.2),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (context) {
                            return IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            );
                          },
                        ),
                        Expanded(
                          child: Text(
                            getTitleFromState(
                              context,
                              payload?.role as UserRole,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child:
                              widget.actions != null
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: widget.actions!,
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : null,
      // Nagy képernyőn nincs AppBar
      drawer:
          isSmallScreen // SidebarX mint Drawer kis képernyőn
              ? SidebarX(
                controller: _sidebarXController,
                theme: _getSidebarXTheme(context),
                extendedTheme: _getSidebarXExtendedTheme(context),
                headerBuilder: (context, extended) {
                  return SizedBox(
                    height: 250,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  );
                },
                footerDivider: const Divider(),
                items: _getSidebarXItems(payload?.role as UserRole, flatId.toString()),
              )
              : null, // Nagy képernyőn nincs Drawer

      body: Row(
        children: [
          // SidebarX mint állandó oldalsáv nagy képernyőn
          if (!isSmallScreen)
            SidebarX(
              controller: _sidebarXController,
              theme: _getSidebarXTheme(context),
              extendedTheme: _getSidebarXExtendedTheme(context),
              headerBuilder: (context, extended) {
                return SizedBox(
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      // Győződj meg róla, hogy ez az asset létezik
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
              footerDivider: const Divider(),
              items: _getSidebarXItems(payload?.role as UserRole, flatId.toString()),
            ),
          Expanded(
            child: Column(
              children: [
                // Felső fejléc (csak akkor, ha nem mobil nézet és nincs AppBar)
                if (!isSmallScreen && widget.actions != null)
                  Container(
                    height: 80 + MediaQuery.of(context).padding.top,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/header-image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      color:
                          ref.watch(themeModeProvider) == ThemeMode.dark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.black.withOpacity(0.2),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        left: 16,
                        right: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              getTitleFromState(
                                context,
                                payload?.role as UserRole,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.actions!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.background.withOpacity(0.3),
                    child: widget.child, // A router által betöltött tartalom
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
