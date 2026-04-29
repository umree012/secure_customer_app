import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure Customers App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const CustomersPage(),
    );
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  // FOR WINDOWS DESKTOP - use localhost
  final String baseUrl = 'http://localhost:3000';

  bool isLoading = false;
  String apiKey = '';
  String statusMessage = 'Press the button to generate API key';
  List<dynamic> customers = [];

  Future<void> generateApiKey() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Generating API key...';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-api-key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'app_name': 'Flutter Lab App'}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          apiKey = data['apiKey'];
          statusMessage = '✅ API key generated successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key Generated! Now press Fetch Data')),
        );
      } else {
        setState(() {
          statusMessage = data['message'] ?? 'Failed to generate API key';
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Connection error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Make sure backend is running on port 3000')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCustomers() async {
    if (apiKey.isEmpty) {
      setState(() {
        statusMessage = '⚠️ Please generate API key first!';
      });
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = 'Fetching customers from MySQL...';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers'),
        headers: {'x-api-key': apiKey},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          customers = data['data'];
          statusMessage = '✅ Loaded ${customers.length} customers successfully!';
        });
      } else {
        setState(() {
          statusMessage = data['message'] ?? 'Request failed';
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Customers App'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'API Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        color: statusMessage.contains('✅') ? Colors.green :
                        statusMessage.contains('⚠️') ? Colors.orange : Colors.grey[700],
                      ),
                    ),
                    if (apiKey.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔑 API Key: ${apiKey.substring(0, 8)}...${apiKey.substring(apiKey.length - 4)}',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : generateApiKey,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Generate Key'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : fetchCustomers,
                    icon: const Icon(Icons.download),
                    label: const Text('Fetch Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: customers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No customer data loaded yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate API key → Fetch Data',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Text(
                          customer['id'].toString(),
                          style: const TextStyle(color: Colors.indigo),
                        ),
                      ),
                      title: Text(
                        customer['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(customer['address']),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      isThreeLine: false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}