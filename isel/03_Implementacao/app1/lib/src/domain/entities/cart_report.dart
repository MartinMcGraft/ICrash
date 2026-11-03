/// A cart report produced by the App: the monthly check (design v2 A8 → A9)
/// or the summary generated when emergency mode ends (A10).
///
/// Backed by a local stub repository for now (see `data/local/`); the shape
/// is JSON-serialisable so it can move to Firestore unchanged.
class CartReport {
  const CartReport({
    required this.id,
    required this.institutionId,
    required this.cartId,
    required this.cartName,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
    this.drawersChecked = 0,
    this.drawersTotal = 0,
    this.positionsChecked = 0,
    this.positionsTotal = 0,
    this.findings = const [],
    this.lines = const [],
    this.notes,
    this.periodStart,
    this.periodEnd,
    this.signedByUid,
    this.signedByName,
    this.signedAt,
  });

  final String id;
  final String institutionId;
  final String cartId;
  final String cartName;
  final ReportKind kind;
  final ReportStatus status;
  final DateTime createdAt;
  final String createdByUid;
  final String createdByName;

  /// Monthly check progress.
  final int drawersChecked;
  final int drawersTotal;
  final int positionsChecked;
  final int positionsTotal;

  /// Problems found during the check ("Problemas encontrados").
  final List<ReportFinding> findings;

  /// Emergency summary: product consumptions.
  final List<ReportLine> lines;
  final String? notes;

  /// Emergency mode start/end.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  final String? signedByUid;
  final String? signedByName;
  final DateTime? signedAt;

  bool get isSigned => status == ReportStatus.signed;

  CartReport signed({required String uid, required String name, required DateTime at}) => CartReport(
        id: id,
        institutionId: institutionId,
        cartId: cartId,
        cartName: cartName,
        kind: kind,
        status: ReportStatus.signed,
        createdAt: createdAt,
        createdByUid: createdByUid,
        createdByName: createdByName,
        drawersChecked: drawersChecked,
        drawersTotal: drawersTotal,
        positionsChecked: positionsChecked,
        positionsTotal: positionsTotal,
        findings: findings,
        lines: lines,
        notes: notes,
        periodStart: periodStart,
        periodEnd: periodEnd,
        signedByUid: uid,
        signedByName: name,
        signedAt: at,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'institutionId': institutionId,
        'cartId': cartId,
        'cartName': cartName,
        'kind': kind.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'createdByUid': createdByUid,
        'createdByName': createdByName,
        'drawersChecked': drawersChecked,
        'drawersTotal': drawersTotal,
        'positionsChecked': positionsChecked,
        'positionsTotal': positionsTotal,
        'findings': [for (final f in findings) f.toJson()],
        'lines': [for (final l in lines) l.toJson()],
        'notes': notes,
        'periodStart': periodStart?.toIso8601String(),
        'periodEnd': periodEnd?.toIso8601String(),
        'signedByUid': signedByUid,
        'signedByName': signedByName,
        'signedAt': signedAt?.toIso8601String(),
      };

  factory CartReport.fromJson(Map<String, Object?> json) => CartReport(
        id: json['id'] as String,
        institutionId: json['institutionId'] as String,
        cartId: json['cartId'] as String,
        cartName: json['cartName'] as String? ?? '',
        kind: ReportKind.values.byName(json['kind'] as String),
        status: ReportStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdByUid: json['createdByUid'] as String? ?? '',
        createdByName: json['createdByName'] as String? ?? '',
        drawersChecked: (json['drawersChecked'] as num?)?.toInt() ?? 0,
        drawersTotal: (json['drawersTotal'] as num?)?.toInt() ?? 0,
        positionsChecked: (json['positionsChecked'] as num?)?.toInt() ?? 0,
        positionsTotal: (json['positionsTotal'] as num?)?.toInt() ?? 0,
        findings: [
          for (final f in (json['findings'] as List? ?? const [])) ReportFinding.fromJson((f as Map).cast<String, Object?>()),
        ],
        lines: [
          for (final l in (json['lines'] as List? ?? const [])) ReportLine.fromJson((l as Map).cast<String, Object?>()),
        ],
        notes: json['notes'] as String?,
        periodStart: _date(json['periodStart']),
        periodEnd: _date(json['periodEnd']),
        signedByUid: json['signedByUid'] as String?,
        signedByName: json['signedByName'] as String?,
        signedAt: _date(json['signedAt']),
      );
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;

enum ReportKind { monthlyCheck, emergencySummary }

enum ReportStatus { pendingSignature, signed }

/// One problem found during a monthly check.
class ReportFinding {
  const ReportFinding({required this.productName, required this.position, required this.issue, this.detail});

  final String productName;

  /// "A5", "B3"…
  final String position;
  final FindingIssue issue;

  /// Free text, e.g. "expira a 28/10/2026 · reposição pedida".
  final String? detail;

  Map<String, Object?> toJson() => {'productName': productName, 'position': position, 'issue': issue.name, 'detail': detail};

  factory ReportFinding.fromJson(Map<String, Object?> json) => ReportFinding(
        productName: json['productName'] as String? ?? '',
        position: json['position'] as String? ?? '',
        issue: FindingIssue.values.byName(json['issue'] as String? ?? FindingIssue.other.name),
        detail: json['detail'] as String?,
      );
}

enum FindingIssue { expired, expiring, missing, lowStock, other }

/// One product line in an emergency summary.
class ReportLine {
  const ReportLine({required this.productName, required this.amount});
  final String productName;
  final int amount;

  Map<String, Object?> toJson() => {'productName': productName, 'amount': amount};

  factory ReportLine.fromJson(Map<String, Object?> json) =>
      ReportLine(productName: json['productName'] as String? ?? '', amount: (json['amount'] as num?)?.toInt() ?? 0);
}
