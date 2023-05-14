/// bindings for `libcashu`

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;

// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names
final DynamicLibrary _dl = _open();
/// Reference to the Dynamic Library, it should be only used for low-level access
final DynamicLibrary dl = _dl;
DynamicLibrary _open() {
  if (Platform.isAndroid) return DynamicLibrary.open('libcashu_ffi.so');
  if (Platform.isIOS) return DynamicLibrary.executable();
  throw UnsupportedError('This platform is not supported.');
}

/// C function `check_spendable`.
int check_spendable(
  int port,
  Pointer<ffi.Utf8> encoded_token,
) {
  return _check_spendable(port, encoded_token);
}
final _check_spendable_Dart _check_spendable = _dl.lookupFunction<_check_spendable_C, _check_spendable_Dart>('check_spendable');
typedef _check_spendable_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> encoded_token,
);
typedef _check_spendable_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> encoded_token,
);

/// C function `create_wallet`.
int create_wallet(
  int port,
  Pointer<ffi.Utf8> url,
) {
  return _create_wallet(port, url);
}
final _create_wallet_Dart _create_wallet = _dl.lookupFunction<_create_wallet_C, _create_wallet_Dart>('create_wallet');
typedef _create_wallet_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> url,
);
typedef _create_wallet_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> url,
);

/// C function `decode_invoice`.
int decode_invoice(
  int port,
  Pointer<ffi.Utf8> invoice,
) {
  return _decode_invoice(port, invoice);
}
final _decode_invoice_Dart _decode_invoice = _dl.lookupFunction<_decode_invoice_C, _decode_invoice_Dart>('decode_invoice');
typedef _decode_invoice_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> invoice,
);
typedef _decode_invoice_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> invoice,
);

/// C function `decode_token`.
int decode_token(
  int port,
  Pointer<ffi.Utf8> token,
) {
  return _decode_token(port, token);
}
final _decode_token_Dart _decode_token = _dl.lookupFunction<_decode_token_C, _decode_token_Dart>('decode_token');
typedef _decode_token_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> token,
);
typedef _decode_token_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> token,
);

/// C function `error_message_utf8`.
int error_message_utf8(
  Pointer<ffi.Utf8> buf,
  int length,
) {
  return _error_message_utf8(buf, length);
}
final _error_message_utf8_Dart _error_message_utf8 = _dl.lookupFunction<_error_message_utf8_C, _error_message_utf8_Dart>('error_message_utf8');
typedef _error_message_utf8_C = Int32 Function(
  Pointer<ffi.Utf8> buf,
  Int32 length,
);
typedef _error_message_utf8_Dart = int Function(
  Pointer<ffi.Utf8> buf,
  int length,
);

/// C function `get_balances`.
int get_balances(
  int port,
) {
  return _get_balances(port);
}
final _get_balances_Dart _get_balances = _dl.lookupFunction<_get_balances_C, _get_balances_Dart>('get_balances');
typedef _get_balances_C = Int32 Function(
  Int64 port,
);
typedef _get_balances_Dart = int Function(
  int port,
);

/// C function `get_mints`.
int get_mints(
  int port,
) {
  return _get_mints(port);
}
final _get_mints_Dart _get_mints = _dl.lookupFunction<_get_mints_C, _get_mints_Dart>('get_mints');
typedef _get_mints_C = Int32 Function(
  Int64 port,
);
typedef _get_mints_Dart = int Function(
  int port,
);

/// C function `get_proofs`.
int get_proofs(
  int port,
) {
  return _get_proofs(port);
}
final _get_proofs_Dart _get_proofs = _dl.lookupFunction<_get_proofs_C, _get_proofs_Dart>('get_proofs');
typedef _get_proofs_C = Int32 Function(
  Int64 port,
);
typedef _get_proofs_Dart = int Function(
  int port,
);

/// C function `last_error_length`.
int last_error_length() {
  return _last_error_length();
}
final _last_error_length_Dart _last_error_length = _dl.lookupFunction<_last_error_length_C, _last_error_length_Dart>('last_error_length');
typedef _last_error_length_C = Int32 Function();
typedef _last_error_length_Dart = int Function();

