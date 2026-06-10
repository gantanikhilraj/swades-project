import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUser {
  final String id;
  final String name;
  final String avatarUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

final List<AppUser> mockUsers = [
  AppUser(id: 'user_alice', name: 'Alice Smith', avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Alice'),
  AppUser(id: 'user_bob', name: 'Bob Jones', avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Bob'),
  AppUser(id: 'user_charlie', name: 'Charlie Brown', avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Charlie'),
];

class UserNotifier extends Notifier<AppUser> {
  @override
  AppUser build() => mockUsers[0];

  void selectUser(AppUser user) {
    state = user;
  }
}

final userProvider = NotifierProvider<UserNotifier, AppUser>(UserNotifier.new);
