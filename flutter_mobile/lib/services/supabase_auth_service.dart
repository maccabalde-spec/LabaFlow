import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();

  SupabaseClient get _client => Supabase.instance.client;
  User? get authUser => _client.auth.currentUser;

  Future<bool> signInWithGoogle() => _client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb ? null : 'com.labaday.labaflow_mobile://login-callback/',
  );

  Future<AppUser?> restoreSession() async {
    final user = authUser;
    if (user == null) return null;
    return _loadProfile(user);
  }

  Future<AppUser> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(), password: password,
    );
    final user = response.user;
    if (user == null) throw StateError('Supabase did not return a user session.');
    return _loadProfile(user);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': name.trim(), 'phone': phone.trim()},
    );
    final user = response.user;
    if (user == null) throw StateError('Supabase did not create an account.');
    if (response.session == null) {
      throw StateError('Check your email to confirm the account, then sign in.');
    }
    return _loadProfile(user);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppUser> updateProfile({
    required AppUser current,
    required String name,
    required String email,
    required String phone,
    String? password,
    String? photoUrl,
  }) async {
    final user = authUser;
    if (user == null || user.id != current.authUid) {
      throw StateError('Your session has expired. Sign in again.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    await _client.auth.updateUser(UserAttributes(
      email: normalizedEmail != user.email ? normalizedEmail : null,
      password: password?.isNotEmpty == true ? password : null,
      data: {'name': name.trim(), 'phone': phone.trim()},
    ));
    final profileEmail = normalizedEmail == user.email ? normalizedEmail : (user.email ?? current.email);
    final row = await _client.from('profiles').update({
      'full_name': name.trim(),
      'email': profileEmail,
      'phone': phone.trim(),
      'avatar_url': photoUrl ?? current.pic,
    }).eq('id', user.id).select().single();
    return _fromProfile(row);
  }

  Future<List<AppUser>> listUsers() async {
    final rows = await _client.from('profiles').select().order('public_id');
    return (rows as List).map((row) => _fromProfile(Map<String, dynamic>.from(row))).toList();
  }

  Future<AppUser> saveUserProfile(AppUser user, {String? invitePassword}) async {
    if (user.authUid.isEmpty) {
      if (invitePassword == null || invitePassword.length < 12) {
        throw StateError('Use a temporary password with at least 12 characters.');
      }
      final result = await _client.functions.invoke('admin-users', body: {
        'action': 'invite',
        'password': invitePassword,
        'user': _userPayload(user),
      });
      return _fromProfile(Map<String, dynamic>.from(result.data['profile']));
    }
    if (invitePassword != null && invitePassword.isNotEmpty && invitePassword.length < 12) {
      throw StateError('Use a temporary password with at least 12 characters.');
    }
    final result = await _client.functions.invoke('admin-users', body: {
      'action': 'update',
      'password': invitePassword,
      'user': _userPayload(user),
    });
    return _fromProfile(Map<String, dynamic>.from(result.data['profile']));
  }

  Future<void> deleteUserProfile(AppUser user) async {
    if (user.authUid.isEmpty) throw StateError('This account has no Supabase identity.');
    await _client.functions.invoke('admin-users', body: {
      'action': 'delete', 'uid': user.authUid,
    });
  }

  Future<int> addLoyaltyPoints(int userId, double amount) async {
    final profile = await _client.from('profiles').select('id')
        .eq('public_id', userId).maybeSingle();
    if (profile == null) throw StateError('Customer profile not found.');
    return grantPoints(profile['id'] as String, amount);
  }

  Future<int> grantPoints(String recipientUid, double amount) async {
    final result = await _client.functions.invoke('admin-users', body: {
      'action': 'award-points', 'recipientUid': recipientUid, 'amount': amount,
    });
    return (result.data['points'] as num).toInt();
  }

  Future<AppUser> _loadProfile(User user) async {
    var row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) {
      throw StateError('Your Supabase profile is missing. Ask an administrator to check the database migration.');
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final googleName = metadata['full_name'] as String? ?? metadata['name'] as String?;
    final googlePhoto = metadata['avatar_url'] as String? ?? metadata['picture'] as String?;
    final updates = <String, dynamic>{};
    final profileName = row['full_name'] as String? ?? '';
    final emailPrefix = (user.email ?? '').split('@').first;
    if ((profileName.isEmpty || profileName == 'Customer' || profileName == emailPrefix) && googleName != null) {
      updates['full_name'] = googleName;
    }
    if ((row['avatar_url'] as String?)?.isEmpty ?? true) {
      if (googlePhoto != null) updates['avatar_url'] = googlePhoto;
    }
    if (updates.isNotEmpty) {
      row = await _client.from('profiles').update(updates).eq('id', user.id).select().single();
    }
    return _fromProfile(row, user: user);
  }

  Map<String, dynamic> _userPayload(AppUser user) => {
    'authUid': user.authUid,
    'name': user.name,
    'email': user.email.trim().toLowerCase(),
    'phone': user.phone,
    'role': user.role.name,
    'pic': user.pic,
  };

  AppUser _fromProfile(Map<String, dynamic> row, {User? user}) => AppUser(
    id: (row['public_id'] as num?)?.toInt() ?? 0,
    authUid: row['id'] as String,
    name: (row['full_name'] as String?) ?? 'Customer',
    email: (row['email'] as String?) ?? '',
    phone: (row['phone'] as String?) ?? '',
    role: UserRoleExt.fromString((row['role'] as String?) ?? 'CUSTOMER'),
    points: (row['points'] as num?)?.toInt() ?? 0,
    pic: row['avatar_url'] as String?,
    googleConnected: (user?.appMetadata['providers'] as List?)?.contains('google') ?? false,
  );
}
