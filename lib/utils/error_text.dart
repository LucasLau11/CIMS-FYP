import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lang.dart';

/// Turns any thrown object into a short message that is safe to show to an
/// end user. Raw `error.toString()` text leaks table names, policy names and
/// SQL details, so screens should always show `friendlyError(e)` instead.
///
/// The original error is still printed in debug builds so it stays easy to
/// diagnose during development.
String friendlyError(Object error) {
  if (kDebugMode) {
    debugPrint('friendlyError: ${error.runtimeType}: $error');
  }

  if (error is SocketException || error is TimeoutException || error is http.ClientException) {
    return tr('No internet connection. Please check your connection and try again.', ms: 'Tiada sambungan internet. Sila semak sambungan anda dan cuba lagi.', zh: '没有网络连接。请检查网络后重试。');
  }

  if (error is PostgrestException) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();
    if (code == '42501' || message.contains('row-level security') || message.contains('permission denied')) {
      return tr('You do not have permission to do that.', ms: 'Anda tidak mempunyai kebenaran untuk melakukannya.', zh: '您没有权限执行此操作。');
    }
    if (code == '23505') return tr('That already exists.', ms: 'Itu sudah wujud.', zh: '该内容已存在。');
    if (code == '23503') return tr('This is linked to other records, so it cannot be changed.', ms: 'Ini dipautkan kepada rekod lain, jadi ia tidak boleh diubah.', zh: '该内容与其他记录关联，因此无法更改。');
    if (code == '23514' || code == '23502') return tr('Some of the information entered is not valid.', ms: 'Sebahagian maklumat yang dimasukkan tidak sah.', zh: '输入的部分信息无效。');
    if (code == 'PGRST116') return tr('That item could not be found.', ms: 'Item itu tidak dijumpai.', zh: '找不到该项目。');
    // P0001 is a deliberate `raise exception` from one of our own database
    // functions (e.g. "the last administrator cannot delete their account"),
    // written to be read by a person.
    if (code == 'P0001' && error.message.length <= 160 && !_looksTechnical(error.message)) {
      return error.message[0].toUpperCase() + error.message.substring(1) +
          (error.message.endsWith('.') ? '' : '.');
    }
    return _somethingWrong();
  }

  if (error is StorageException) {
    final status = error.statusCode ?? '';
    if (status == '413' || error.message.toLowerCase().contains('exceeded the maximum')) {
      return tr('That file is too large.', ms: 'Fail itu terlalu besar.', zh: '文件过大。');
    }
    if (status == '415' || error.message.toLowerCase().contains('mime type')) {
      return tr('That file type is not allowed.', ms: 'Jenis fail itu tidak dibenarkan.', zh: '不允许该文件类型。');
    }
    return tr('The file could not be uploaded or opened. Please try again.', ms: 'Fail tidak dapat dimuat naik atau dibuka. Sila cuba lagi.', zh: '无法上传或打开文件。请重试。');
  }

  if (error is AuthException) {
    return tr('Authentication failed. Please log in again.', ms: 'Pengesahan gagal. Sila log masuk semula.', zh: '身份验证失败。请重新登录。');
  }

  if (error is FileSystemException) {
    return tr('The file could not be read.', ms: 'Fail tidak dapat dibaca.', zh: '无法读取文件。');
  }

  // Exceptions the app throws on purpose (`throw Exception('You must be
  // logged in.')`) already carry a user-facing sentence — keep those.
  if (error is Exception) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isNotEmpty && text.length <= 160 && !_looksTechnical(text)) return text;
  }

  return _somethingWrong();
}

String _somethingWrong() => tr('Something went wrong. Please try again.', ms: 'Sesuatu telah berlaku. Sila cuba lagi.', zh: '出了点问题，请重试。');

/// True when [error] is a database refusal that [friendlyError] can only describe in general
/// terms (an invalid value, a duplicate, or something unexpected), so a screen that knows the
/// likely cause can say it more helpfully.
bool isVagueDatabaseError(Object error) {
  if (error is! PostgrestException) return false;
  final code = error.code ?? '';
  if (code == '23514' || code == '23502' || code == '23505') return true;
  return !const {'42501', '23503', 'PGRST116', 'P0001'}.contains(code);
}

bool _looksTechnical(String text) {
  final lower = text.toLowerCase();
  return lower.contains('postgrest') ||
      lower.contains('sqlstate') ||
      lower.contains('violates') ||
      lower.contains('relation "') ||
      lower.contains('instance of') ||
      lower.contains('stack') ||
      lower.contains('supabase') ||
      lower.contains('socketexception') ||
      lower.contains('{') ||
      lower.contains('http://') ||
      lower.contains('https://');
}
