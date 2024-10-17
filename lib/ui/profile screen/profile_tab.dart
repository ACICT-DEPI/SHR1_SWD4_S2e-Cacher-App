import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/cubit/auth_cubit.dart';
import 'cubit/manager_cubit.dart';
import 'cubit/manager_states.dart';

// File: profile_tab.dart
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ManagerCubit()..fetchManagerData(),
        ),
        BlocProvider(create: (_) => AuthCubit())
      ],
      child: Builder(
        // Add this Builder widget
        builder: (BuildContext context) {
          // This context now has access to both providers
          return BlocBuilder<ManagerCubit, ManagerState>(
            builder: (context, state) {
              if (state is ManagerLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ManagerError) {
                return Center(child: Text(state.message));
              } else if (state is ManagerLoaded) {
                final manager = state.manager;
                final authCubit = context.read<AuthCubit>();
                return Padding(
                  padding: const EdgeInsets.only(
                      right: 16.0, left: 16, bottom: 16, top: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _showUpdateLogoDialog(context, authCubit);
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: manager.logoPath != null
                                ? NetworkImage(manager.logoPath!)
                                : const AssetImage(
                                        'assets/images/default_logo.png')
                                    as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          manager.name ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('البريد الإلكتروني'),
                          subtitle: Text(manager.email!),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.shop_two),
                          title: const Text('الاسم'),
                          subtitle: Text(manager.name ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showUpdateNameDialog(context, authCubit);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Center(child: Text('No Data'));
              }
            },
          );
        },
      ),
    );
  }

  // Dialog to update name
  void _showUpdateNameDialog(BuildContext context, AuthCubit authCubit) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('تحديث الاسم'),
                  content: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'أدخل الاسم الجديد',
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('إلغاء'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    ElevatedButton(
                      child: const Text('تحديث'),
                      onPressed: () {
                        authCubit.updateName(context,nameController.text)
                            .then((_) {
                          Navigator.of(dialogContext).pop();
                          context.read<ManagerCubit>().fetchManagerData();
                        });
                      },
                    ),
                  ],
                ),
              );
            },
        );
  }

  // Dialog to update logo
  void _showUpdateLogoDialog(BuildContext context, AuthCubit authCubit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تحديث الشعار'),
              content: const Text('هل ترغب في تحديث الشعار؟'),
              actions: [
                TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('تحديث'),
                  onPressed: () async {
                    await authCubit.imageFromGallery();
                    if (authCubit.selectedImage != null) {
                      await authCubit.updateLogo(context,authCubit.selectedImage!)
                          .then((_) {
                        Navigator.of(dialogContext).pop();
                        context.read<ManagerCubit>().fetchManagerData();
                      });
                    }
                  },
                ),
              ],
            ));
      },
    );
  }
}
