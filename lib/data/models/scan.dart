import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';

/// Steps of a full scan, in the order the server runs them.
const List<String> scanSteps = ['dns', 'subdomains', 'ports', 'ssl', 'technologies', 'headers', 'exposed_resources'];

class Scan {
  final String id;
  final String domainId;
  final String status;
  final String? trigger;

  /// Step name -> status string (status payload) or detail object (full scan).
  final Json steps;
  final int changeCount;
  final String? error;
  final int? progress;
  final String? currentStep;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const Scan({
    required this.id,
    required this.domainId,
    required this.status,
    required this.steps,
    this.trigger,
    this.changeCount = 0,
    this.error,
    this.progress,
    this.currentStep,
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  bool get isActive => status == 'QUEUED' || status == 'RUNNING';

  String stepStatus(String step) {
    final value = steps[step];
    if (value is String) return value;
    if (value is Map) return value['status'] as String? ?? 'pending';
    return 'pending';
  }

  Json? stepDetail(String step) => steps[step] is Map ? Json.from(steps[step] as Map) : null;

  int get progressPercent {
    if (progress != null) return progress!;
    final done = scanSteps.where((s) => stepStatus(s) != 'pending' && stepStatus(s) != 'running').length;
    return (done * 100 / scanSteps.length).round();
  }

  /// Applies a `GET /scan/status/:id` payload on top of this scan.
  Scan mergeStatus(Json s) => Scan(
    id: id,
    domainId: domainId,
    status: s['status'] as String? ?? status,
    steps: s['steps'] is Map ? Json.from(s['steps'] as Map) : steps,
    trigger: trigger,
    changeCount: changeCount,
    error: error,
    progress: s['progress'] as int?,
    currentStep: s['currentStep'] as String?,
    startedAt: parseDate(s['startedAt']) ?? startedAt,
    completedAt: parseDate(s['completedAt']),
    createdAt: createdAt,
  );

  factory Scan.fromJson(Json json) => Scan(
    id: json['id'] as String,
    domainId: json['domainId'] as String? ?? '',
    status: json['status'] as String? ?? 'QUEUED',
    steps: json['steps'] is Map ? Json.from(json['steps'] as Map) : {},
    trigger: json['trigger'] as String?,
    changeCount: json['changeCount'] as int? ?? 0,
    error: json['error'] as String?,
    progress: json['progress'] as int?,
    currentStep: json['currentStep'] as String?,
    startedAt: parseDate(json['startedAt']),
    completedAt: parseDate(json['completedAt']),
    createdAt: parseDate(json['createdAt']),
  );
}
