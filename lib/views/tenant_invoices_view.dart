import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantInvoicesView extends ConsumerWidget {
  final String tenantUserId;

  const TenantInvoicesView({required this.tenantUserId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Text("Tenant Invoice Screen");
  }
}
