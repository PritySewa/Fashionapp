// Unit tests for SlugUtils
//
// Coverage:
//   - Normal category name → lowercase slug
//   - Apostrophe in name → removed (non-alphanumeric)
//   - Ampersand and extra spaces → single hyphen
//   - Leading and trailing whitespace → trimmed
//   - Multiple consecutive special characters → single hyphen
//   - All-special-character input → empty string
//   - Numbers in name → preserved
//   - Already-valid slug → unchanged
//   - Mixed case → lowercased

import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_admin/core/utils/slug_utils.dart';

void main() {
  group('SlugUtils.toSlug', () {
    // ── Normal names ─────────────────────────────────────────────────────────

    test('single word is lowercased', () {
      expect(SlugUtils.toSlug('Electronics'), 'electronics');
    });

    test('two words separated by a space become hyphenated', () {
      expect(SlugUtils.toSlug('Mobile Phones'), 'mobile-phones');
    });

    test('already lowercase single word is unchanged', () {
      expect(SlugUtils.toSlug('electronics'), 'electronics');
    });

    // ── Apostrophes ───────────────────────────────────────────────────────────

    test("apostrophe in possessive is removed — Men's Shoes → mens-shoes", () {
      expect(SlugUtils.toSlug("Men's Shoes"), 'mens-shoes');
    });

    test("apostrophe-only contraction is collapsed — Women's → womens", () {
      expect(SlugUtils.toSlug("Women's"), 'womens');
    });

    // ── Ampersand and special characters ─────────────────────────────────────

    test('ampersand becomes a single hyphen between words', () {
      expect(SlugUtils.toSlug('Home & Kitchen'), 'home-kitchen');
    });

    test('multiple special chars between words collapse to one hyphen', () {
      expect(SlugUtils.toSlug('Home & Kitchen!!'), 'home-kitchen');
    });

    test('percent sign between word and number becomes hyphen', () {
      expect(SlugUtils.toSlug('100% Cotton'), '100-cotton');
    });

    // ── Whitespace ────────────────────────────────────────────────────────────

    test('leading and trailing whitespace is stripped', () {
      expect(SlugUtils.toSlug('  Electronics  '), 'electronics');
    });

    test('leading and trailing whitespace around two words is stripped', () {
      expect(SlugUtils.toSlug('  Home & Kitchen  '), 'home-kitchen');
    });

    test('internal multiple spaces collapse to a single hyphen', () {
      expect(SlugUtils.toSlug('Sports   &   Outdoors'), 'sports-outdoors');
    });

    // ── Edge cases ────────────────────────────────────────────────────────────

    test('all-special-character input produces an empty string', () {
      expect(SlugUtils.toSlug('---'), '');
    });

    test('input with only whitespace produces an empty string', () {
      expect(SlugUtils.toSlug('   '), '');
    });

    test('empty string produces an empty string', () {
      expect(SlugUtils.toSlug(''), '');
    });

    // ── Numbers ───────────────────────────────────────────────────────────────

    test('numbers in a name are preserved', () {
      expect(SlugUtils.toSlug('Zone 1 Products'), 'zone-1-products');
    });

    test('number-only input is preserved', () {
      expect(SlugUtils.toSlug('123'), '123');
    });

    // ── Leading/trailing hyphens ──────────────────────────────────────────────

    test('leading hyphens from special chars are stripped', () {
      expect(SlugUtils.toSlug('---weird'), 'weird');
    });

    test('trailing hyphens from special chars are stripped', () {
      expect(SlugUtils.toSlug('weird---'), 'weird');
    });

    test('leading and trailing hyphens are both stripped', () {
      expect(SlugUtils.toSlug('---weird---'), 'weird');
    });

    // ── Full realistic examples ───────────────────────────────────────────────

    test('realistic: Electronics', () {
      expect(SlugUtils.toSlug('Electronics'), 'electronics');
    });

    test("realistic: Men's Shoes → mens-shoes", () {
      expect(SlugUtils.toSlug("Men's Shoes"), 'mens-shoes');
    });

    test(
      'realistic: Home & Kitchen with surrounding spaces → home-kitchen',
      () {
        expect(SlugUtils.toSlug('  Home & Kitchen  '), 'home-kitchen');
      },
    );

    test('realistic: Mobile Phones → mobile-phones', () {
      expect(SlugUtils.toSlug('Mobile Phones'), 'mobile-phones');
    });
  });
}
