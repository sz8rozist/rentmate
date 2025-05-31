import 'package:flutter/material.dart';
import 'package:rentmate/routing/app_router.dart';
import '../theme/theme.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/welcome_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
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
                        text: '\nEnter personal details to your employee account',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
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
