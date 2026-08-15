import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

class GMBHealthScorecardWidget extends StatefulWidget {
  final String locationId;
  final VoidCallback? onAuditUpdated;

  const GMBHealthScorecardWidget({
    super.key,
    required this.locationId,
    this.onAuditUpdated,
  });

  @override
  State<GMBHealthScorecardWidget> createState() => _GMBHealthScorecardWidgetState();
}

class _GMBHealthScorecardWidgetState extends State<GMBHealthScorecardWidget> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isFixing = false;
  String? _fixingId;
  Map<String, dynamic>? _auditData;

  @override
  void initState() {
    super.initState();
    _fetchAuditData();
  }

  @override
  void didUpdateWidget(covariant GMBHealthScorecardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) {
      _fetchAuditData();
    }
  }

  Future<void> _fetchAuditData() async {
    if (widget.locationId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/gmb/audit?location_id=${Uri.encodeComponent(widget.locationId)}',
      );
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _auditData = data;
            _isLoading = false;
          });
          widget.onAuditUpdated?.call();
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching GMB audit: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _applyFix(String fixType, String issueId) async {
    setState(() {
      _isFixing = true;
      _fixingId = issueId;
    });
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/audit/fix');
      final body = jsonEncode({
        'location_id': widget.locationId,
        'fix_type': fixType,
      });

      final res = await http.post(uri, headers: headers, body: body);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? '✨ AI Auto-Fix applied successfully!'),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          await _fetchAuditData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply fix: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFixing = false;
          _fixingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_auditData == null) {
      return const SizedBox.shrink();
    }

    final int score = (_auditData!['health_score'] ?? 80) as int;
    final String statusLabel = _auditData!['status_label'] ?? 'Optimized Profile';
    final List issues = (_auditData!['issues'] as List?) ?? [];

    Color scoreColor = Colors.green;
    if (score < 65) {
      scoreColor = Colors.red;
    } else if (score < 85) {
      scoreColor = Colors.amber.shade800;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              scoreColor.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Score & Refresh Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      score >= 85 ? Icons.shield : Icons.warning_amber_rounded,
                      color: scoreColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GMB Local SEO Health',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score / 100',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100.0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                InkWell(
                  onTap: _fetchAuditData,
                  child: const Text(
                    'Re-scan 🔄',
                    style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Issues Section & 1-Click Auto Fix All
            if (issues.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detected Issues (${issues.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isFixing ? null : () => _applyFix('auto_fix_all', 'all'),
                    icon: _isFixing && _fixingId == 'all'
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome, size: 14),
                    label: Text(_isFixing && _fixingId == 'all' ? 'Fixing...' : 'AI Auto-Fix All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: issues.length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final issue = issues[index];
                  final String title = issue['title'] ?? 'Policy Risk';
                  final String desc = issue['description'] ?? '';
                  final bool canFix = issue['fix_available'] == true;
                  final String? fixType = issue['fix_type'];

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (canFix && fixType != null)
                        TextButton(
                          onPressed: _isFixing ? null : () => _applyFix(fixType, issue['id'] ?? fixType),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Fix Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Policy Compliant! Zero listing risks detected.',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
