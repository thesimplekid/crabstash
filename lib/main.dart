import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cashu/cashu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color_schemes.g.dart';
import 'screens/home.dart';
import 'screens/lightning.dart';
import 'screens/settings.dart';
import 'shared/models/transaction.dart';
import 'shared/models/token.dart';
import 'shared/models/invoice.dart';

void main() => runApp(const MyApp());

class AppData {}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashu',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'Cashu Wallet'),
    );
  }

  const MyApp({Key? key}) : super(key: key);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  Cashu cashu = Cashu();

  Map<String, int> mints = {};
  int balance = 0;
  String? activeMint;
  int activeBalance = 0;

  TokenData? tokenData;

  List<Transaction> pendingTransactions = List.empty(growable: true);
  List<Transaction> transactions = List.empty(growable: true);

  List<Invoice> pendingInvoices = List.empty(growable: true);
  List<Invoice> invoices = List.empty(growable: true);

  late List<Widget> _widgetOptions;

  late Lightning _lightningTab;
  late Home _homeTab;
  late Settings _settingsTab;

  @override
  void initState() {
    super.initState();
    Cashu.setup();
    _loadProofs();
    // _mintsFromProof();
    _loadMints();

    // Load transaction
    _loadTransactions();
    // Load Invoices
    _loadInvoices();

    _getActiveMint();

    // Set balances
    _getBalances();
    // Set Balance
    _getBalance();
  }

  _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _lightningTab = Lightning(
      cashu: cashu,
      activeWallet: activeMint,
      wallets: mints,
      pendingInvoices: pendingInvoices,
      invoices: invoices,
      setProofs: _setProofs,
      setInvoices: setInvoices,
    );

    _homeTab = Home(
      balance: balance,
      activeBalance: activeBalance,
      activeMint: activeMint,
      tokenData: tokenData,
      pendingTransactions: pendingTransactions,
      transactions: transactions,
      mints: mints,
      decodeToken: _decodeToken,
      clearToken: clearToken,
      receiveToken: receiveToken,
      send: sendToken,
      addMint: _addNewMint,
      checkTransactionStatus: _checkTransactionStatus,
    );

    _settingsTab = Settings(
      mints: mints,
      addMint: _addNewMint,
      removeMint: removeMint,
      activeMint: activeMint,
      setActiveMint: _setActiveMint,
    );

    _widgetOptions = <Widget>[
      _lightningTab,
      _homeTab,
      _settingsTab,
    ];
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Lightning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> _getBalances() async {
    final gotBalances = await cashu.getBalances();
    Map<String, dynamic> bal = json.decode(gotBalances);
    setState(() {
      mints = bal.cast<String, int>();
    });
    _getBalance();
  }

  /// Get total balance of all mints
  void _getBalance() {
    int bal = mints.values.fold(0, (acc, value) => acc + value);

    setState(() {
      balance = bal;
      if (activeMint != null) {
        activeBalance = mints[activeMint] ?? 0;
      }
    });
  }

  Future<TokenData> _decodeToken(String token) async {
    final data = await cashu.decodeToken(token);
    TokenData r = TokenData(
      encodedToken: token,
      mint: data[0],
      amount: data[1],
      memo: data.length > 2 ? data[2] : null,
    );

    setState(() {
      tokenData = r;
    });

    return r;
  }

  Future<bool> _checkTransactionStatus(Transaction transaction) async {
    final spendable =
        await cashu.checkSpendable(transaction.token.encodedToken);

    if (spendable == false) {
      setState(() {
        pendingTransactions.removeWhere(
            (t) => t.token.encodedToken == transaction.token.encodedToken);
        if (!transactions.any(
            (t) => t.token.encodedToken == transaction.token.encodedToken)) {
          transaction.status = TransactionStatus.sent;
          transactions.add(transaction);
        }
      });
    }

    await _saveTransactions();
    await _loadTransactions();
    return spendable;
  }

  void clearToken() async {
    setState(() {
      tokenData = null;
    });
  }

  void receiveToken() async {
    if (tokenData?.encodedToken != null) {
      String proofs = await cashu.receiveToken(tokenData!.encodedToken);
      // REVIEW: how does this handle a failed token that shouldned be added
      setState(() {
        Transaction transaction = Transaction(
            status: TransactionStatus.received,
            time: DateTime.now(),
            token: tokenData!);
        transactions.add(transaction);
      });

      await _saveTransactions();
      await _setProofs(proofs);
      await _getBalances();
    }
  }

  Future<String> sendToken(int amount) async {
    if (activeMint == null) {
      return "";
    }

    String token = await cashu.send(amount, activeMint!);
    TokenData tokenData = await _decodeToken(token);
    setState(() {
      Transaction transaction = Transaction(
          status: TransactionStatus.pending,
          time: DateTime.now(),
          token: tokenData);
      pendingTransactions.add(transaction);
    });
    await _saveTransactions();

    // Get Proofs from rust
    // Since sending is handled by rust we dont know what proof(s) is spend directly
    // So we just get the current list of proofs from rust and overwrite the proof list
    String proofs = await cashu.getProofs();
    await _setProofs(proofs);
    await _getBalances();
    return (token.toString());
  }

  // Get Proofs
  Future<String?> _getActiveMint() async {
    final prefs = await SharedPreferences.getInstance();
    String? mint = prefs.getString('active_mint');
    setState(() {
      activeMint = mint;
    });
    await _getBalances();
    _getBalance();

    return mint;
  }

  // Set active in storage
  Future<void> _setActiveMint(String? newActiveMint) async {
    final prefs = await SharedPreferences.getInstance();

    if (activeMint == null) {
      prefs.remove('active_mint');
    } else {
      prefs.setString('active_mint', newActiveMint!);
    }

    setState(() {
      activeMint = newActiveMint;
    });
    await _getBalances();
    _getBalance();
  }

  // Get Proofs
  Future<String> _getProofs() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('proofs') ?? "{}");
  }

  // Set proofs in storage
  Future<void> _setProofs(String proofs) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('proofs', proofs);
    await _getBalances();
    _getBalance();
  }

  /// Load Proofs  from disk into rust
  Future<void> _loadProofs() async {
    String proofs = await _getProofs();
    await cashu.setProofs(proofs);
    await _getBalances();
    _getBalance();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionsJson = prefs.getStringList('transactions') ?? [];

    List<Transaction> loadedTransactions = transactionsJson
        .map((jsonString) => json.decode(jsonString))
        .map((jsonMap) => Transaction.fromJson(jsonMap))
        .toList();

    List<String> pendingTransactionsJson =
        prefs.getStringList('pending_transactions') ?? [];

    List<Transaction> loadedPendingTransactions = pendingTransactionsJson
        .map((jsonString) => json.decode(jsonString))
        .map((jsonMap) => Transaction.fromJson(jsonMap))
        .toList();

    setState(() {
      transactions = loadedTransactions;
      pendingTransactions = loadedPendingTransactions;
    });
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionsJson = transactions
        .map((transaction) => transaction.toJson())
        .map((jsonMap) => json.encode(jsonMap))
        .toList();

    await prefs.setStringList('transactions', transactionsJson);

    List<String> pendingTransactionsJson = pendingTransactions
        .map((transaction) => transaction.toJson())
        .map((jsonMap) => json.encode(jsonMap))
        .toList();

    await prefs.setStringList('pending_transactions', pendingTransactionsJson);
  }

  void setInvoices(
      List<Invoice> passedPendingInvoices, List<Invoice> passedInvoices) async {
    setState(() {
      invoices = passedInvoices;
      pendingInvoices = passedPendingInvoices;
    });
    await _saveInvoices();
  }

  Future<void> _loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> invoicesJson = prefs.getStringList('invoices') ?? [];

    List<Invoice> loadedInvoices = invoicesJson
        .map((jsonString) => json.decode(jsonString))
        .map((jsonMap) => Invoice.fromJson(jsonMap))
        .toList();

    List<String> pendingInvoicesJson =
        prefs.getStringList('pending_invoices') ?? [];

    List<Invoice> loadedPendingInvoices = pendingInvoicesJson
        .map((jsonString) => json.decode(jsonString))
        .map((jsonMap) => Invoice.fromJson(jsonMap))
        .toList();

    setState(() {
      invoices = loadedInvoices;
      pendingInvoices = loadedPendingInvoices;
    });
  }

  Future<void> _saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> invoicesJson = invoices
        .map((invoice) => invoice.toJson())
        .map((jsonMap) => json.encode(jsonMap))
        .toList();

    await prefs.setStringList('invoices', invoicesJson);

    List<String> pendingInvoicesJson = pendingInvoices
        .map((invoice) => invoice.toJson())
        .map((jsonMap) => json.encode(jsonMap))
        .toList();

    await prefs.setStringList('pending_invoices', pendingInvoicesJson);
  }

  /// Get Mints from disk
  Future<List<String>> _getMints() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('mints') ?? []);
  }

  // Save mints to disk
  Future<void> _setMints(Map<String, int> ms) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> mintList = ms.keys.toList();
    prefs.setStringList('mints', mintList);
    await cashu.setMints(mintList);

    if (activeMint == null) {
      if (mintList.isNotEmpty) {
        await _setActiveMint(mintList[0]);
      }
    }

    setState(() {
      mints = ms;
    });
  }

  /// Load mints from disk into rust
  Future<void> _loadMints() async {
    List<String> gotMints = await _getMints();
    // _setMints(mints);
    await cashu.setMints(gotMints);
    final zeroValues = List.filled(gotMints.length, 0);
    setState(() {
      mints = Map.fromIterables(gotMints, zeroValues);
    });
  }

  Future<void> removeMint(String mintUrl) async {
    // Should only allow if balance is 0
    await _getBalances();

    if (mints[mintUrl] == 0) {
      // Remove from rust
      await cashu.deleteWallet(mintUrl);
      mints.remove(mintUrl);
      await _setMints(mints);

      if (mintUrl == activeMint) {
        String? newActive;

        List<String> mintUrls = mints.keys.toList();

        if (mints.isNotEmpty) {
          newActive = mintUrls[0];
        }

        _setActiveMint(newActive);
      }
    }
  }

  Future<void> _addNewMint(String mintUrl) async {
    // TODO: Should handle error connecting to mint
    await cashu.createWallet(mintUrl);

    mints[mintUrl] = 0;
    await _setMints(mints);
  }
}
