import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../config/api_config.dart';
import '../models/scan_model.dart';

class MlScreen extends StatefulWidget {
  final bool embedded;
  final String category;
  const MlScreen({super.key, this.embedded = false, this.category = 'url'});

  @override
  State<MlScreen> createState() => _MlScreenState();
}

class _MlScreenState extends State<MlScreen> {
  String get _apiBase => ApiConfig.baseUrl;

  bool _isUploading = false;
  bool _isTraining = false;
  bool _isScanning = false;
  String _errorMessage = '';

  final TextEditingController _scanInputController = TextEditingController();
  ScanHistoryItem? _scanResult;

  Map<String, dynamic>? _datasetInfo;
  Map<String, dynamic>? _edaData;
  Map<String, dynamic>? _trainResults;
  String _selectedModel = 'Random Forest';
  Map<String, dynamic>? _analyzeResults;

  static const Map<String, Map<String, String>> _kaggleSuggestions = {
    'url': {
      'name': 'PhiUSIIL Phishing URL Dataset',
      'source': 'Kaggle: phiusiil-phishing-url-dataset',
    },
    'text': {
      'name': 'SMS Spam Collection Dataset',
      'source': 'Kaggle: uciml/sms-spam-collection-dataset',
    },
    'screenshot': {
      'name': 'Phishing Website Screenshots',
      'source': 'Kaggle: phishing-site-screenshots',
    },
    'email': {
      'name': 'Email Headers Fraud Dataset',
      'source': 'Kaggle: email-headers-dataset',
    },
    'spam': {
      'name': 'Spam Email Classification',
      'source': 'Kaggle: spam-email-classification-dataset',
    },
  };

