import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:isolate/ports.dart';

import 'ffi.dart' as native;

class Cashu {
  static setup() {
    native.store_dart_post_cobject(NativeApi.postCObject);
    print("Cashu Setup Done");
  }

  /// Create Wallet
  Future<String> createWallet(String url) {
    var urlPointer = url.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.create_wallet(sendPort.nativePort, urlPointer);
    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Create Wallet
  Future<String> deleteWallet(String url) {
    var urlPointer = url.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.remove_wallet(sendPort.nativePort, urlPointer);
    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Create Wallet
  Future<List<dynamic>> getMints() {
    final completer = Completer<List<dynamic>>();
    final sendPort = singleCompletePort(completer);
    final res = native.get_mints(sendPort.nativePort);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Receive
  Future<String> receiveToken(String token) {
    var tokenPointer = token.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.receive_token(sendPort.nativePort, tokenPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Send
  Future<String> send(int amount, String activeMint) {
    var activeMintPointer = activeMint.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.send(sendPort.nativePort, amount, activeMintPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<List<dynamic>> decodeToken(String token) {
    var tokenPointer = token.toNativeUtf8();
    final completer = Completer<List<dynamic>>();
    final sendPort = singleCompletePort(completer);
    final res = native.decode_token(sendPort.nativePort, tokenPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<List<dynamic>> decodeInvoice(String invoice) {
    var invoicePointer = invoice.toNativeUtf8();
    final completer = Completer<List<dynamic>>();
    final sendPort = singleCompletePort(completer);
    final res = native.decode_invoice(sendPort.nativePort, invoicePointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<String> payInvoice(int amount, String invoice, String mint) {
    var invoicePointer = invoice.toNativeUtf8();
    var mintPointer = mint.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.pay_invoice(
        sendPort.nativePort, amount, invoicePointer, mintPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Receive
  Future<String> getBalances() {
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.get_balances(sendPort.nativePort);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Receive
  Future<String> getProofs() {
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.get_proofs(sendPort.nativePort);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<String> setProofs(String proofs) {
    var tokenPointer = proofs.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res = native.set_proofs(sendPort.nativePort, tokenPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  /// Receive
  Future<String> setMints(List<String> mints) {
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    String mintsStr = jsonEncode(mints);
    final res = native.set_mints(sendPort.nativePort, mintsStr.toNativeUtf8());

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<bool> checkSpendable(String encodedToken) {
    var tokenPointer = encodedToken.toNativeUtf8();
    final completer = Completer<bool>();
    final sendPort = singleCompletePort(completer);
    final res = native.check_spendable(sendPort.nativePort, tokenPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<List<dynamic>> requestMint(int amount, String mint) {
    var mintPointer = mint.toNativeUtf8();
    final completer = Completer<List<dynamic>>();
    final sendPort = singleCompletePort(completer);
    final res = native.request_mint(sendPort.nativePort, amount, mintPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  Future<String> mint(int amount, String hash, String mint) {
    var mintPointer = mint.toNativeUtf8();
    var hashPointer = hash.toNativeUtf8();
    final completer = Completer<String>();
    final sendPort = singleCompletePort(completer);
    final res =
        native.mint(sendPort.nativePort, amount, hashPointer, mintPointer);

    if (res != 1) {
      _throwError();
    }
    return completer.future;
  }

  void _throwError() {
    final length = native.last_error_length();
    final Pointer<Utf8> message = calloc.allocate(length);
    native.error_message_utf8(message, length);
    final error = message.toDartString();
    print(error);
    throw error;
  }
}