/// C function `mint`.
int mint(
  int port,
  int amount,
  Pointer<ffi.Utf8> hash,
  Pointer<ffi.Utf8> mint,
) {
  return _mint(port, amount, hash, mint);
}
final _mint_Dart _mint = _dl.lookupFunction<_mint_C, _mint_Dart>('mint');
typedef _mint_C = Int32 Function(
  Int64 port,
  Int64 amount,
  Pointer<ffi.Utf8> hash,
  Pointer<ffi.Utf8> mint,
);
typedef _mint_Dart = int Function(
  int port,
  int amount,
  Pointer<ffi.Utf8> hash,
  Pointer<ffi.Utf8> mint,
);

/// C function `pay_invoice`.
int pay_invoice(
  int port,
  int amount,
  Pointer<ffi.Utf8> invoice,
  Pointer<ffi.Utf8> mint,
) {
  return _pay_invoice(port, amount, invoice, mint);
}
final _pay_invoice_Dart _pay_invoice = _dl.lookupFunction<_pay_invoice_C, _pay_invoice_Dart>('pay_invoice');
typedef _pay_invoice_C = Int32 Function(
  Int64 port,
  Int64 amount,
  Pointer<ffi.Utf8> invoice,
  Pointer<ffi.Utf8> mint,
);
typedef _pay_invoice_Dart = int Function(
  int port,
  int amount,
  Pointer<ffi.Utf8> invoice,
  Pointer<ffi.Utf8> mint,
);

/// C function `receive_token`.
int receive_token(
  int port,
  Pointer<ffi.Utf8> token,
) {
  return _receive_token(port, token);
}
final _receive_token_Dart _receive_token = _dl.lookupFunction<_receive_token_C, _receive_token_Dart>('receive_token');
typedef _receive_token_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> token,
);
typedef _receive_token_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> token,
);

/// C function `remove_wallet`.
int remove_wallet(
  int port,
  Pointer<ffi.Utf8> url,
) {
  return _remove_wallet(port, url);
}
final _remove_wallet_Dart _remove_wallet = _dl.lookupFunction<_remove_wallet_C, _remove_wallet_Dart>('remove_wallet');
typedef _remove_wallet_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> url,
);
typedef _remove_wallet_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> url,
);

/// C function `request_mint`.
int request_mint(
  int port,
  int amount,
  Pointer<ffi.Utf8> mint,
) {
  return _request_mint(port, amount, mint);
}
final _request_mint_Dart _request_mint = _dl.lookupFunction<_request_mint_C, _request_mint_Dart>('request_mint');
typedef _request_mint_C = Int32 Function(
  Int64 port,
  Int64 amount,
  Pointer<ffi.Utf8> mint,
);
typedef _request_mint_Dart = int Function(
  int port,
  int amount,
  Pointer<ffi.Utf8> mint,
);

/// C function `send`.
int send(
  int port,
  int amount,
  Pointer<ffi.Utf8> active_mint,
) {
  return _send(port, amount, active_mint);
}
final _send_Dart _send = _dl.lookupFunction<_send_C, _send_Dart>('send');
typedef _send_C = Int32 Function(
  Int64 port,
  Int64 amount,
  Pointer<ffi.Utf8> active_mint,
);
typedef _send_Dart = int Function(
  int port,
  int amount,
  Pointer<ffi.Utf8> active_mint,
);

/// C function `set_mints`.
int set_mints(
  int port,
  Pointer<ffi.Utf8> mints,
) {
  return _set_mints(port, mints);
}
final _set_mints_Dart _set_mints = _dl.lookupFunction<_set_mints_C, _set_mints_Dart>('set_mints');
typedef _set_mints_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> mints,
);
typedef _set_mints_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> mints,
);

/// C function `set_proofs`.
int set_proofs(
  int port,
  Pointer<ffi.Utf8> proofs,
) {
  return _set_proofs(port, proofs);
}
final _set_proofs_Dart _set_proofs = _dl.lookupFunction<_set_proofs_C, _set_proofs_Dart>('set_proofs');
typedef _set_proofs_C = Int32 Function(
  Int64 port,
  Pointer<ffi.Utf8> proofs,
);
typedef _set_proofs_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> proofs,
);

/// Binding to `allo-isolate` crate
void store_dart_post_cobject(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
) {
  _store_dart_post_cobject(ptr);
}
final _store_dart_post_cobject_Dart _store_dart_post_cobject = _dl.lookupFunction<_store_dart_post_cobject_C, _store_dart_post_cobject_Dart>('store_dart_post_cobject');
typedef _store_dart_post_cobject_C = Void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
typedef _store_dart_post_cobject_Dart = void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