  String _getUserId() {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      return appState.currentUser?['userId']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    try {
      final uid = _getUserId();
      final res = await http.get(
        Uri.parse('$_apiBase/api/ml/model-status?category=${widget.category}&user_id=$uid'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['dataset_loaded'] == true) {
          setState(() {
            _datasetInfo = data['dataset_info'];
            _trainResults = data['training_results'];
            if (_trainResults != null && _trainResults!['best_model'] != null) {
              _selectedModel = _trainResults!['best_model'];
            }
          });
          _fetchEda();
          if (_trainResults != null) {
            _fetchAutoAnalysis();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchEda() async {
    try {
      final uid = _getUserId();
      final res = await http.get(
        Uri.parse('$_apiBase/api/ml/eda-results?category=${widget.category}&user_id=$uid'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _edaData = jsonDecode(res.body);
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadCsv() async {
    setState(() {
      _errorMessage = '';
      _isUploading = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'arff'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        setState(() {
          _errorMessage = 'Could not read file bytes.';
          _isUploading = false;
        });
        return;
      }

      final uid = _getUserId();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$_apiBase/api/ml/upload-dataset?category=${widget.category}&user_id=$uid',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _datasetInfo = data['dataset_info'];
          _edaData = data['eda'];
          _trainResults = null;
        });
        // Auto-train immediately after upload
        setState(() => _isUploading = false);
        await _trainModels();
        return;
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _errorMessage = err['detail'] ?? 'Upload failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading file: $e';
      });
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _loadSampleDataset() async {
    setState(() {
      _errorMessage = '';
      _isUploading = true;
    });

    try {
      final uid = _getUserId();
      final sampleRes = await http.get(
        Uri.parse(
          '$_apiBase/api/ml/sample-dataset?category=${widget.category}&user_id=$uid',
        ),
      );
      if (sampleRes.statusCode != 200) {
        throw Exception('Failed to get sample dataset');
      }

      final bytes = sampleRes.bodyBytes;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$_apiBase/api/ml/upload-dataset?category=${widget.category}&user_id=$uid',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'sample_phishing_dataset.csv',
        ),
      );

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _datasetInfo = data['dataset_info'];
          _edaData = data['eda'];
          _trainResults = null;
        });
        // Auto-train immediately after sample dataset load
        setState(() => _isUploading = false);
        await _trainModels();
        return;
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _errorMessage = err['detail'] ?? 'Failed to process sample dataset';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Backend error: Please ensure FastAPI backend is running on port 8000. ($e)';
      });
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _trainModels() async {
    setState(() {
      _errorMessage = '';
      _isTraining = true;
      _analyzeResults = null;
    });

    try {
      final uid = _getUserId();
      final res = await http.post(
        Uri.parse('$_apiBase/api/ml/train?category=${widget.category}&user_id=$uid'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _trainResults = data;
          if (data['best_model'] != null) {
            _selectedModel = data['best_model'];
          }
        });
        // Auto-analyze the dataset after training
        await _fetchAutoAnalysis();
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          _errorMessage = err['detail'] ?? 'Training failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Training error: $e';
      });
    } finally {
      setState(() => _isTraining = false);
    }
  }

  Future<void> _fetchAutoAnalysis() async {
    try {
      final uid = _getUserId();
      final res = await http.get(
        Uri.parse('$_apiBase/api/ml/auto-analyze?category=${widget.category}&user_id=$uid'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _analyzeResults = jsonDecode(res.body);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (!widget.embedded)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ML Dataset & Training Lab',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Upload CSV phishing dataset → EDA → Train ML Models',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Live Threat Scanner Input Box (Top Section)
          _buildLiveScannerCard(),

          const SizedBox(height: 24),

          // Section 1: Upload Card
          _buildUploadCard(),

          // Section 2: EDA Results Card
          if (_edaData != null) ...[
            const SizedBox(height: 24),
            _buildEdaCard(),
          ],

          // Section 3: Model Training Results
          if (_trainResults != null) ...[
            const SizedBox(height: 24),
            _buildTrainingResultsCard(),
          ],

          // Section 4: Auto-Analysis Results (Spam vs Safe)
          if (_analyzeResults != null) ...[
            const SizedBox(height: 24),
            _buildAutoAnalysisCard(),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(child: body),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.7),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Step 1: Dataset Upload',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upload open-source CSV / ARFF dataset (PhiUSIIL, UCI, Kaggle, or custom URL list)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 18),

          // Kaggle dataset suggestion
          if (_kaggleSuggestions.containsKey(widget.category)) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.25),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF06B6D4),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try: ${_kaggleSuggestions[widget.category]!["name"]} (${_kaggleSuggestions[widget.category]!["source"]})',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadCsv,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(
                    _isUploading ? 'Uploading…' : 'Upload CSV / ARFF File',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _loadSampleDataset,
                  icon: const Icon(Icons.science_rounded, size: 18),
                  label: const Text('Use Sample CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_datasetInfo != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dataset Loaded: ${_datasetInfo!['total_rows']} rows · ${_datasetInfo!['feature_count']} features',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEdaCard() {
    final info = _datasetInfo ?? {};
    final labelDist = _edaData?['label_distribution'] ?? {};
    final phishCount = labelDist['phishing'] ?? 0;
    final legitCount = labelDist['legitimate'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.7),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Step 2: Exploratory Data Analysis (EDA)',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stat boxes grid
          Row(
            children: [
              _buildStatBox(
                'Total Rows',
                '${info['total_rows'] ?? 0}',
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _buildStatBox('Phishing', '$phishCount', const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _buildStatBox(
                'Legitimate',
                '$legitCount',
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                'Class Balance',
                '${info['class_balance'] ?? 0}%',
                const Color(0xFFF59E0B),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Train button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTraining ? null : _trainModels,
              icon: _isTraining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _trainResults != null
                          ? Icons.keyboard_double_arrow_down_rounded
                          : Icons.rocket_launch_rounded,
                    ),
              label: Text(
                _isTraining
                    ? 'Training Models…'
                    : (_trainResults != null
                          ? '📊 View Results Below'
                          : '🚀 Train ML Models'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingResultsCard() {
    final modelsMap = _trainResults?['models'] as Map<String, dynamic>? ?? {};
    final modelNames = modelsMap.keys.toList();
    final currentModelData =
        modelsMap[_selectedModel] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.7),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Step 3: Model Performance Results',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Model selectors
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modelNames.map((name) {
              final isSelected = _selectedModel == name;
              final isBest = name == _trainResults?['best_model'];
              return GestureDetector(
                onTap: () {
                  debugPrint('Model tapped: $name (was: $_selectedModel)');
                  setState(() {
                    _selectedModel = name;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEF4444)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEF4444)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${isBest ? "🏆 " : ""}$name',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Active model indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Viewing Metrics & Weights for: $_selectedModel',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metric Badges
          Row(
            children: [
              _buildMetricBadge(
                'Accuracy',
                '${currentModelData['accuracy'] ?? 0}%',
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _buildMetricBadge(
                'Precision',
                '${currentModelData['precision'] ?? 0}%',
                const Color(0xFF06B6D4),
              ),
              const SizedBox(width: 8),
              _buildMetricBadge(
                'Recall',
                '${currentModelData['recall'] ?? 0}%',
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _buildMetricBadge(
                'F1 Score',
                '${currentModelData['f1_score'] ?? 0}%',
                const Color(0xFF10B981),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Feature Importance / Model Weights for Selected Model
          if (currentModelData['feature_importance'] != null &&
              (currentModelData['feature_importance'] as List).isNotEmpty) ...[
            Text(
              '📊 Top Feature Weights / Importance ($_selectedModel)',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: (currentModelData['feature_importance'] as List)
                    .take(5)
                    .map((f) {
                      final feat = f as Map<String, dynamic>;
                      final name = feat['feature'] ?? '';
                      final imp =
                          (feat['importance'] as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                '$name',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (imp / (imp > 1.0 ? imp : 1.0)).clamp(
                                    0.05,
                                    1.0,
                                  ),
                                  backgroundColor: Colors.white10,
                                  color: _selectedModel == 'Random Forest'
                                      ? const Color(0xFF10B981)
                                      : _selectedModel == 'Logistic Regression'
                                      ? const Color(0xFF06B6D4)
                                      : const Color(0xFFF59E0B),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$imp',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Confusion Matrix
          if (currentModelData['confusion_matrix'] != null) ...[
            Text(
              '🎯 Confusion Matrix ($_selectedModel)',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildConfusionMatrixGrid(currentModelData['confusion_matrix']),
          ],

          const SizedBox(height: 20),

          // Model Comparison Table
          Text(
            '📋 Models Comparison Table',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildComparisonTable(modelsMap),
        ],
      ),
    );
  }

  Widget _buildAutoAnalysisCard() {
    final modelUsed = _analyzeResults?['model_used'] ?? 'Random Forest';
    final totalRows = _analyzeResults?['total_rows'] ?? 0;
    final spamCount = _analyzeResults?['spam_count'] ?? 0;
    final safeCount = _analyzeResults?['safe_count'] ?? 0;
    final spamPct = _analyzeResults?['spam_percentage'] ?? 0;
    final safePct = _analyzeResults?['safe_percentage'] ?? 0;
    final sampleSpam = _analyzeResults?['sample_spam'] as List? ?? [];
    final sampleSafe = _analyzeResults?['sample_safe'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.7),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Step 4: Auto-Analysis Results',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  modelUsed,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dataset automatically scanned & classified using trained $modelUsed model',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),

          // Summary Stats
          Row(
            children: [
              _buildAnalysisStat(
                'Total Scanned',
                '$totalRows',
                const Color(0xFF06B6D4),
                Icons.dataset_rounded,
              ),
              const SizedBox(width: 8),
              _buildAnalysisStat(
                'Malicious',
                '$spamCount ($spamPct%)',
                const Color(0xFFEF4444),
                Icons.dangerous_rounded,
              ),
              const SizedBox(width: 8),
              _buildAnalysisStat(
                'Safe',
                '$safeCount ($safePct%)',
                const Color(0xFF10B981),
                Icons.verified_user_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (spamPct > 0)
                    Expanded(
                      flex: (spamPct as num).toInt().clamp(1, 100),
                      child: Container(
                        color: const Color(0xFFEF4444),
                        alignment: Alignment.center,
                        child: Text(
                          '${spamPct}% Spam',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (safePct > 0)
                    Expanded(
                      flex: (safePct as num).toInt().clamp(1, 100),
                      child: Container(
                        color: const Color(0xFF10B981),
                        alignment: Alignment.center,
                        child: Text(
                          '${safePct}% Safe',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sample Spam Rows
          if (sampleSpam.isNotEmpty) ...[
            Text(
              '🚨 Sample Malicious/Spam Detected:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 8),
            ...sampleSpam.map(
              (item) => _buildSampleRow(item, const Color(0xFFEF4444)),
            ),
            const SizedBox(height: 12),
          ],

          // Sample Safe Rows
          if (sampleSafe.isNotEmpty) ...[
            Text(
              '✅ Sample Safe/Legitimate Detected:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 8),
            ...sampleSafe.map(
              (item) => _buildSampleRow(item, const Color(0xFF10B981)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleRow(dynamic item, Color color) {
    final row = item as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${row['row']}',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${row['text']}',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            color == const Color(0xFFEF4444)
                ? Icons.warning_rounded
                : Icons.check_circle_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfusionMatrixGrid(dynamic cmRaw) {
    try {
      final List cm = cmRaw;
      final int tn = cm[0][0];
      final int fp = cm[0][1];
      final int fn = cm[1][0];
      final int tp = cm[1][1];

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: [
          _buildCmCell(
            'True Negative (TN)',
            '$tn',
            'Legit → Legit ✓',
            const Color(0xFF10B981),
          ),
          _buildCmCell(
            'False Positive (FP)',
            '$fp',
            'Legit → Phish ✗',
            const Color(0xFFF59E0B),
          ),
          _buildCmCell(
            'False Negative (FN)',
            '$fn',
            'Phish → Legit ✗',
            const Color(0xFFEF4444),
          ),
          _buildCmCell(
            'True Positive (TP)',
            '$tp',
            'Phish → Phish ✓',
            const Color(0xFFEF4444),
          ),
        ],
      );
    } catch (_) {
      return const SizedBox();
    }
  }

  Widget _buildCmCell(String title, String val, String desc, Color col) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        border: Border.all(color: col.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: col,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(Map<String, dynamic> modelsMap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: modelsMap.entries.map((e) {
          final name = e.key;
          final m = e.value;
          final isBest = name == _trainResults?['best_model'];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              color: isBest
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${isBest ? "🏆 " : ""}$name',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Acc: ${m['accuracy']}%',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'F1: ${m['f1_score']}%',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _executeLiveScan() async {
    final inputContent = _scanInputController.text.trim();
    if (inputContent.isEmpty) return;

    setState(() {
      _errorMessage = '';
      _isScanning = true;
      _scanResult = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final res = await appState.executeScan(
        inputType: widget.category,
        inputContent: inputContent,
      );
      setState(() {
        _scanResult = res;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Scan error: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickAndScanScreenshot() async {
    setState(() {
      _errorMessage = '';
      _isScanning = true;
      _scanResult = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isScanning = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        setState(() {
          _errorMessage = 'Could not read image file bytes.';
          _isScanning = false;
        });
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);
      final res = await appState.executeScreenshotScan(
        bytes: bytes,
        filename: file.name,
      );
      setState(() {
        _scanResult = res;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Screenshot scan error: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Widget _buildLiveScannerCard() {
    final String label =
        {
          'url': 'Suspicious URL',
          'text': 'SMS / Text Message',
          'email': 'Raw Email Headers',
          'spam': 'Spam / Phishing Message',
        }[widget.category] ??
        'suspicious content';

    final String placeholder =
        {
          'url': 'http://secure-login-chase-update.xyz/login',
          'text': 'Urgent: Your account is locked. Verify at http://...',
          'email': 'Delivered-To: victim@gmail.com\nReceived: from ...',
          'spam': 'Free entry: Win \$1000 cash prize now. Click here!',
        }[widget.category] ??
        'Enter content here...';

    final isScreenshot = widget.category == 'screenshot';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.7),
        border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                color: Color(0xFF00F2FE),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '⚡ Instant Threat Scanner (Type Message or Link)',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isScreenshot
                ? 'Scan a suspicious website screenshot image to analyze visual & brand threat features.'
                : 'Enter a $label to run it through your trained ML classifier in real-time.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 18),

          if (isScreenshot) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _pickAndScanScreenshot,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.image_search_rounded, size: 18),
                label: Text(
                  _isScanning
                      ? 'Analyzing Screenshot...'
                      : 'Scan Screenshot Image',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: _scanInputController,
              maxLines: widget.category == 'email' ? 5 : 1,
              decoration: InputDecoration(
                labelText: 'Enter $label',
                hintText: placeholder,
                labelStyle: GoogleFonts.outfit(
                  color: const Color(0xFF00F2FE),
                  fontSize: 13,
                ),
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F2FE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _executeLiveScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.radar_rounded, size: 18),
                label: Text(
                  _isScanning
                      ? 'Scanning Content...'
                      : '⚡ Scan & Analyze Threat',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          if (_scanResult != null) ...[
            const SizedBox(height: 18),
            _buildScanResultPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildScanResultPanel() {
    final scan = _scanResult!;
    final isDangerous = scan.riskLevel == 'DANGEROUS';
    final isSuspicious = scan.riskLevel == 'SUSPICIOUS';
    final Color riskColor = isDangerous
        ? const Color(0xFFEF4444)
        : (isSuspicious ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    final String riskText = isDangerous
        ? '🔴 CONFIRMED THREAT DETECTED'
        : (isSuspicious
              ? '⚠️ SUSPICIOUS THREAT WARNING'
              : '🟢 SAFE & CLEAN CONTENT');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        border: Border.all(color: riskColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  riskText,
                  style: GoogleFonts.outfit(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                'Risk Score: ${scan.riskScore}%',
                style: GoogleFonts.spaceGrotesk(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: scan.riskScore / 100,
              backgroundColor: Colors.white.withOpacity(0.04),
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🔍 Prediction Findings:',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          ...scan.reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.white70)),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
