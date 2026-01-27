import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/custom_text_form_field.dart';
import '../models/user_role.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/custom_scaffold.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../widgets/loading_overlay.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool agreePersonalData = true;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);
    return LoadingOverlay(
      isLoading: state.isLoading,
      child: CustomScaffold(
        child: Column(
          children: [
            const Expanded(flex: 1, child: SizedBox(height: 10)),
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Kezdjük',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        // Teljes név
                        CustomTextFormField(
                          labelText: "Teljes név",
                          errorText: state.nameError,
                          onChanged: vm.onNameChanged,
                        ),
                        const SizedBox(height: 25.0),
                        // Email
                        CustomTextFormField(
                          labelText: "Email",
                          errorText: state.emailError,
                          onChanged: vm.onEmailChanged,
                        ),
                        const SizedBox(height: 25.0),
                        // Jelszó
                        CustomTextFormField(
                          labelText: "Jelszó",
                          obscureText: true,
                          errorText: state.passwordError,
                          onChanged: vm.onPasswordChanged,
                        ),
                        const SizedBox(height: 41),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<UserRole>(
                                  value: UserRole.landlord,
                                  groupValue: state.role,
                                  onChanged: vm.onRoleChanged,
                                ),
                                Text(UserRole.landlord.label),
                                const SizedBox(width: 20),
                                Radio<UserRole>(
                                  value: UserRole.tenant,
                                  groupValue: state.role,
                                  onChanged: vm.onRoleChanged,
                                ),
                                Text(UserRole.tenant.label),
                              ],
                            ),
                            if (state.roleError != null)
                              Text(
                                state.roleError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        // Checkbox
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: agreePersonalData,
                              onChanged: (bool? value) {
                                setState(
                                  () => agreePersonalData = value ?? false,
                                );
                              },
                            ),
                            Flexible(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Elfogadom a személyes adatok kezelését',
                                      style: TextStyle(color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25.0),
                        // Gomb
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                state.isLoading ? null : vm.submit,
                            child: const Text('Regisztráció'),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        _dividerRow('Regisztrálj'),
                        const SizedBox(height: 30.0),
                        _socialRow(),
                        const SizedBox(height: 25.0),
                        // Már van fiókod?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Van már fiókod? ',
                              style: TextStyle(color: Colors.black45),
                            ),
                            GestureDetector(
                              onTap:
                                  () => context.goNamed(AppRoute.signin.name),
                              child: Text(
                                'Jelentkezz be',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
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

  Widget _dividerRow(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(thickness: 0.7, color: Colors.grey.withOpacity(0.5)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: const TextStyle(color: Colors.black45)),
        ),
        Expanded(
          child: Divider(thickness: 0.7, color: Colors.grey.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Logo(Logos.facebook_f),
        Logo(Logos.twitter),
        Logo(Logos.google),
        Logo(Logos.apple),
      ],
    );
  }
}
