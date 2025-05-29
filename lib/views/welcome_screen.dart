import 'package:flutter/material.dart';
import 'package:rentmate/views/signin_view.dart';
import 'package:rentmate/views/signup_view.dart';
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
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 40.0,
              ),
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Üdv Újra!\n',
                        style: TextStyle(
                          fontSize: 45.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text:
                            '\nEnter personal details to your employee account',
                        style: TextStyle(
                          fontSize: 20,
                          // height: 0,
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
                  onTap: const SignInScreen(),
                  color: Colors.transparent,
                  textColor: Colors.white,
                ),
              ),
              Expanded(
                child: WelcomeButton(
                  buttonText: 'Regisztráció',
                  onTap: const SignUpScreen(),
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
