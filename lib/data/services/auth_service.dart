import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current user id
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName, // Supabase metadata
        'phone': phone,
        'role': role,
      },
    );

    // User profile is created automatically by database trigger
    // defined in triggers.sql
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get User Profile
  Future<UserModel?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    // Ensure email is populated from the source of truth (Auth)
    // because public.users table might have outdated or missing email
    final Map<String, dynamic> mutableData = Map<String, dynamic>.from(data);
    if (user.email != null) {
      mutableData['email'] = user.email!;
    }

    return UserModel.fromJson(mutableData);
  }

  // Get User Profile by ID
  Future<UserModel?> getUserById(String userId) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;

    return UserModel.fromJson(data);
  }

  // Get Multiple Users
  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final data = await _supabase.from('users').select().filter('id', 'in', ids);

    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  // Update User Role to Agent
  Future<void> upgradeToAgent(String businessName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('users')
        .update({'role': 'agent', 'business_name': businessName})
        .eq('id', user.id);
  }
}
