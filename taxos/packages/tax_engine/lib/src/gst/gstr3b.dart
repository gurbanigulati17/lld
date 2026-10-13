import 'dart:math' as math;

import '../common/line_item.dart';
import '../common/money.dart';

/// Tax split across the three GST heads plus compensation cess.
class GstHeads {
  const GstHeads({this.igst = 0, this.cgst = 0, this.sgst = 0, this.cess = 0});

  final int igst;
  final int cgst;
  final int sgst;
  final int cess;

  int get total => igst + cgst + sgst + cess;

  GstHeads operator +(GstHeads o) => GstHeads(
        igst: igst + o.igst,
        cgst: cgst + o.cgst,
        sgst: sgst + o.sgst,
        cess: cess + o.cess,
      );

  GstHeads operator -(GstHeads o) => GstHeads(
        igst: igst - o.igst,
        cgst: cgst - o.cgst,
        sgst: sgst - o.sgst,
        cess: cess - o.cess,
      );

  Map<String, Object?> toJson() =>
      {'igst': igst, 'cgst': cgst, 'sgst': sgst, 'cess': cess};

  factory GstHeads.fromJson(Map<String, Object?> j) => GstHeads(
        igst: _i(j['igst']),
        cgst: _i(j['cgst']),
        sgst: _i(j['sgst']),
        cess: _i(j['cess']),
      );

  @override
  String toString() => 'IGST $igst CGST $cgst SGST $sgst Cess $cess';
}

/// One line of outward supply for the period.
class OutwardSupply {
  const OutwardSupply({
    required this.taxableValue,
    required this.ratePercent,
    required this.interState,
    this.cessPercent = 0,
    this.description = '',
  });

  final int taxableValue;
  final double ratePercent;

  /// Inter-state supplies attract IGST; intra-state split CGST/SGST equally.
  final bool interState;
  final double cessPercent;
  final String description;

  GstHeads get tax {
    final t = pct(taxableValue, ratePercent);
    final cess = pct(taxableValue, cessPercent);
    if (interState) return GstHeads(igst: t, cess: cess);
    final half = t ~/ 2;
    return GstHeads(cgst: half, sgst: t - half, cess: cess);
  }

  Map<String, Object?> toJson() => {
        'taxableValue': taxableValue,
        'ratePercent': ratePercent,
        'interState': interState,
        'cessPercent': cessPercent,
        'description': description,
      };

  factory OutwardSupply.fromJson(Map<String, Object?> j) => OutwardSupply(
        taxableValue: _i(j['taxableValue']),
        ratePercent: (j['ratePercent'] as num).toDouble(),
        interState: (j['interState'] as bool?) ?? false,
        cessPercent: ((j['cessPercent'] as num?) ?? 0).toDouble(),
        description: (j['description'] as String?) ?? '',
      );
}

class Gstr3bInput {
  const Gstr3bInput({
    required this.period,
    required this.outwardSupplies,
    this.reverseChargeLiability = const GstHeads(),
    this.itcAvailable = const GstHeads(),
    this.itcReversal = const GstHeads(),
    this.openingCreditLedger = const GstHeads(),
    this.annualTurnover = 0,
    this.dueDate,
    this.filingDate,
    this.isNilReturn = false,
  });

  /// e.g. `2025-09` for September 2025.
  final String period;
  final List<OutwardSupply> outwardSupplies;

  /// Tax payable under reverse charge (must be paid in cash).
  final GstHeads reverseChargeLiability;

  /// Eligible ITC for the period as per GSTR-2B.
  final GstHeads itcAvailable;

  /// ITC to be reversed (Rules 42/43, s.17(5)).
  final GstHeads itcReversal;
  final GstHeads openingCreditLedger;

  /// Previous-year turnover, drives the late fee cap.
  final int annualTurnover;
  final DateTime? dueDate;
  final DateTime? filingDate;
  final bool isNilReturn;

  Map<String, Object?> toJson() => {
        'period': period,
        'outwardSupplies': outwardSupplies.map((s) => s.toJson()).toList(),
        'reverseChargeLiability': reverseChargeLiability.toJson(),
        'itcAvailable': itcAvailable.toJson(),
        'itcReversal': itcReversal.toJson(),
        'openingCreditLedger': openingCreditLedger.toJson(),
        'annualTurnover': annualTurnover,
        if (dueDate != null)
          'dueDate': dueDate!.toIso8601String().substring(0, 10),
        if (filingDate != null)
          'filingDate': filingDate!.toIso8601String().substring(0, 10),
        'isNilReturn': isNilReturn,
      };

