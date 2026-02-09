import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

class APITestingPage extends StatefulWidget {
  const APITestingPage({super.key});

  @override
  State<APITestingPage> createState() => _APITestingPageState();
}

class _APITestingPageState extends State<APITestingPage> with SingleTickerProviderStateMixin {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'default_key';

  late TabController _tabController;
  late PageController _responsePageController;

  bool isLoading = false;
  String responseText = '';
  String errorText = '';

  // Auth state
  String _accessToken = '';
  String _refreshToken = '';

  // Form states - Auth
  final _authEmailController = TextEditingController(text: "john@example.com");
  final _authPasswordController = TextEditingController(text: "password123");

  // Form states - Users
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userIdController = TextEditingController();

  // Form states - Products
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();

  // Form states - Testing
  final _delayController = TextEditingController(text: '0');
  final _errorRateController = TextEditingController(text: '0');
  String _simulateError = '';

  File? selectedFile;

  // File preview states
  List<FileItem> uploadedFiles = [];
  String? selectedFileIdForDownload;
  Uint8List? downloadedFileData;
  String? downloadedFileName;

  late final INetworkClient networkClient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _responsePageController = PageController();
    networkClient = NetworkClient(
      /*retry: NetworkRetry(
        component: SnackbarRetryComponent(context: context),
        hideDuration: Duration(seconds: 2),
      ),*/
      /*retry: NetworkRetry(
        component: BannerRetryComponent(
          context: context,
          scaffoldMessengerKey: MyApp.scaffoldMessengerKey,
          messageBuilder: (exception) {
            return 'Failed to connect to server: ${exception.message}';
          },
        ),
        hideDuration: Duration(seconds: 2),
      ),*/
      retry: NetworkRetry(
        component: BottomSheetRetryComponent(context: context, maxManualRetries: 1),

        //hideDuration: Duration(seconds: 2),
      ),
      /*retry: NetworkRetry(
        component: DialogRetryComponent(context: context),
        hideDuration: Duration(seconds: 2),
      ),*/
      adapter: DioAdapter(),
      refreshTokenHandler: (exception) async {
        if (_accessToken.isEmpty) return exception;
        try {
          final (newAccessToken, newRefreshToken, response) = await _refresh();

          exception.requestConfig?.headers?['Authorization'] = "Bearer $newAccessToken";
          return exception;
        } catch (e) {
          return exception;
        }
      },
      refreshTokenFailHandler: (exception) async {
        await _handleLogout();
      },
      config: NetworkConfig(
        baseUrl: baseUrl,
        baseHeaders: {"Content-Type": "application/json"},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
      logger: ConsoleLogger(enabled: true, minimumLevel: LogLevel.debug),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _responsePageController.dispose();
    _authEmailController.dispose();
    _authPasswordController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _userIdController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _delayController.dispose();
    _errorRateController.dispose();
    super.dispose();
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (_accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (_delayController.text != '0') {
      headers['X-Delay-Ms'] = _delayController.text;
    }

    if (_errorRateController.text != '0') {
      headers['X-Error-Rate'] = _errorRateController.text;
    }

    if (_simulateError.isNotEmpty) {
      headers['X-Simulate-Error'] = _simulateError;
    }

    return headers;
  }

  void _asyncHandleRequest(AsyncCallback callback) async {
    setState(() {
      isLoading = true;
      errorText = '';
    });
    try {
      await callback();
    } catch (error) {
      _showError(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setResponse(dynamic data) {
    setState(() {
      try {
        if (data is String) {
          responseText = data;
        } else {
          responseText = const JsonEncoder.withIndent('  ').convert(data);
        }
        errorText = '';
      } catch (e) {
        responseText = data.toString();
      }
    });
  }

  void _showError(String error) {
    setState(() {
      errorText = error;
      responseText = '';
    });
    final snackBar = SnackBar(content: Text(error), backgroundColor: Colors.red);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ============== AUTH OPERATIONS ==============

  Future<void> _handleLogin() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest(
          'auth/login',
          //extra: {'__netcore_refresh_attempted': false},
          method: HttpMethod.post,
          headers: _getHeaders(),
        ),
        body: {'email': _authEmailController.text, 'password': _authPasswordController.text},
      );

      _setResponse(response);

      if (response != null && response['Data'] != null) {
        setState(() {
          _accessToken = response['Data']['AccessToken'] ?? '';
          _refreshToken = response['Data']['RefreshToken'] ?? '';
        });
      }
    });
  }

  Future<void> _handleRefreshToken() async {
    if (_refreshToken.isEmpty) {
      _showError('No refresh token available');
      return;
    }

    _asyncHandleRequest(() async {
      final (accessToken, refreshToken, response) = await _refresh();

      _setResponse(response);

      if (response != null) {
        setState(() {
          _accessToken = accessToken ?? '';
          _refreshToken = refreshToken ?? '';
        });
      }
    });
    return;
  }

  Future<(String?, String?, dynamic response)> _refresh() async {
    final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
      request: NetworkRequest('auth/refresh', method: HttpMethod.post, headers: _getHeaders()),
      body: {'refreshToken': _refreshToken},
    );

    if (response != null && response['Data'] != null) {
      setState(() {
        _accessToken = response['Data']['AccessToken'] ?? '';
        _refreshToken = response['Data']['RefreshToken'] ?? '';
      });
      return (_accessToken, _refreshToken, response);
    }
    return (null, null, null);
  }

  Future<void> _handleLogout() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, void>(
        request: NetworkRequest('auth/logout', method: HttpMethod.post, headers: _getHeaders()  ,   extra: {'skipAuthHandling': true}, ),
      );

      _setResponse(response);

      setState(() {
        _accessToken = '';
        _refreshToken = '';
      });
    });
  }

  Future<void> _handleRevoke() async {
    if (_refreshToken.isEmpty) {
      _showError('No refresh token to revoke');
      return;
    }

    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, void>(
        request: NetworkRequest('auth/revoke', method: HttpMethod.post, headers: _getHeaders()),
        body: {'refreshToken': _refreshToken},
      );

      _setResponse(response);

      setState(() {
        _refreshToken = '';
      });
    });
  }

  // ============== USER OPERATIONS ==============

  Future<void> _handleGetUsers() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('users', method: HttpMethod.get, headers: _getHeaders()),
      );

      _setResponse(response);
    });
  }

  Future<void> _handleGetUser() async {
    if (_userIdController.text.isEmpty) {
      _showError('User ID required');
      return;
    }

    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('users/${_userIdController.text}', method: HttpMethod.get, headers: _getHeaders()),
      );

      _setResponse(response);
    });
  }

  Future<void> _handleCreateUser() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('users', method: HttpMethod.post, headers: _getHeaders()),
        body: {
          'name': _userNameController.text,
          'email': _userEmailController.text,
          'password': _userPasswordController.text,
        },
      );

      _setResponse(response);
    });
  }

  Future<void> _handleUpdateUser() async {
    if (_userIdController.text.isEmpty) {
      _showError('User ID required');
      return;
    }

    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('users/${_userIdController.text}', method: HttpMethod.put, headers: _getHeaders()),
        body: {'name': _userNameController.text, 'email': _userEmailController.text},
      );

      _setResponse(response);
    });
  }

  Future<void> _handleDeleteUser() async {
    if (_userIdController.text.isEmpty) {
      _showError('User ID required');
      return;
    }

    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('users/${_userIdController.text}', method: HttpMethod.delete, headers: _getHeaders()),
      );

      _setResponse(response);
    });
  }

  Future<void> _handleGetUserInfo() async {
    if (_userIdController.text.isEmpty) {
      _showError('User ID required');
      return;
    }

    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('users/${_userIdController.text}/info', method: HttpMethod.get, headers: _getHeaders()),
      );

      _setResponse(response);
    });
  }

  // ============== PRODUCT OPERATIONS ==============

  Future<void> _handleGetProducts() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('products', method: HttpMethod.get, headers: _getHeaders()),
      );

      _setResponse(response);
    });
  }

  Future<void> _handleCreateProduct() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('products', method: HttpMethod.post, headers: _getHeaders()),
        body: {
          'name': _productNameController.text,
          'description': 'Test Product',
          'price': double.parse(_productPriceController.text),
          'stock': 10,
          'imageUrl': '',
        },
      );

      _setResponse(response);
    });
  }

  // ============== FILE OPERATIONS ==============

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _handleFileUpload() async {
    if (selectedFile == null) {
      _showError('No file selected');
      return;
    }

    _asyncHandleRequest(() async {
      /*  try {
        final uri = Uri.parse('${baseUrl}files/upload');
        final request = http.MultipartRequest('POST', uri);

        request.files.add(
          await http.MultipartFile.fromPath('file', selectedFile!.path),
        );

        if (_accessToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_accessToken';
        }

        if (_delayController.text != '0') {
          request.headers['X-Delay-Ms'] = _delayController.text;
        }

        if (_errorRateController.text != '0') {
          request.headers['X-Error-Rate'] = _errorRateController.text;
        }

        if (_simulateError.isNotEmpty) {
          request.headers['X-Simulate-Error'] = _simulateError;
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

        _setResponse(jsonResponse);

        if (response.statusCode == 200 && jsonResponse['data'] != null) {
          setState(() {
            selectedFile = null;
          });
          await _handleGetFiles();
        }
      } catch (e) {
        _showError('Upload error: $e');
      }*/
    });
  }

  Future<void> _handleGetFiles() async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, Map<String, dynamic>>(
        request: NetworkRequest('files', method: HttpMethod.get, headers: _getHeaders()),
      );

      _setResponse(response);

      if (response != null && response['Data'] != null) {
        final filesList = response['Data'] as List;
        setState(() {
          uploadedFiles = filesList.map((file) => FileItem.fromJson(file as Map<String, dynamic>)).toList();
          selectedFileIdForDownload = null;
          downloadedFileData = null;
          downloadedFileName = null;
        });
      }
    });
  }

  Future<void> _downloadFile(String fileId) async {
    _asyncHandleRequest(() async {
      /*  try {
        final uri = Uri.parse('${baseUrl}files/$fileId/download');
        final request = http.Request('GET', uri);

        if (_accessToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_accessToken';
        }

        final response = await request.send();

        if (response.statusCode == 200) {
          final fileBytes = await response.stream.toBytes();
          final fileItem = uploadedFiles.firstWhere((f) => f.id == fileId);

          setState(() {
            downloadedFileData = fileBytes;
            downloadedFileName = fileItem.originalFileName;
            selectedFileIdForDownload = fileId;
            responseText =
                'File downloaded successfully!\nFile: ${fileItem.originalFileName}\nSize: ${(fileItem.size / 1024).toStringAsFixed(2)} KB\nType: ${fileItem.contentType}';
            errorText = '';
          });
        } else {
          _showError('Failed to download file');
        }
      } catch (e) {
        _showError('Download error: $e');
      }*/
    });
  }

  Future<void> _deleteFile(String fileId) async {
    _asyncHandleRequest(() async {
      final response = await networkClient.send<Map<String, dynamic>, void>(
        request: NetworkRequest('files/$fileId', method: HttpMethod.delete, headers: _getHeaders()),
      );

      _setResponse(response);
      await _handleGetFiles();
    });
  }

  // ============== UI BUILDERS ==============

  Widget _buildAuthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Authentication', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(_authEmailController, 'Email', TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField(_authPasswordController, 'Password', TextInputType.text, true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildButton('Login', _handleLogin)),
              const SizedBox(width: 8),
              Expanded(
                child: _buildButton(
                  'Refresh',
                  _handleRefreshToken,
                  enabled: _refreshToken.isNotEmpty,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildButton('Logout', _handleLogout, enabled: _accessToken.isNotEmpty, color: Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildButton('Revoke', _handleRevoke, enabled: _refreshToken.isNotEmpty, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTokenDisplay('Access Token', _accessToken),
          const SizedBox(height: 12),
          _buildTokenDisplay('Refresh Token', _refreshToken),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('User Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(_userIdController, 'User ID'),
          const SizedBox(height: 12),
          _buildTextField(_userNameController, 'Name'),
          const SizedBox(height: 12),
          _buildTextField(_userEmailController, 'Email', TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField(_userPasswordController, 'Password', TextInputType.text, true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildButton('Get All', _handleGetUsers)),
              const SizedBox(width: 8),
              Expanded(child: _buildButton('Get One', _handleGetUser)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildButton('Create', _handleCreateUser, color: Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildButton('Update', _handleUpdateUser, color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildButton('Delete', _handleDeleteUser, color: Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildButton('Get Info', _handleGetUserInfo, color: Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Product Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(_productNameController, 'Product Name'),
          const SizedBox(height: 12),
          _buildTextField(_productPriceController, 'Product Price', TextInputType.number),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildButton('Get Products', _handleGetProducts)),
              const SizedBox(width: 8),
              Expanded(child: _buildButton('Create', _handleCreateProduct, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('File Operations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // File picker
          GestureDetector(
            onTap: _selectFile,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    selectedFile?.path.split('/').last ?? 'Click to select file',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildButton('Upload', _handleFileUpload, enabled: selectedFile != null, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildButton('Get Files', _handleGetFiles)),
            ],
          ),
          // Files list
          if (uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Your Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uploadedFiles.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final file = uploadedFiles[index];
                  return ListTile(
                    leading: Icon(_getFileIcon(file.contentType), color: Colors.blue),
                    title: Text(file.originalFileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB', style: const TextStyle(fontSize: 12)),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(child: const Text('Download'), onTap: () => _downloadFile(file.id)),
                        PopupMenuItem(child: const Text('Delete'), onTap: () => _deleteFile(file.id)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.contains('image')) return Icons.image;
    if (contentType.contains('video')) return Icons.video_library;
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('word') || contentType.contains('document')) return Icons.description;
    if (contentType.contains('sheet') || contentType.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Widget _buildTestingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Testing Parameters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Delay (ms)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTextField(_delayController, 'Delay in milliseconds', TextInputType.number),
          const SizedBox(height: 4),
          const Text('Simulates network delay', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('Error Rate (%)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTextField(_errorRateController, 'Error probability (0-100)', TextInputType.number),
          const SizedBox(height: 4),
          const Text('Random error probability', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('Simulate Error', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildErrorDropdown(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ How to use:',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                ),
                SizedBox(height: 8),
                Text(
                  '• Set delay to test loading states',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                Text(
                  '• Set error rate to simulate random failures',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                Text(
                  '• Select specific error to test error handling',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                Text(
                  '• These settings apply to all subsequent requests',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  ]) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed, {bool enabled = true, Color color = Colors.blue}) {
    return ElevatedButton(
      onPressed: (enabled && !isLoading) ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildErrorDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      initialValue: _simulateError.isEmpty ? null : _simulateError,
      items: const [
        DropdownMenuItem(value: '', child: Text('None')),
        DropdownMenuItem(value: '500', child: Text('500 Server Error')),
        DropdownMenuItem(value: '401', child: Text('401 Unauthorized')),
        DropdownMenuItem(value: '404', child: Text('404 Not Found')),
        DropdownMenuItem(value: 'timeout', child: Text('Timeout')),
        DropdownMenuItem(value: 'network', child: Text('Network Error')),
      ],
      onChanged: (value) {
        setState(() {
          _simulateError = value ?? '';
        });
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTokenDisplay(String label, String token) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 4),
          Text(
            token.isEmpty
                ? 'Not available'
                : token.length > 50
                ? '${token.substring(0, 50)}...'
                : token,
            style: TextStyle(fontSize: 11, color: token.isEmpty ? Colors.grey : Colors.black, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLoading
                    ? Icons.hourglass_empty
                    : errorText.isNotEmpty
                    ? Icons.error
                    : responseText.isNotEmpty
                    ? Icons.check_circle
                    : Icons.info,
                color: isLoading
                    ? Colors.orange
                    : errorText.isNotEmpty
                    ? Colors.red
                    : responseText.isNotEmpty
                    ? Colors.green
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                isLoading
                    ? 'Loading...'
                    : errorText.isNotEmpty
                    ? 'Error'
                    : responseText.isNotEmpty
                    ? 'Response'
                    : 'No Response Yet',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // File preview section
          if (downloadedFileData != null && downloadedFileName != null) ...[
            Divider(color: Colors.grey[300]),
            const Text('File Preview:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            _buildFilePreview(),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
          ],
          // JSON Response section
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                errorText.isNotEmpty
                    ? errorText
                    : responseText.isEmpty
                    ? 'Make a request to see the response here...'
                    : responseText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: errorText.isNotEmpty ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    if (downloadedFileData == null || downloadedFileName == null) {
      return const SizedBox.shrink();
    }

    final fileName = downloadedFileName!.toLowerCase();
    final isImage =
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif');
    final isVideo = fileName.endsWith('.mp4') || fileName.endsWith('.avi') || fileName.endsWith('.mov');

    if (isImage) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(downloadedFileData!, fit: BoxFit.contain, height: 200),
      );
    } else if (isVideo) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(downloadedFileName!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${(downloadedFileData!.length / 1024).toStringAsFixed(2)} KB',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(downloadedFileName!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${(downloadedFileData!.length / 1024).toStringAsFixed(2)} KB',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Flutter API Testing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Auth'),
            Tab(text: 'Users'),
            Tab(text: 'Products'),
            Tab(text: 'Files'),
            Tab(text: 'Testing'),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: TabBarView(
              controller: _tabController,
              children: [_buildAuthTab(), _buildUsersTab(), _buildProductsTab(), _buildFilesTab(), _buildTestingTab()],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
                color: Colors.grey[50],
              ),
              child: _buildResponseDisplay(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Helper Model ==============
class FileItem {
  final String id;
  final String fileName;
  final String originalFileName;
  final String contentType;
  final int size;
  final String filePath;
  final DateTime uploadedAt;

  FileItem({
    required this.id,
    required this.fileName,
    required this.originalFileName,
    required this.contentType,
    required this.size,
    required this.filePath,
    required this.uploadedAt,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      originalFileName: json['originalFileName'] as String,
      contentType: json['contentType'] as String,
      size: json['size'] as int,
      filePath: json['filePath'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}
