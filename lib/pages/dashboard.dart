import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:front/config.dart';
import 'package:front/pages/acceuil.dart';
import 'package:front/pages/hive_details_screen.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final double offsetY;

  const CustomFloatingActionButtonLocation({this.offsetY = 0.0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset endFloatOffset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(endFloatOffset.dx, endFloatOffset.dy - offsetY);
  }
}

class Dashboard extends StatefulWidget {
  final String token;
  const Dashboard({required this.token, Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String userId;
  late TextEditingController hiveTitleController;
  List<dynamic>? items;
  bool isLoading = false;
  bool isDeleting = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    hiveTitleController = TextEditingController();
    final Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userId = jwtDecodedToken['_id'] ?? '';
    _loadHives();
  }

  @override
  void dispose() {
    hiveTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadHives() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$getHiVeList?userId=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            items = jsonResponse['success'] ?? [];
            isLoading = false;
          });
        }
      } else {
        _showErrorSnackbar('Failed to load hives: ${response.statusCode}');
      }
    } on TimeoutException {
      _showErrorSnackbar('Request timed out');
    } on PlatformException catch (e) {
      _showErrorSnackbar('Platform error: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> addHive() async {
    if (hiveTitleController.text.isEmpty) {
      _showErrorSnackbar('Please enter a hive title');
      return;
    }

    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(addhive),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "title": hiveTitleController.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        hiveTitleController.clear();
        if (mounted) Navigator.pop(context);
        await _loadHives();
      } else {
        _showErrorSnackbar(jsonResponse['message'] ?? 'Failed to add hive');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteHive(id);
    }
  }

  Future<void> _deleteHive(String id) async {
    if (!mounted) return;

    setState(() => isDeleting = true);
    try {
      final response = await http.post(
        Uri.parse(deleteHive),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true) {
          _showSuccessSnackbar('Hive deleted successfully');
          await _loadHives();
        } else {
          _showErrorSnackbar(jsonResponse['message'] ?? 'Failed to delete hive');
        }
      } else {
        _showErrorSnackbar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _scanQRCode() async {
    try {
      final scannedData = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scan Hive QR Code'),
              backgroundColor: Colors.amber,
            ),
            body: MobileScanner(
              controller: MobileScannerController(
                facing: CameraFacing.back,
                torchEnabled: false,
              ),
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && mounted) {
                  Navigator.pop(context, barcodes.first.rawValue);
                }
              },
            ),
          ),
        ),
      );

      if (scannedData != null && mounted) {
        _processScannedQR(scannedData);
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar('Camera permission denied: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('Failed to scan QR code: ${e.toString()}');
    }
  }

  void _processScannedQR(String data) {
    if (data.startsWith('RUCHE_')) {
      final hiveId = data.substring(5);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HiveDetailScreen(
            hiveId: hiveId,
            hiveTitle: 'Scanned Hive',
            token: widget.token,
          ),
        ),
      );
    } else {
      _showErrorSnackbar('Invalid QR code format');
    }
  }

  Future<void> _showAddHiveDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Hive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hiveTitleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter a title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : addHive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Acceuil()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHiveDialog,
        backgroundColor: const Color.fromARGB(255, 255, 216, 97),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Hive',
      ),
      floatingActionButtonLocation: const CustomFloatingActionButtonLocation(offsetY: 90.0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60.0, left: 30.0, right: 30.0, bottom: 30.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'DASHBOARD:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadHives,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      spreadRadius: 5,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: isLoading && (items == null || items!.isEmpty)
                      ? const Center(child: CircularProgressIndicator())
                      : items == null
                          ? const Center(child: Text("No Hives found."))
                          : items!.isEmpty
                              ? const Center(child: Text("No Hives found. Add a new hive to get started!"))
                              : ListView.builder(
                                  itemCount: items!.length,
                                  itemBuilder: (context, index) {
                                    final item = items![index];
                                    if (item == null || item['_id'] == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Slidable(
                                      key: ValueKey(item['_id']),
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        children: [
                                          SlidableAction(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            icon: Icons.delete,
                                            label: 'Delete',
                                            onPressed: (_) => _confirmDelete(
                                              item['_id'],
                                              item['title'] ?? 'Untitled Hive',
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: ListTile(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => HiveDetailScreen(
                                                  hiveId: item['_id'],
                                                  hiveTitle: item['title'] ?? 'Untitled Hive',
                                                  token: widget.token,
                                                ),
                                              ),
                                            );
                                          },
                                          title: Text(
                                            item['title'] ?? 'Untitled Hive',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  spreadRadius: 5,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.home,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
                IconButton(
                  onPressed: _scanQRCode,
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
                IconButton(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(
                    Icons.logout,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}