  factory Gstr3bInput.fromJson(Map<String, Object?> j) => Gstr3bInput(
        period: j['period'] as String,
        outwardSupplies: ((j['outwardSupplies'] as List?) ?? const [])
            .map((e) => OutwardSupply.fromJson(e as Map<String, Object?>))
            .toList(),
        reverseChargeLiability: _heads(j['reverseChargeLiability']),
        itcAvailable: _heads(j['itcAvailable']),
        itcReversal: _heads(j['itcReversal']),
        openingCreditLedger: _heads(j['openingCreditLedger']),
        annualTurnover: _i(j['annualTurnover']),
        dueDate: j['dueDate'] == null ? null : DateTime.parse(j['dueDate'] as String),
        filingDate:
            j['filingDate'] == null ? null : DateTime.parse(j['filingDate'] as String),
        isNilReturn: (j['isNilReturn'] as bool?) ?? false,
      );

  static GstHeads _heads(Object? v) =>
      v == null ? const GstHeads() : GstHeads.fromJson(v as Map<String, Object?>);
}

class Gstr3bResult {
  const Gstr3bResult({
    required this.outputTax,
    required this.reverseCharge,
    required this.netItc,
    required this.itcUtilised,
    required this.cashPayable,
    required this.closingCreditLedger,
    required this.lateFee,
    required this.interest,
    required this.daysLate,
    required this.lineItems,
    required this.notes,
  });

  final GstHeads outputTax;
  final GstHeads reverseCharge;
  final GstHeads netItc;
  final GstHeads itcUtilised;
  final GstHeads cashPayable;
  final GstHeads closingCreditLedger;

  /// CGST + SGST late fee (equal halves).
  final int lateFee;

  /// s.50 interest on the net cash liability.
  final int interest;
  final int daysLate;
  final List<LineItem> lineItems;
  final List<String> notes;

  int get totalCashOutflow => cashPayable.total + lateFee + interest;

  Map<String, Object?> toJson() => {
        'outputTax': outputTax.toJson(),
        'reverseCharge': reverseCharge.toJson(),
        'netItc': netItc.toJson(),
        'itcUtilised': itcUtilised.toJson(),
        'cashPayable': cashPayable.toJson(),
        'closingCreditLedger': closingCreditLedger.toJson(),
        'lateFee': lateFee,
        'interest': interest,
        'daysLate': daysLate,
        'totalCashOutflow': totalCashOutflow,
        'lineItems': lineItems.map((l) => l.toJson()).toList(),
        'notes': notes,
      };
}

/// Computes a GSTR-3B: output tax, ITC set-off in the order prescribed by
/// s.49/49A and Rule 88A, net cash payable, late fee and s.50 interest.
///
/// Set-off order:
/// * IGST credit → IGST liability, then CGST and SGST (any order; here CGST
///   first) until exhausted.
/// * CGST credit → CGST, then IGST. Never SGST.
/// * SGST credit → SGST, then IGST. Never CGST.
/// * Cess credit → cess only.
/// Reverse-charge liability is always paid in cash.
class Gstr3bComputer {
  const Gstr3bComputer();

  /// Late fee per day under s.47 (CGST + SGST combined).
  static const int lateFeePerDay = 50;
  static const int lateFeePerDayNil = 20;
  static const double interestRatePercentPa = 18;

