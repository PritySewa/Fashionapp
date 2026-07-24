/// Utility for generating URL-safe slugs from arbitrary text.
///
/// No external packages — pure Dart regex only.
///
/// ## Slug rules
/// 1. Trim leading and trailing whitespace.
/// 2. Lowercase the entire string.
/// 3. Replace every sequence of one or more characters that are **not**
///    `[a-z0-9]` with a single hyphen `-`.
/// 4. Strip any leading or trailing hyphens that remain after step 3.
///
/// ## Examples
/// | Input               | Output          |
/// |---------------------|-----------------|
/// | `"Electronics"`     | `"electronics"` |
/// | `"Men's Shoes"`     | `"mens-shoes"`  |
/// | `"  Home & Kitchen  "` | `"home-kitchen"` |
/// | `"Mobile Phones"`   | `"mobile-phones"` |
/// | `"---weird---"`     | `"weird"`        |
/// | `"100% Cotton"`     | `"100-cotton"`   |
abstract final class SlugUtils {
  /// Matches apostrophes (straight single quotes) for removal before
  /// hyphenation. Apostrophes in possessives and contractions (e.g. "Men's")
  /// should be deleted rather than converted to a hyphen so that the result is
  /// "mens" (not "men-s").
  static final RegExp _apostrophes = RegExp(r"'");

  // Matches one or more characters that are NOT lowercase letters or digits.
  static final RegExp _nonAlphanumeric = RegExp(r'[^a-z0-9]+');

  // Matches leading or trailing hyphens.
  static final RegExp _leadingTrailingHyphens = RegExp(r'^-+|-+$');

  /// Converts [input] into a URL-safe slug.
  ///
  /// Returns an empty string if [input] consists entirely of
  /// non-alphanumeric characters (e.g. `"---"`).
  static String toSlug(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(_apostrophes, '') // remove apostrophes before hyphenation
        .replaceAll(_nonAlphanumeric, '-')
        .replaceAll(_leadingTrailingHyphens, '');
  }
}
