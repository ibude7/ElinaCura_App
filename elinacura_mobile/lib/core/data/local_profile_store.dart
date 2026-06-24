import '../../shared/models/models.dart';
import 'local_prefs.dart';

/// Device-local health profiles when the API is unreachable (PWA parity).
class LocalProfileStore {
  LocalProfileStore._();

  static const _key = 'ec.pref.health_profiles';

  static Future<List<HealthProfile>> readAll() async {
    final rows = await LocalPrefs.readList(_key);
    return rows.map(HealthProfile.fromJson).where((p) => p.id.isNotEmpty).toList();
  }

  static Future<void> saveAll(List<HealthProfile> profiles) async {
    await LocalPrefs.writeList(
      _key,
      profiles.map((p) => p.toJson()).toList(),
    );
  }

  static Future<void> upsert(HealthProfile profile) async {
    final all = await readAll();
    final idx = all.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      all[idx] = profile;
    } else {
      all.add(profile);
    }
    await saveAll(all);
  }
}
