import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sriwaap/auth_service.dart';
import 'package:sriwaap/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      print('DEBUG: auth state changed, user: ${user?.uid}');
      if (user == null) {
        state = const AsyncValue.data(null);
      } else {
        try {
          final appUser = await _authService.getUser(user.uid);
          print('DEBUG: setting state with appUser: $appUser');
          state = AsyncValue.data(appUser);
        } catch (e, st) {
          print('DEBUG: error getting user: $e');
          state = AsyncValue.error(e, st);
        }
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    print('DEBUG: signIn called');
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(email, password);
      print('DEBUG: signIn completed');
    } catch (e, st) {
      print('DEBUG: signIn error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
      return AuthNotifier(ref.watch(authServiceProvider));
    });
