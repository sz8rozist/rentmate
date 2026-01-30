import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/user_role.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/custom_text_form_field.dart';
import '../models/auth_state.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../widgets/custom_scaffold.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/loading_overlay.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final loginVM = ref.read(loginViewModelProvider.notifier);
    bool rememberPassword = false;

    void handleLogin() {
      loginVM.submit().then((success) {
        final payload = ref.read(authViewModelProvider).asData?.value.payload;
        print(payload);
        if (payload != null) {
          ref.read(bottomNavIndexProvider.notifier).state = 0;
          if (payload.role == UserRole.landlord) {
            context.goNamed(AppRoute.flatSelect.name);
          } else {
            context.goNamed(AppRoute.home.name);
          }
        }
      }).catchError((err) {
        CustomSnackBar.error(context, err.toString());
      });
    }

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: CustomScaffold(
        child: Column(
          children: [
            const Expanded(flex: 1, child: SizedBox(height: 10)),
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 50, 25, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Üdv újra',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomTextFormField(
                          labelText: "Email",
                          onChanged: loginVM.onEmailChanged,
                          errorText: state.errors.errorFor('email'),
                        ),
                        const SizedBox(height: 25),
                        CustomTextFormField(
                          obscureText: true,
                          labelText: "Jelszó",
                          onChanged: loginVM.onPasswordChanged,
                          errorText: state.errors.errorFor('password'),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                StatefulBuilder(
                                  builder: (context, setState) => Checkbox(
                                    value: rememberPassword,
                                    onChanged: (v) => setState(() {
                                      rememberPassword = v!;
                                    }),
                                  ),
                                ),
                                const Text(
                                  'Emlékezz rám',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                            const Text(
                              'Elfelejtett jelszó?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.isLoading ? null : handleLogin,
                            child: const Text('Bejelentkezés'),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Nincs még fiókod? ',
                              style: TextStyle(color: Colors.black45),
                            ),
                            GestureDetector(
                              onTap: () => context.goNamed(AppRoute.signup.name),
                              child: const Text(
                                'Regisztrálj',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

