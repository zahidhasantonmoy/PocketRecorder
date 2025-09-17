import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sos_service.dart';

class SOSSettingsScreen extends StatefulWidget {
  const SOSSettingsScreen({super.key});

  @override
  State<SOSSettingsScreen> createState() => _SOSSettingsScreenState();
}

class _SOSSettingsScreenState extends State<SOSSettingsScreen> {
  final List<String> _trustedContacts = [];
  final TextEditingController _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _addContact() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _trustedContacts.add(_contactController.text);
        _contactController.clear();
      });
      
      // In a real app, you would save this to the SOS service
      final sosService = Provider.of<SOSService>(context, listen: false);
      sosService.addTrustedContact(_contactController.text);
    }
  }

  void _removeContact(int index) {
    final contact = _trustedContacts[index];
    setState(() {
      _trustedContacts.removeAt(index);
    });
    
    // In a real app, you would remove this from the SOS service
    final sosService = Provider.of<SOSService>(context, listen: false);
    sosService.removeTrustedContact(contact);
  }

  @override
  Widget build(BuildContext context) {
    final sosService = Provider.of<SOSService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trusted Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add phone numbers or email addresses of people to notify in an emergency.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number or email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a contact';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addContact,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_trustedContacts.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.contacts,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No trusted contacts added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _trustedContacts.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text(_trustedContacts[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeContact(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _trustedContacts.isEmpty
                  ? null
                  : () {
                      sosService.sendSOSAlert(_trustedContacts);
                    },
              icon: sosService.isSendingAlert
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.emergency),
              label: Text(sosService.isSendingAlert
                  ? 'Sending Alert...'
                  : 'Test SOS Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              sosService.lastAlertMessage,
              style: const TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}