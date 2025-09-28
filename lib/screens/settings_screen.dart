import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/camera_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _esp32UrlController = TextEditingController();
  final TextEditingController _dockerUrlController = TextEditingController();
  final TextEditingController _vitGptUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _esp32UrlController.text = 'http://192.168.0.144/capture';
    _dockerUrlController.text = 'http://localhost:8000';
    _vitGptUrlController.text = 'http://localhost:5000';
  }

  @override
  void dispose() {
    _esp32UrlController.dispose();
    _dockerUrlController.dispose();
    _vitGptUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appStateProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Camera Source'),
                SizedBox(height: 16),
                _buildCameraSourceCard(appStateProvider),
                SizedBox(height: 32),

                _buildSectionTitle('AI Service'),
                SizedBox(height: 16),
                _buildAIServiceCard(appStateProvider),
                SizedBox(height: 32),

                _buildSectionTitle('ESP32 Camera'),
                SizedBox(height: 16),
                _buildEsp32Card(appStateProvider),
                SizedBox(height: 32),

                _buildSectionTitle('VIT-GPT AI Service'),
                SizedBox(height: 16),
                _buildVitGptCard(appStateProvider),
                SizedBox(height: 32),

                _buildSectionTitle('Docker AI Service'),
                SizedBox(height: 16),
                _buildDockerCard(appStateProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCameraSourceCard(AppStateProvider provider) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.cyan),
              title: Text(
                'Device Camera',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Radio<CameraSource>(
                value: CameraSource.device,
                groupValue: CameraService().currentSource,
                onChanged: (value) {
                  if (value != null) {
                    provider.switchCameraSource(value);
                    HapticFeedback.mediumImpact();
                  }
                },
                activeColor: Colors.cyan,
              ),
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: Icon(Icons.wifi, color: Colors.orange),
              title: Text(
                'ESP32 Camera',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Radio<CameraSource>(
                value: CameraSource.esp32,
                groupValue: CameraService().currentSource,
                onChanged: (value) {
                  if (value != null) {
                    provider.switchCameraSource(
                      value,
                      esp32Url: _esp32UrlController.text,
                    );
                    HapticFeedback.mediumImpact();
                  }
                },
                activeColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIServiceCard(AppStateProvider provider) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.smart_toy, color: Colors.green),
              title: Text(
                'Mock AI Service',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Radio<bool>(
                value: false,
                groupValue: provider.useDockerAI || provider.useVitGptAI,
                onChanged: (value) {
                  provider.toggleAIService();
                  HapticFeedback.mediumImpact();
                },
                activeColor: Colors.green,
              ),
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: Icon(Icons.psychology, color: Colors.purple),
              title: Text(
                'VIT-GPT AI Service',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Radio<bool>(
                value: true,
                groupValue: provider.useVitGptAI,
                onChanged: (value) {
                  provider.toggleAIService();
                  HapticFeedback.mediumImpact();
                },
                activeColor: Colors.purple,
              ),
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.blue),
              title: Text(
                'Docker AI Service',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Radio<bool>(
                value: true,
                groupValue: provider.useDockerAI,
                onChanged: (value) {
                  provider.toggleAIService();
                  HapticFeedback.mediumImpact();
                },
                activeColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEsp32Card(AppStateProvider provider) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _esp32UrlController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'ESP32 Camera URL',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  provider.configureEsp32Camera(_esp32UrlController.text);
                  HapticFeedback.mediumImpact();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('Configure ESP32 Camera'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitGptCard(AppStateProvider provider) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _vitGptUrlController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'VIT-GPT AI Service URL',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  provider.configureVitGptAI(_vitGptUrlController.text);
                  HapticFeedback.mediumImpact();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: Text('Configure VIT-GPT AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockerCard(AppStateProvider provider) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _dockerUrlController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Docker AI Service URL',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'API Key (Optional)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  provider.configureDockerAI(
                    _dockerUrlController.text,
                    apiKey:
                        _apiKeyController.text.isNotEmpty
                            ? _apiKeyController.text
                            : null,
                  );
                  HapticFeedback.mediumImpact();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Configure Docker AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
