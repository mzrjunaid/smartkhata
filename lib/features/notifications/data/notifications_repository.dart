import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../../../core/providers/profile_providers.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(Supabase.instance.client);
});

final notificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final currentProfileAsync = ref.watch(currentProfileProvider);
  
  return currentProfileAsync.when(
    data: (profile) {
      if (profile == null) return Stream.value([]);
      final repository = ref.watch(notificationsRepositoryProvider);
      return repository.watchNotifications(profile['id']);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

class NotificationsRepository {
  NotificationsRepository(this._supabase);

  final SupabaseClient _supabase;

  Stream<List<NotificationModel>> watchNotifications(String profileId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> markAllAsRead(String profileId) async {
    await _supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('profile_id', profileId)
        .isFilter('read_at', null); // only update unread ones
  }
}
