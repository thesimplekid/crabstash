import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cashu/cashu.dart';

import '../screens/create_invoice.dart';
import '../screens/pay_invoice.dart';
import '../shared/models/invoice.dart';
import '../shared/utils.dart';

class Lightning extends StatefulWidget {
  final Cashu cashu;
  final String? activeWallet;
  final Map<String, int> wallets;
  final List<Invoice> pendingInvoices;
  final List<Invoice> invoices;
  final Function setProofs;
  final Function setInvoices;

  const Lightning({
    super.key,
    required this.activeWallet,
    required this.wallets,
    required this.cashu,
    required this.pendingInvoices,
    required this.invoices,
    required this.setProofs,
    required this.setInvoices,
  });

  @override
  State<Lightning> createState() => _LightningState();
}

class _LightningState extends State<Lightning> {
  _LightningState();
  int amountToSend = 0;
  String? mint;
  Invoice? invoice;
  final receiveController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wallets.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Must set Mint",
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      );
    }

    mint ??= widget.activeWallet;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.pendingInvoices.isNotEmpty)
                    const Text(
                      "Pending Invoices",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (widget.pendingInvoices.isNotEmpty)
                    Flexible(
                      child: InvoiceList(
                        invoices: widget.pendingInvoices,
                        checkSpendable: mintInvoice,
                        setProofs: widget.setProofs,
                        showInvoice: _createInvoiceDialog,
                      ),
                    ),
                  const Text(
                    "Invoices",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: InvoiceList(
                      invoices: widget.invoices,
                      checkSpendable: null,
                      setProofs: widget.setProofs,
                      showInvoice: _createInvoiceDialog,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 70),
                    ),
                    onPressed: () {
                      if (widget.activeWallet != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateInvoice(
                              cashu: widget.cashu,
                              mints: widget.wallets,
                              activeMint: widget.activeWallet!,
                              pendingInvoices: widget.pendingInvoices,
                              invoices: widget.invoices,
                              setInvoices: widget.setInvoices,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Create Invoice'),
                  ),
                ),
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 70),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayInvoice(
                            activeMint: widget.activeWallet,
                            cashu: widget.cashu,
                            mints: widget.wallets,
                            setProofs: widget.setProofs,
                            setInvoices: widget.setInvoices,
                          ),
                        ),
                      );
                    },
                    child: const Text('Pay Invoice'),
                  ),
                ),
              ], // Bottom row children
            ), // Bottom Row
          ], // body children
        ), // Body column
      ),
    );
  } // Build widget

  Future<Invoice?> decodeInvoice(String encodedInvoice) async {
    final data = await widget.cashu.decodeInvoice(encodedInvoice);
    Invoice newInvoice = Invoice(
      amount: data[0],
      invoice: encodedInvoice,
      hash: data[1],
      mintUrl: mint!,
      status: InvoiceStatus.pending,
      time: DateTime.now(),
      memo: data.length > 2 ? data[2] : null,
    );

    setState(() {
      invoice = newInvoice;
    });

    return invoice;
  }

  void mintInvoice(Invoice invoice) async {
    String proofs =
        await widget.cashu.mint(invoice.amount, invoice.hash, invoice.mintUrl);

    if (!proofs.startsWith("Error")) {
      setState(() {
        // HACK: There are many places where error handling needs to be improved
        // This is one of them
        widget.pendingInvoices.removeWhere((i) => i.hash == invoice.hash);
        invoice.status = InvoiceStatus.received;
        widget.invoices.add(invoice);
      });
      await widget.setProofs(proofs);
      await widget.setInvoices(widget.pendingInvoices, widget.invoices);
    }
    // TODO: update proofs
  }

  void _createInvoiceDialog(
      int amount, String mintUrl, Invoice? passedInvoice) async {
    late Invoice displayInvoice;
    if (passedInvoice == null) {
      // TODO: Make a type for this
      List<dynamic> result = await widget.cashu.requestMint(amount, mintUrl);
      Invoice invoice = Invoice(
          status: InvoiceStatus.pending,
          invoice: result[0],
          hash: result[1].toString(),
          time: DateTime.now(),
          amount: amount,
          mintUrl: mintUrl);
      displayInvoice = invoice;
      setState(() {
        widget.pendingInvoices.add(invoice);
      });

      await widget.setInvoices(widget.pendingInvoices, widget.invoices);
    } else {
      displayInvoice = passedInvoice;
    }
    if (context.mounted) {
      // TODO Decode invoice
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Send'),
            content: SizedBox(
              height: 200,
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: SingleChildScrollView(
                      child: Text(displayInvoice.invoice!),
                    ),
                  ),
                  Wrap(
                    children: [
                      Text(
                        "Invoice ${displayInvoice.amount.toString()}",
                      ), // Mint Text
                    ],
                  ), // Wrap
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: displayInvoice.invoice));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                      ),
                    );
                  }
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final Function? checkSpendable;
  final Function setProofs;
  final Function showInvoice;

  const InvoiceList(
      {super.key,
      required this.setProofs,
      required this.invoices,
      required this.checkSpendable,
      required this.showInvoice});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: invoices.length,
        itemBuilder: (BuildContext context, int index) {
          IconData statusIcon = Icons.pending;
          Invoice invoice = invoices[index];
          Text amountText;
          switch (invoice.status) {
            case InvoiceStatus.sent:
              statusIcon = Icons.call_made;
              amountText = Text(
                "${invoice.amount.toString()} sats",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w100,
                  color: Colors.red,
                ),
              );
              break;
            case InvoiceStatus.received:
              statusIcon = Icons.call_received;
              amountText = Text(
                "${invoice.amount.toString()} sats",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w100,
                  color: Colors.green,
                ),
              );
              break;
            default:
              amountText = Text(
                "${invoice.amount.toString()} sats",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w100,
                  color: Colors.grey,
                ),
              );
          }
          return GestureDetector(
            onTap: () => {
              {showInvoice(invoice.amount, invoice.mintUrl, invoice)},
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon),
                if (checkSpendable != null)
                  GestureDetector(
                    onTap: () {
                      checkSpendable!(invoice);
                    },
                    child: const Icon(Icons.refresh),
                  ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      invoice.memo ?? "No memo",
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      formatTimeAgo(invoice.time),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w100,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                amountText
              ],
            ),
          );
        },
      ),
    );
  }
}
