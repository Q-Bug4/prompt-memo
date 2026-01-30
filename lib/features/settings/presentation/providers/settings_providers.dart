import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

enum SortOrder { dateDesc, dateAsc, titleAsc, titleDesc }

class SettingsState {
  final AppThemeMode themeMode;
  final SortOrder sortOrder;
  final bool autoSave;
  final int cacheSize;
  final bool showThumbnails;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.sortOrder = SortOrder.dateDesc,
    this.autoSave = true,
    this.cacheSize = 0,
    this.showThumbnails = true,
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    SortOrder? sortOrder,
    bool? autoSave,
    int? cacheSize,
    bool? showThumbnails,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      sortOrder: sortOrder ?? this.sortOrder,
      autoSave: autoSave ?? this.autoSave,
      cacheSize: cacheSize ?? this.cacheSize,
      showThumbnails: showThumbnails ?? this.showThumbnails,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      themeMode: AppThemeMode.values[prefs.getInt('themeMode') ?? 0],
      sortOrder: SortOrder.values[prefs.getInt('sortOrder') ?? 0],
      autoSave: prefs.getBool('autoSave') ?? true,
      cacheSize: prefs.getInt('cacheSize') ?? 0,
      showThumbnails: prefs.getBool('showThumbnails') ?? true,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setSortOrder(SortOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortOrder', order.index);
    state = state.copyWith(sortOrder: order);
  }

  Future<void> setAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSave', value);
    state = state.copyWith(autoSave: value);
  }

  Future<void> setShowThumbnails(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showThumbnails', value);
    state = state.copyWith(showThumbnails: value);
  }

  Future<void> updateCacheSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cacheSize', size);
    state = state.copyWith(cacheSize: size);
  }

  Future<void> clearCache() async {
    state = state.copyWith(cacheSize: 0);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
