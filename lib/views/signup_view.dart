import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/custom_text_form_field.dart';
import '../models/user_role.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/custom_scaffold.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../widgets/loading_overlay.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool agreePersonalData = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formSignupKey.currentState!.validate() && agreePersonalData) {
      final role = ref.read(roleProvider);
      if (role == null) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Figyelmeztetés',
            message: 'Kérlek válassz szerepkört.',
            contentType: ContentType.warning,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
         snackBar
        );
        return;
      }
      final authViewModel = ref.read(authViewModelProvider.notifier);

      await authViewModel.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: role
      );

      final state = ref.read(authViewModelProvider);
      state.when(
        data: (_) {
          CustomSnackBar.success("Sikeres regisztráció!");
          context.goNamed(AppRoute.signin.name);
        },
        loading: () {},
        error: (e, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(CustomSnackBar.error(e.toString()));
          print(e);
        },
      );
    } else if (!agreePersonalData) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.info('Kérlet fogadd el az adatkezelési feltételeket.')
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final selectedRole = ref.watch(roleProvider);
    return LoadingOverlay(
      isLoading: state is AsyncLoading,
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
                    key: _formSignupKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Kezdjük',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w900
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        // Teljes név
                        CustomTextFormField(
                          controller: _nameController,
                          validator:
                              RequiredValidator(
                                errorText: 'Teljes név megadása kötelező.',
                              ).call,
                          labelText: "Teljes név",
                        ),
                        const SizedBox(height: 25.0),
                        // Email
                        CustomTextFormField(
                          controller: _emailController,
                          validator:
                              MultiValidator([
                                RequiredValidator(
                                  errorText: 'Email cím megadása kötelező.',
                                ),
                                EmailValidator(
                                  errorText: 'Érvényes email címet adjon meg.',
                                ),
                              ]).call,
                          labelText: "Email",
                        ),
                        const SizedBox(height: 25.0),
                        // Jelszó
                        CustomTextFormField(
                          controller: _passwordController,
                          obscureText: true,
                         validator:
                              MultiValidator([
                                RequiredValidator(
                                  errorText: 'Jelszó megadása kötelező.',
                                ),
                                MinLengthValidator(
                                  6,
                                  errorText:
                                      'A jelszónak legalább 6 karakter hosszúnak kell lennie.',
                                ),
                              ]).call,
                         labelText: "Jelszó",
                        ),
                        const SizedBox(height: 25.0),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<UserRole>(
                                  value: UserRole.landlord,
                                  groupValue: selectedRole,
                                  onChanged: (value) {
                                    ref.read(roleProvider.notifier).state =
                                        value;
                                  },
                                ),
                                Text(UserRole.landlord.label),
                                const SizedBox(width: 20),
                                Radio<UserRole>(
                                  value: UserRole.tenant,
                                  groupValue: selectedRole,
                                  onChanged: (value) {
                                    ref.read(roleProvider.notifier).state =
                                        value;
                                  },
                                ),
                                Text(UserRole.tenant.label),
                              ],
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
                                      text: 'Elfogadom a személyes adatok kezelését',
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
                                state is AsyncLoading ? null : _submitForm,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
