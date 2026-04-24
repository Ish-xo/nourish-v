import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/bhashini_service.dart';

// ---- Localization State ----
// Holds locale + a rebuild version counter so Riverpod detects changes
// even when the locale itself hasn't changed (e.g. async translations arrive).

class LocalizationState {
  final String locale;
  final int _version;

  const LocalizationState(this.locale, [this._version = 0]);

  LocalizationState bump() => LocalizationState(locale, _version + 1);
  LocalizationState withLocale(String l) => LocalizationState(l, _version + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizationState &&
          locale == other.locale &&
          _version == other._version;

  @override
  int get hashCode => locale.hashCode ^ _version.hashCode;
}

// ---- Localization Controller ----
// Fully API-driven for non-English locales.
// English text is returned as-is (source language).
// All other locales are translated via Bhashini API with in-memory cache.

class LocalizationController extends StateNotifier<LocalizationState> {
  LocalizationController() : super(const LocalizationState(AppLocales.english));

  // In-memory translation cache: { locale: { sourceText: translatedText } }
  final Map<String, Map<String, String>> _cache = {};

  // Tracks in-flight requests to avoid duplicates
  final Set<String> _pending = {};

  /// Current locale string
  String get locale => state.locale;

  void setLocale(String locale) {
    if (AppLocales.supported.contains(locale)) {
      state = state.withLocale(locale);
    }
  }

  /// Translates [text].
  /// - English → returns immediately as-is.
  /// - Other → returns cached translation if available, otherwise returns
  ///   [text] (English fallback) and triggers an async API translation
  ///   that rebuilds the UI when complete.
  String tr(String text) {
    if (text.isEmpty) return text;
    if (state.locale == 'en') return text;

    final cached = _cache[state.locale]?[text];
    if (cached != null) return cached;

    // Kick off async translation if not already in flight
    final key = '${state.locale}__$text';
    if (!_pending.contains(key)) {
      _pending.add(key);
      _translate(text, state.locale);
    }

    return text; // Temporarily show English while translating
  }

  Future<void> _translate(String text, String targetLocale) async {
    try {
      final translated =
          await BhashiniService.translate(text, 'en', targetLocale);
      _cache[targetLocale] ??= {};
      _cache[targetLocale]![text] = translated;

      // Only rebuild if locale hasn't changed and widget is still mounted
      if (state.locale == targetLocale && mounted) {
        state = state.bump(); // trigger Riverpod rebuild via version bump
      }
    } catch (_) {
      // Silently ignore — text stays as English fallback
    } finally {
      _pending.remove('${targetLocale}__$text');
    }
  }
}

// ---- Riverpod Provider ----

final localizationProvider =
    StateNotifierProvider<LocalizationController, LocalizationState>((ref) {
  return LocalizationController();
});

/// Convenience top-level helper — watches the provider for rebuilds.
String tr(WidgetRef ref, String text) {
  ref.watch(localizationProvider);
  return ref.read(localizationProvider.notifier).tr(text);
}
