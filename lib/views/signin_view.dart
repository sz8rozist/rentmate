import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../theme/theme.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../widgets/custom_scaffold.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/loading_overlay.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool rememberPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Figyeld az állapotváltozást, és navigálj vagy mutass hibát
    ref.listen<AsyncValue<UserModel?>>(authViewModelProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
              context.goNamed(AppRoute.home.name);
            });
          }
        },
        loading: () {},
        error: (err, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(CustomSnackBar.error(err.toString()));
          });
        },
      );
    });
    return LoadingOverlay(
      isLoading: authState.isLoading,
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40.0),
                    topRight: Radius.circular(40.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formSignInKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Üdv újra',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w900,
                            color: lightColorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        TextFormField(
                          controller: _emailController,
                          validator:
                              MultiValidator([
                                RequiredValidator(
                                  errorText: 'Email megadása kötelező',
                                ),
                                EmailValidator(
                                  errorText: 'Érvénytelen email cím',
                                ),
                              ]).call,
                          decoration: InputDecoration(
                            label: const Text('Email'),
                            hintText: 'Írja be az email címét',
                            hintStyle: const TextStyle(color: Colors.black26),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          obscuringCharacter: '*',
                          validator:
                              RequiredValidator(
                                errorText: 'Jelszó megadása kötelező',
                              ).call,
                          decoration: InputDecoration(
                            label: const Text('Jelszó'),
                            hintText: 'Írja be a jelszavát',
                            hintStyle: const TextStyle(color: Colors.black26),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.black12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberPassword,
                                  onChanged: (value) {
                                    setState(() {
                                      rememberPassword = value!;
                                    });
                                  },
                                  activeColor: lightColorScheme.primary,
                                ),
                                const Text(
                                  'Emlékezz rám',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                            GestureDetector(
                              child: Text(
                                'Elfelejtett jelszó?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lightColorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                authState.isLoading
                                    ? null
                                    : () async {
                                      if (_formSignInKey.currentState!
                                          .validate()) {
                                        await ref
                                            .read(
                                              authViewModelProvider.notifier,
                                            )
                                            .signIn(
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
                                            );
                                      }
                                    },
                            child: const Text('Bejelentkezés'),
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Nincs még fiókod? ',
                              style: TextStyle(color: Colors.black45),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.goNamed(AppRoute.signup.name);
                              },
                              child: Text(
                                'Regisztrálj',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lightColorScheme.primary,
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
}