  Gstr3bResult compute(Gstr3bInput input) {
    final lines = <LineItem>[];
    final notes = <String>[];

    final output = input.outwardSupplies
        .fold(const GstHeads(), (acc, s) => acc + s.tax);
    lines.add(LineItem(
      code: 'GST.OUTPUT',
      label: 'Output tax on outward supplies',
      amount: output.total,
      section: 's.9',
      note: output.toString(),
    ));
    final rcm = input.reverseChargeLiability;
    if (rcm.total > 0) {
      lines.add(LineItem(
        code: 'GST.RCM',
        label: 'Reverse charge liability (cash only)',
        amount: rcm.total,
        section: 's.9(3)/(4)',
        note: rcm.toString(),
      ));
    }

    final netItc = input.itcAvailable - input.itcReversal;
    final credit = input.openingCreditLedger + netItc;
    lines.add(LineItem(
      code: 'GST.ITC',
      label: 'Net ITC available (incl. opening balance)',
      amount: credit.total,
      section: 's.16',
      note: credit.toString(),
    ));

    // ---- set-off ---------------------------------------------------------
    var liabI = output.igst, liabC = output.cgst, liabS = output.sgst;
    var liabCess = output.cess;
    var crI = credit.igst, crC = credit.cgst, crS = credit.sgst, crCess = credit.cess;
    var usedI = 0, usedC = 0, usedS = 0, usedCess = 0;

    int use(int available, int liability) => math.min(available, liability);

    // IGST credit: IGST → CGST → SGST
    var u = use(crI, liabI);
    crI -= u; liabI -= u; usedI += u;
    u = use(crI, liabC);
    crI -= u; liabC -= u; usedI += u;
    u = use(crI, liabS);
    crI -= u; liabS -= u; usedI += u;
    // CGST credit: CGST → IGST
    u = use(crC, liabC);
    crC -= u; liabC -= u; usedC += u;
    u = use(crC, liabI);
    crC -= u; liabI -= u; usedC += u;
    // SGST credit: SGST → IGST
    u = use(crS, liabS);
    crS -= u; liabS -= u; usedS += u;
    u = use(crS, liabI);
    crS -= u; liabI -= u; usedS += u;
    // Cess credit: cess only
    u = use(crCess, liabCess);
    crCess -= u; liabCess -= u; usedCess += u;

    final utilised = GstHeads(igst: usedI, cgst: usedC, sgst: usedS, cess: usedCess);
    final cash = GstHeads(
      igst: liabI + rcm.igst,
      cgst: liabC + rcm.cgst,
      sgst: liabS + rcm.sgst,
      cess: liabCess + rcm.cess,
    );
    final closing = GstHeads(igst: crI, cgst: crC, sgst: crS, cess: crCess);

    lines.add(LineItem(
      code: 'GST.ITC_USED',
      label: 'ITC utilised',
      amount: -utilised.total,
      section: 'Rule 88A',
      note: utilised.toString(),
    ));
    lines.add(LineItem(
      code: 'GST.CASH',
      label: 'Net tax payable in cash',
      amount: cash.total,
      note: cash.toString(),
    ));
    if (closing.total > 0) {
      notes.add('Credit carried forward: $closing.');
    }

    // ---- late fee and interest -----------------------------------------
    var daysLate = 0;
    var lateFee = 0;
    var interest = 0;
    if (input.dueDate != null && input.filingDate != null &&
        input.filingDate!.isAfter(input.dueDate!)) {
      daysLate = input.filingDate!.difference(input.dueDate!).inDays;
      final perDay = input.isNilReturn ? lateFeePerDayNil : lateFeePerDay;
      lateFee = math.min(daysLate * perDay, _lateFeeCap(input));
      lines.add(LineItem(
        code: 'GST.LATE_FEE',
        label: 'Late fee ($daysLate days)',
        amount: lateFee,
        section: 's.47',
        note: 'Split equally between CGST and SGST.',
      ));
      // Interest only on the cash component (proviso to s.50(1)).
      interest = (cash.total * interestRatePercentPa / 100 * daysLate / 365).round();
      if (interest > 0) {
        lines.add(LineItem(
          code: 'GST.INTEREST',
          label: 'Interest 18% p.a. on net cash liability',
          amount: interest,
          section: 's.50(1)',
        ));
      }
    }

    return Gstr3bResult(
      outputTax: output,
      reverseCharge: rcm,
      netItc: netItc,
      itcUtilised: utilised,
      cashPayable: cash,
      closingCreditLedger: closing,
      lateFee: lateFee,
      interest: interest,
      daysLate: daysLate,
      lineItems: List.unmodifiable(lines),
      notes: List.unmodifiable(notes),
    );
  }

  /// Late-fee caps (CGST + SGST combined) notified under s.47 by turnover.
  static int _lateFeeCap(Gstr3bInput i) {
    if (i.isNilReturn) return 500;
    if (i.annualTurnover <= 15000000) return 2000;
    if (i.annualTurnover <= 50000000) return 5000;
    return 10000;
  }
}

int _i(Object? v) => v == null ? 0 : (v as num).toInt();
