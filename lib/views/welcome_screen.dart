import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../theme/theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/welcome_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  @override
  void initState() {
    super.initState();
    _tryBiometricAuthLoop();
  }

  Future<void> _tryBiometricAuthLoop() async {

    if(!await auth.canCheckBiometrics){
      return;
    }

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts && mounted) {
      try {
        final authenticated = await auth.authenticate(
          localizedReason: 'Kérlek azonosítsd magad',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (authenticated && mounted) {
          context.goNamed(AppRoute.home.name);
          return;
        } else {
          attempts++;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.error("TÚl sok sikertelen próbálkozás!")
        );
        break; // hibánál kilépünk a loopból
      }
    }

    if (attempts >= maxAttempts && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Túl sok sikertelen próbálkozás')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 20.0,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8.0,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Üdv Újra!\n',
                        style: TextStyle(
                          fontSize: 45.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text:
                            '\nEnter personal details to your employee account',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: WelcomeButton(
                  buttonText: 'Bejelentkezés',
                  routeName: AppRoute.signin.name,
                  color: Colors.transparent,
                  textColor: Colors.white,
                ),
              ),
              Expanded(
                child: WelcomeButton(
                  buttonText: 'Regisztráció',
                  routeName: AppRoute.signup.name,
                  color: Colors.white,
                  textColor: lightColorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
