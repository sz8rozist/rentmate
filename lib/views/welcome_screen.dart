import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../models/snackbar_message.dart';
import '../models/user_role.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/custom_scaffold.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final extra = GoRouterState.of(context).extra;
    if (extra != null && extra is SnackBarMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        extra.isError
            ? CustomSnackBar.error(context,extra.message)
            : CustomSnackBar.success(context,extra.message);
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _tryBiometricAuthLoop();
  }

  Future<void> _tryBiometricAuthLoop() async {
    if (!await auth.canCheckBiometrics) {
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
          if(user.role == UserRole.landlord){
            context.goNamed(AppRoute.flatSelect.name);
          }else{
            //Albérlő mehet a home ra és itt kéne neki be állítani a selectedFlat et szerintem.
            context.goNamed(AppRoute.home.name);
          }
          return;
        } else {
          attempts++;
        }
      } catch (e) {
        if (!mounted) return;
        CustomSnackBar.error(context,"Túl sok sikertelen próbálkozás!");
        break;
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16.0),
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
                          text: '\nEnter personal details to your employee account',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildButton(
              text: 'Bejelentkezés',
              onPressed: () => context.goNamed(AppRoute.signin.name),
            ),
            const SizedBox(height: 16),
            _buildButton(
              text: 'Regisztráció',
              onPressed: () => context.goNamed(AppRoute.signup.name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
        ),
      ),
    );
  }
}
