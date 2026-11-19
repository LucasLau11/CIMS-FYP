import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fyp_cims/utils/error_text.dart';

void main() {
  group('friendlyError', () {
    test('never leaks database internals', () {
      final text = friendlyError(PostgrestException(
        message: 'duplicate key value violates unique constraint "applications_student_id_job_posting_id_key"',
        code: '23505',
      ));
      expect(text, 'That already exists.');
      expect(text.toLowerCase(), isNot(contains('constraint')));
    });

    test('maps row-level-security denials to a permission message', () {
      expect(
        friendlyError(PostgrestException(
            message: 'new row violates row-level security policy for table "profiles"', code: '42501')),
        'You do not have permission to do that.',
      );
    });

    test('maps foreign-key blocks', () {
      expect(
        friendlyError(PostgrestException(message: 'violates foreign key constraint', code: '23503')),
        'This is linked to other records, so it cannot be changed.',
      );
    });

    test('shows deliberate messages raised by our own database functions', () {
      expect(
        friendlyError(PostgrestException(
            message: 'the last administrator cannot delete their account', code: 'P0001')),
        'The last administrator cannot delete their account.',
      );
    });

    test('does not show unknown database errors', () {
      expect(
        friendlyError(PostgrestException(message: 'relation "secret_table" does not exist', code: '42P01')),
        'Something went wrong. Please try again.',
      );
    });

    test('treats network failures as a connection problem', () {
      const expected = 'No internet connection. Please check your connection and try again.';
      expect(friendlyError(const SocketException('Failed host lookup')), expected);
      expect(friendlyError(TimeoutException('timed out')), expected);
    });

    test('maps storage size and type rejections', () {
      expect(friendlyError(const StorageException('too big', statusCode: '413')), 'That file is too large.');
      expect(friendlyError(const StorageException('bad', statusCode: '415')), 'That file type is not allowed.');
    });

    test('keeps short, deliberate Exception messages', () {
      expect(friendlyError(Exception('You must be logged in.')), 'You must be logged in.');
    });

    test('hides technical Exception text and non-exceptions', () {
      expect(friendlyError(Exception('PostgrestException(message: boom, code: 500)')),
          'Something went wrong. Please try again.');
      expect(friendlyError(StateError('internal')), 'Something went wrong. Please try again.');
    });
  });
}
