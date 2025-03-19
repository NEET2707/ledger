import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../colors.dart';
import '../main.dart';
import '../password/set_pin.dart';
import '../settings/all_account.dart';
import '../settings/all_payment.dart';
import '../settings/currencymanager.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

import '../sharedpreferences.dart';



class textlink {
  static const String tblAccount = "Account";
  static String accountId = "account_id";
  static String accountName = "account_name";
  static String accountContact = "account_contact";
  static String accountEmail = "account_email";
  static String accountDescription = "account_description";
  static String accountImage = "image";
  static String accountTotal = "account_total";
  static String accountDateAdded = "date_added";
  static String accountDateModified = "date_modified";
  static String accountIsDelete = "is_delete";

// Transaction table field names
  static String tbltransaction = "Transaction";
  static String transactionAccountId = "account_id";
  static String transactionId = "transaction_id";
  static String transactionAmount = "transaction_amount";
  static String transactionDate = "transaction_date";
  static String transactionIsDueReminder = "is_due_reminder";
  static String transactionReminderDate = "reminder_date";
  static String transactionIsCredited = "is_credited";
  static String transactionNote = "transaction_note";
  static String transactionDateAdded = "date_added";
  static String transactionDateModified = "date_modified";
  static String transactionIsDelete = "is_delete";
}


class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool isToggled = false;

  void onToggleSwitch(bool value) {
    if (value) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetPinScreen()),
      );
    }
    if (value == false) {
      SharedPreferenceHelper.deleteSpecific(prefKey: PrefKey.pin);
      setState(() {
        isToggled = value;
      });
    }
  }

  Future<void> _getSavedPin() async {
    String? savedPin = await SharedPreferenceHelper.get(prefKey: PrefKey.pin);

    setState(() {
      isToggled = savedPin != null && savedPin.isNotEmpty;
    });
  }

  Future<void> ispinsave() async {
    String? savedPin = SharedPreferenceHelper.get(
        prefKey: PrefKey.pin) as String?;
    isToggled = savedPin != null ? true : false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _getSavedPin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            icon: Icons.account_circle,
            title: "All Account",
            subtitle: "Manage All Account - Edit/Delete",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllAccountsPage(),
                ),
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.payment,
            title: "All Payment",
            subtitle: "Manage All Payment - Filter/Edit/Delete",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllPaymentPage(),
                ),
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.lock,
            title: "Enter PIN",
            subtitle: "Secure your app with a PIN.",
            leadingIcon: Icons.lock,
            // Set leadingIcon to use the lock icon
            trailingWidget: Switch(
              value: isToggled, // Current state of the switch
              onChanged: onToggleSwitch, // Callback to toggle the switch
            ),
          ),
          _buildSettingsCard(
            icon: Icons.cloud_upload,
            title: "Ledger Book Backup",
            subtitle: "Backup/Restore Your Ledger Book Entries",
          ),
          _buildSettingsCard(
            icon: Icons.currency_exchange,
            title: "Change Currency",
            subtitle: "Select Currency",
            onTap: () {
              showCurrencyPicker(
                context: context,
                showFlag: true,
                showCurrencyName: true,
                showCurrencyCode: true,
                onSelect: (Currency currency) {
                  Provider.of<CurrencyManager>(context, listen: false)
                      .updateCurrency(currency.symbol);
                },
              );
            },

          ),
          _buildSettingsCard(
            icon: Icons.phone,
            title: "Contact Us",
            subtitle: "Communication Details",
            onTap: () {
              _showCompensationDetailsDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    void Function()? onTap,
    Widget? trailingWidget,
    IconData? leadingIcon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        // Use custom icon if provided, fallback to default
        leading: Icon(
          leadingIcon ?? icon,
          size: 40,
          color: Colors.black54,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: trailingWidget,
        // Optional trailing widget (e.g., switch, arrow)
        onTap: onTap,
      ),
    );
  }


  Future<void> _launchUrl(String links) async {
    final Uri _url = Uri.parse(links);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  void _showCompensationDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ledger Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('We are thanking you for using this app.'),
              SizedBox(height: 8),
              Text('Write us on'),
              GestureDetector(
                onTap: () {
                  _launchUrl("mailto:ledgerbook@gnhub.com");
                },
                child: Text(
                  'ledgerbook@gnhub.com',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: 8),
              Text('Generation Next'),
              GestureDetector(
                onTap: () {
                  _launchUrl("http://www.gnhub.com/");
                },
                child: Text(
                  'http://www.gnhub.com/',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _launchUrl('tel:+912612665403');
                },
                child: Text(
                  '+91 261 2665403',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
