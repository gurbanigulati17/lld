import 'dart:math' as math;

import '../common/line_item.dart';
import '../common/money.dart';
import 'interest.dart';
import 'models.dart';
import 'result.dart';
import 'rule_pack.dart';

/// Deterministic income-tax computation for an individual.
///
/// The computation is an explicit pipeline, in statutory order:
///
/// 1. Income under each head (salary, house property, capital gains,
///    business, other sources) with head-specific deductions.
/// 2. Inter-head set-off of losses, then gross total income.
/// 3. Chapter VI-A deductions (old regime, plus s.80CCD(2) in both).
/// 4. Total income, rounded to ₹10 (s.288A).
/// 5. Tax at slab rates on normal income and at special rates on
///    s.111A / s.112A / s.112 gains, with the unexhausted basic exemption
///    absorbed by special-rate income for residents.
/// 6. s.87A rebate (with marginal relief in the new regime).
/// 7. Surcharge with the 15% cap on special-rate income and marginal relief.
/// 8. Health and education cess.
/// 9. Credits (TDS, TCS, advance tax, self-assessment tax) and interest
///    under ss.234A/B/C.
///
/// Every step appends [LineItem]s so the UI can show provenance.
class ItrComputer {
  const ItrComputer();

  /// Computes both regimes and recommends the cheaper one.
  RegimeComparison compare(ItrInput input) => RegimeComparison(
        oldRegime: compute(input, TaxRegime.oldRegime),
        newRegime: compute(input, TaxRegime.newRegime),
      );

  ItrComputation compute(ItrInput input, TaxRegime regime) {
    final rp = ItrRulePack.forYear(input.assessmentYear);
    final age = input.profile.ageCategoryFor(input.assessmentYear);
    final isOld = regime == TaxRegime.oldRegime;
    final lines = <LineItem>[];
    final warnings = <String>[];

    // ------------------------------------------------------------------
    // 1. Salary
    // ------------------------------------------------------------------
    var salaryIncome = 0;
    var employerNps = 0;
    final sal = input.salary;
    if (sal != null) {
      final gross = sal.grossSalary;
      lines.add(LineItem(
        code: 'SAL.GROSS',
        label: 'Gross salary',
        amount: gross,
        section: 's.17(1)',
        group: LineGroup.salary,
      ));
      var exempt = 0;
      if (isOld) {
        final hraExempt = _hraExemption(sal);
        if (hraExempt > 0) {
          lines.add(LineItem(
            code: 'SAL.HRA_EXEMPT',
            label: 'HRA exemption',
            amount: -hraExempt,
            section: 's.10(13A)',
            note: 'Least of HRA received, rent paid less 10% of basic+DA, '
                'and ${sal.isMetroCity ? 50 : 40}% of basic+DA.',
            group: LineGroup.salary,
          ));
          exempt += hraExempt;
        }
        if (sal.exemptAllowances > 0) {
          lines.add(LineItem(
            code: 'SAL.ALLOW_EXEMPT',
            label: 'Exempt allowances',
            amount: -sal.exemptAllowances,
            section: 's.10(14)',
            group: LineGroup.salary,
          ));
          exempt += sal.exemptAllowances;
        }
      } else if (sal.hraReceived > 0 || sal.exemptAllowances > 0) {
        warnings.add('HRA and s.10(14) allowance exemptions are not '
            'available in the new regime.');
      }
      final net = nonNegative(gross - exempt);
      final std = math.min(rp.standardDeductionFor(regime), net);
      lines.add(LineItem(
        code: 'SAL.STD_DED',
        label: 'Standard deduction',
        amount: -std,
        section: 's.16(ia)',
        group: LineGroup.salary,
      ));
      var profTax = 0;
      if (isOld && sal.professionalTax > 0) {
        profTax = math.min(sal.professionalTax, net - std);
        lines.add(LineItem(
          code: 'SAL.PROF_TAX',
          label: 'Professional tax',
          amount: -profTax,
          section: 's.16(iii)',
          group: LineGroup.salary,
        ));
      }
      salaryIncome = nonNegative(net - std - profTax);
      lines.add(LineItem(
        code: 'SAL.NET',
        label: 'Income from salary',
        amount: salaryIncome,
        group: LineGroup.salary,
      ));
      if (sal.employerNpsContribution > 0) {
        final cap = pct(
          sal.basic + sal.dearnessAllowance,
          rp.employerNpsCapPercentFor(regime),
        );
        employerNps = math.min(sal.employerNpsContribution, cap);
      }
    }

    // ------------------------------------------------------------------
    // 2. House property
    // ------------------------------------------------------------------
    var hpTotal = 0;
    for (var idx = 0; idx < input.houseProperties.length; idx++) {
      final hp = input.houseProperties[idx];
      final tag = input.houseProperties.length > 1 ? ' #${idx + 1}' : '';
      int income;
      if (hp.type == HousePropertyType.selfOccupied) {
        final interest = hp.interestOnLoan + hp.preConstructionInterest;
        if (isOld) {
          final allowed = math.min(interest, rp.selfOccupiedInterestCap);
          income = -allowed;
          if (allowed > 0) {
            lines.add(LineItem(
              code: 'HP.SOP_INTEREST',
              label: 'Home loan interest (self-occupied$tag)',
              amount: -allowed,
              section: 's.24(b)',
              note: 'Capped at ${formatInr(rp.selfOccupiedInterestCap)}.',
              group: LineGroup.houseProperty,
            ));
          }
        } else {
          income = 0;
          if (interest > 0) {
            warnings.add('Interest on a self-occupied property is not '
                'deductible in the new regime.');
          }
        }
      } else {
        final nav = nonNegative(hp.annualRent - hp.municipalTaxesPaid);
        final std = pct(nav, 30);
        final interest = hp.interestOnLoan + hp.preConstructionInterest;
        income = nav - std - interest;
        lines.add(LineItem(
          code: 'HP.NAV',
          label: 'Net annual value (let-out$tag)',
          amount: nav,
          section: 's.23',
          group: LineGroup.houseProperty,
        ));
        lines.add(LineItem(
          code: 'HP.STD',
          label: 'Standard deduction 30%',
          amount: -std,
          section: 's.24(a)',
          group: LineGroup.houseProperty,
        ));
        if (interest > 0) {
          lines.add(LineItem(
            code: 'HP.LO_INTEREST',
            label: 'Loan interest (let-out$tag)',
            amount: -interest,
            section: 's.24(b)',
            group: LineGroup.houseProperty,
          ));
        }
      }
      hpTotal += income;
    }
    var hpIncome = hpTotal;
    if (hpTotal < 0) {
      if (isOld) {
        final setOff = math.min(-hpTotal, rp.housePropertyLossSetOffCap);
        if (-hpTotal > setOff) {
          warnings.add('House property loss of ${formatInr(-hpTotal - setOff)} '
              'exceeds the ${formatInr(rp.housePropertyLossSetOffCap)} set-off '
              'cap and is carried forward.');
        }
        hpIncome = -setOff;
      } else {
        warnings.add('House property loss cannot be set off against other '
            'heads in the new regime (s.115BAC(2)).');
        hpIncome = 0;
      }
    }
    if (input.houseProperties.isNotEmpty) {
      lines.add(LineItem(
        code: 'HP.NET',
        label: 'Income from house property',
        amount: hpIncome,
        group: LineGroup.houseProperty,
      ));
    }

    // ------------------------------------------------------------------
    // 3. Capital gains with intra-head set-off
    // ------------------------------------------------------------------
    final cg = _CapitalGainsPool.from(input.capitalGains);
    final cgSetOff = cg.applySetOff();
    if (cgSetOff.carriedForward > 0) {
      warnings.add('Capital loss of ${formatInr(cgSetOff.carriedForward)} '
          'remains and is carried forward (8 years).');
    }
    final cgTotal = cg.net111A + cg.netStcgOther + cg.net112A + cg.netLtcgOther;
    if (input.capitalGains.isNotEmpty) {
      if (cg.netStcgOther != 0) {
        lines.add(LineItem(
          code: 'CG.STCG_OTHER',
          label: 'Short-term capital gains (slab rate)',
          amount: cg.netStcgOther,
          group: LineGroup.capitalGains,
        ));
      }
      if (cg.net111A != 0) {
        lines.add(LineItem(
          code: 'CG.STCG_111A',
          label: 'Short-term capital gains on listed equity',
          amount: cg.net111A,
          section: 's.111A',
          group: LineGroup.capitalGains,
        ));
      }
      if (cg.net112A != 0) {
        lines.add(LineItem(
          code: 'CG.LTCG_112A',
          label: 'Long-term capital gains on listed equity',
          amount: cg.net112A,
          section: 's.112A',
          note: 'First ${formatInr(rp.ltcg112AExemption)} is exempt.',
          group: LineGroup.capitalGains,
        ));
      }
      if (cg.netLtcgOther != 0) {
        lines.add(LineItem(
          code: 'CG.LTCG_OTHER',
          label: 'Long-term capital gains (other assets)',
          amount: cg.netLtcgOther,
          section: 's.112',
          group: LineGroup.capitalGains,
        ));
      }
      lines.add(LineItem(
        code: 'CG.NET',
        label: 'Income from capital gains',
        amount: cgTotal,
        group: LineGroup.capitalGains,
      ));
    }

    // ------------------------------------------------------------------
    // 4. Business / profession
    // ------------------------------------------------------------------
    var businessIncome = 0;
    final biz = input.business;
    if (biz != null) {
      switch (biz.kind) {
        case BusinessIncomeKind.regular:
          businessIncome = biz.netProfit;
          lines.add(LineItem(
            code: 'BIZ.NET',
            label: 'Profit from business or profession',
            amount: businessIncome,
            section: 's.28',
            group: LineGroup.business,
          ));
        case BusinessIncomeKind.presumptive44AD:
          final digital = math.min(biz.digitalTurnover, biz.turnover);
          final cash = biz.turnover - digital;
          final deemed = pct(cash, rp.presumptive44ADRatePercent) +
              pct(digital, rp.presumptive44ADDigitalRatePercent);
          businessIncome = math.max(deemed, biz.declaredProfit ?? 0);
          if (biz.turnover > rp.presumptive44ADTurnoverCap) {
            warnings.add('Turnover exceeds the s.44AD limit; presumptive '
                'taxation is not available.');
          } else if (biz.turnover > 20000000 && digital < pct(biz.turnover, 95)) {
            warnings.add('Turnover above ₹2 crore qualifies for s.44AD only '
                'if at least 95% of receipts are digital.');
          }
          lines.add(LineItem(
            code: 'BIZ.44AD',
            label: 'Presumptive business income',
            amount: businessIncome,
            section: 's.44AD',
            note: '${rp.presumptive44ADRatePercent}% of cash turnover '
                '${formatInr(cash)} and '
                '${rp.presumptive44ADDigitalRatePercent}% of digital turnover '
                '${formatInr(digital)}.',
            group: LineGroup.business,
          ));
        case BusinessIncomeKind.presumptive44ADA:
          final deemed = pct(biz.grossReceipts, rp.presumptive44ADARatePercent);
          businessIncome = math.max(deemed, biz.declaredProfit ?? 0);
          if (biz.grossReceipts > rp.presumptive44ADAReceiptsCap) {
            warnings.add('Gross receipts exceed the s.44ADA limit; presumptive '
                'taxation is not available.');
          } else if (biz.grossReceipts > 5000000) {
            warnings.add('Receipts above ₹50 lakh qualify for s.44ADA only '
                'if at least 95% are received digitally.');
          }
          lines.add(LineItem(
            code: 'BIZ.44ADA',
            label: 'Presumptive professional income',
            amount: businessIncome,
            section: 's.44ADA',
            note: '${rp.presumptive44ADARatePercent}% of gross receipts '
                '${formatInr(biz.grossReceipts)}.',
            group: LineGroup.business,
          ));
      }
    }

    // ------------------------------------------------------------------
    // 5. Other sources
    // ------------------------------------------------------------------
    final os = input.otherSources;
    var familyPension = os.familyPension;
    if (familyPension > 0) {
      final ded = math.min(familyPension ~/ 3, rp.familyPensionDeductionFor(regime));
      familyPension -= ded;
      lines.add(LineItem(
        code: 'OS.FAMILY_PENSION_DED',
        label: 'Family pension deduction',
        amount: -ded,
        section: 's.57(iia)',
        group: LineGroup.otherSources,
      ));
    }
    final osIncome = os.savingsInterest +
        os.fixedDepositInterest +
        os.dividends +
        os.other +
        familyPension;
    if (osIncome != 0) {
      lines.add(LineItem(
        code: 'OS.NET',
        label: 'Income from other sources',
        amount: osIncome,
        section: 's.56',
        group: LineGroup.otherSources,
      ));
    }

    // ------------------------------------------------------------------
    // 6. Inter-head set-off and gross total income
    // ------------------------------------------------------------------
    // Business loss cannot be set off against salary (s.71(2A)).
    var bizForGti = businessIncome;
    if (businessIncome < 0) {
      final nonSalary = nonNegative(hpIncome) + nonNegative(cgTotal) + osIncome;
      final setOff = math.min(-businessIncome, nonSalary);
      bizForGti = -setOff;
      if (-businessIncome > setOff) {
        warnings.add('Business loss of ${formatInr(-businessIncome - setOff)} '
            'cannot be set off against salary and is carried forward.');
      }
    }
    final gti = nonNegative(
        salaryIncome + hpIncome + cgTotal + bizForGti + osIncome);
    lines.add(LineItem(
      code: 'GTI',
      label: 'Gross total income',
      amount: gti,
      group: LineGroup.other,
    ));

    // ------------------------------------------------------------------
    // 7. Chapter VI-A deductions
    // ------------------------------------------------------------------
    final d = input.deductions;
    var deductions = 0;
    void ded(String code, String label, int amount, String section, [String? note]) {
      if (amount <= 0) return;
      deductions += amount;
      lines.add(LineItem(
        code: code,
        label: label,
        amount: -amount,
        section: section,
        note: note,
        group: LineGroup.deductions,
      ));
    }

    if (employerNps > 0) {
      ded('DED.80CCD2', 'Employer NPS contribution', employerNps, 's.80CCD(2)');
    }
    if (isOld) {
      ded('DED.80C', 'Investments under 80C', math.min(d.section80C, rp.section80CCap),
          's.80C', 'Capped at ${formatInr(rp.section80CCap)}.');
      ded('DED.80CCD1B', 'Additional NPS contribution',
          math.min(d.section80CCD1B, rp.section80CCD1BCap), 's.80CCD(1B)');
      final selfCap = age == AgeCategory.below60
          ? rp.section80DSelfCap
          : rp.section80DSelfSeniorCap;
      final parentsCap = d.parentsAreSenior
          ? rp.section80DParentsSeniorCap
          : rp.section80DParentsCap;
      ded('DED.80D', 'Health insurance (self & family)',
          math.min(d.section80D, selfCap), 's.80D');
      ded('DED.80D_PARENTS', 'Health insurance (parents)',
          math.min(d.section80DParents, parentsCap), 's.80D');
      ded('DED.80E', 'Education loan interest', d.section80E, 's.80E');
      ded('DED.80G', 'Donations', d.section80G, 's.80G');
      ded('DED.80EEA', 'Affordable housing loan interest',
          math.min(d.section80EEA, rp.section80EEACap), 's.80EEA');
      ded('DED.80U', 'Disability', d.section80U, 's.80U');
      if (age == AgeCategory.below60) {
        ded('DED.80TTA', 'Savings account interest',
            math.min(os.savingsInterest, rp.section80TTACap), 's.80TTA');
      } else {
        ded('DED.80TTB', 'Deposit interest (senior citizen)',
            math.min(os.savingsInterest + os.fixedDepositInterest, rp.section80TTBCap),
            's.80TTB');
      }
    } else if (d.section80C > 0 || d.section80D > 0 || d.section80CCD1B > 0) {
      warnings.add('Chapter VI-A deductions other than s.80CCD(2) are not '
          'available in the new regime.');
    }

    // Deductions cannot reduce special-rate income (ss.111A, 112, 112A).
    final specialGross = cg.net111A + cg.net112A + cg.netLtcgOther;
    final maxDeduction = nonNegative(gti - nonNegative(specialGross));
    if (deductions > maxDeduction) {
      warnings.add('Deductions limited to income chargeable at normal rates.');
      deductions = maxDeduction;
    }

    // ------------------------------------------------------------------
    // 8. Total income
    // ------------------------------------------------------------------
    final totalIncome = roundTo10(nonNegative(gti - deductions));
    lines.add(LineItem(
      code: 'TI',
      label: 'Total income',
      amount: totalIncome,
      section: 's.288A',
      note: 'Rounded to the nearest ₹10.',
      group: LineGroup.other,
    ));

    final special = _SpecialIncome(
      stcg111A: nonNegative(cg.net111A),
      ltcg112ATaxable: nonNegative(cg.net112A - rp.ltcg112AExemption),
      ltcgOther: nonNegative(cg.netLtcgOther),
    );
    final specialInTotal = nonNegative(cg.net111A) +
        nonNegative(cg.net112A) +
        nonNegative(cg.netLtcgOther);
    final normalIncome = nonNegative(totalIncome - specialInTotal);

    // ------------------------------------------------------------------
    // 9. Tax
    // ------------------------------------------------------------------
    final slabs = rp.slabsFor(regime, age);
    final basicExemption = slabs.first.from;
    // Residents absorb unexhausted basic exemption against special income.
    var adjustedSpecial = special;
    if (input.profile.isResident && normalIncome < basicExemption) {
      adjustedSpecial = special.absorbExemption(basicExemption - normalIncome);
    }

    final taxNormal = _slabTax(
      slabs,
      normalIncome,
      agriculturalIncome: input.agriculturalIncome,
    );
    final taxSpecial = adjustedSpecial.tax(rp);
    lines.add(LineItem(
      code: 'TAX.NORMAL',
      label: 'Tax at slab rates',
      amount: taxNormal,
      note: 'On ${formatInr(normalIncome)} of normal-rate income.',
      group: LineGroup.tax,
    ));
    if (taxSpecial > 0) {
      lines.add(LineItem(
        code: 'TAX.SPECIAL',
        label: 'Tax at special rates',
        amount: taxSpecial,
        section: 'ss.111A/112/112A',
        group: LineGroup.tax,
      ));
    }

    // s.87A rebate
    final rebateRule = rp.rebateFor(regime);
    var rebate = 0;
    final rebateBase =
        rebateRule.excludesSpecialRateIncome ? taxNormal : taxNormal + taxSpecial;
    if (input.profile.isResident) {
      if (totalIncome <= rebateRule.incomeThreshold) {
        rebate = math.min(rebateBase, rebateRule.maxRebate);
      } else if (rebateRule.marginalRelief) {
        final excess = totalIncome - rebateRule.incomeThreshold;
        if (rebateBase > excess) rebate = rebateBase - excess;
      }
    }
    if (rebate > 0) {
      lines.add(LineItem(
        code: 'TAX.REBATE',
        label: 'Rebate',
        amount: -rebate,
        section: 's.87A',
        note: totalIncome > rebateRule.incomeThreshold
            ? 'Marginal relief: tax limited to income above '
                '${formatInr(rebateRule.incomeThreshold)}.'
            : null,
        group: LineGroup.tax,
      ));
    }
    final taxAfterRebate = nonNegative(taxNormal + taxSpecial - rebate);

    // Surcharge with marginal relief
    final bands = rp.surchargeFor(regime);
    final surchargeRate = _surchargeRate(bands, totalIncome);
    var surcharge = 0;
    var relief = 0;
    if (surchargeRate > 0) {
      surcharge = _surcharge(rp, surchargeRate, taxNormal, taxSpecial);
      // Marginal relief: tax + surcharge must not exceed tax + surcharge at
      // the band threshold plus the income above the threshold.
      final threshold = _surchargeThreshold(bands, totalIncome);
      final excess = totalIncome - threshold;
      final normalAtThreshold = nonNegative(normalIncome - excess);
      final taxNormalAtT = _slabTax(slabs, normalAtThreshold,
          agriculturalIncome: input.agriculturalIncome);
      final lowerRate = _surchargeRate(bands, threshold);
      final surchargeAtT =
          lowerRate > 0 ? _surcharge(rp, lowerRate, taxNormalAtT, taxSpecial) : 0;
      final cap = taxNormalAtT + taxSpecial + surchargeAtT + excess;
      final actual = taxAfterRebate + surcharge;
      if (actual > cap) relief = actual - cap;
      lines.add(LineItem(
        code: 'TAX.SURCHARGE',
        label: 'Surcharge $surchargeRate%',
        amount: surcharge,
        group: LineGroup.tax,
      ));
      if (relief > 0) {
        lines.add(LineItem(
          code: 'TAX.MARGINAL_RELIEF',
          label: 'Marginal relief on surcharge',
          amount: -relief,
          group: LineGroup.tax,
        ));
      }
    }
    final taxPlusSurcharge = taxAfterRebate + surcharge - relief;
    final cess = pct(taxPlusSurcharge, rp.cessPercent);
    lines.add(LineItem(
      code: 'TAX.CESS',
      label: 'Health & education cess ${rp.cessPercent}%',
      amount: cess,
      group: LineGroup.tax,
    ));
    final totalTax = roundTo10(taxPlusSurcharge + cess);
    lines.add(LineItem(
      code: 'TAX.TOTAL',
      label: 'Total tax liability',
      amount: totalTax,
      section: 's.288B',
      group: LineGroup.tax,
    ));

    // ------------------------------------------------------------------
    // 10. Credits and interest
    // ------------------------------------------------------------------
    final tp = input.taxesPaid;
    final tds = (sal?.tdsOnSalary ?? 0) + tp.tdsOther + tp.tcs;
    final advance = tp.totalAdvanceTax;
    if (tds > 0) {
      lines.add(LineItem(
        code: 'CR.TDS',
        label: 'TDS / TCS',
        amount: -tds,
        group: LineGroup.credits,
      ));
    }
    if (advance > 0) {
      lines.add(LineItem(
        code: 'CR.ADVANCE',
        label: 'Advance tax',
        amount: -advance,
        group: LineGroup.credits,
      ));
    }
    if (tp.selfAssessmentTax > 0) {
      lines.add(LineItem(
        code: 'CR.SAT',
        label: 'Self-assessment tax',
        amount: -tp.selfAssessmentTax,
        group: LineGroup.credits,
      ));
    }

    final filingDate = input.filingDate ?? rp.dueDateNonAudit;
    final interest = computeInterest(InterestInput(
      assessmentYear: input.assessmentYear,
      totalTaxLiability: totalTax,
      tdsAndTcs: tds,
      advanceTaxPayments: tp.advanceTax
          .map((p) => (date: p.date, amount: p.amount))
          .toList(),
      filingDate: filingDate,
      dueDate: rp.dueDateNonAudit,
      advanceTaxThreshold: rp.advanceTaxThreshold,
      isWhollyPresumptive:
          biz != null && biz.kind != BusinessIncomeKind.regular,
    ));
    void interestLine(String code, String label, int amount, String section) {
      if (amount <= 0) return;
      lines.add(LineItem(
        code: code,
        label: label,
        amount: amount,
        section: section,
        group: LineGroup.interest,
      ));
    }

    interestLine('INT.234A', 'Interest for late filing', interest.section234A, 's.234A');
    interestLine('INT.234B', 'Interest for short advance tax', interest.section234B, 's.234B');
    interestLine('INT.234C', 'Interest for deferred instalments', interest.section234C, 's.234C');
    warnings.addAll(interest.notes);

    final netPayable =
        totalTax + interest.total - tds - advance - tp.selfAssessmentTax;
    lines.add(LineItem(
      code: netPayable >= 0 ? 'NET.PAYABLE' : 'NET.REFUND',
      label: netPayable >= 0 ? 'Tax payable' : 'Refund due',
      amount: netPayable.abs(),
      group: LineGroup.other,
    ));

    return ItrComputation(
      regime: regime,
      incomeFromSalary: salaryIncome,
      incomeFromHouseProperty: hpIncome,
      incomeFromCapitalGains: cgTotal,
      incomeFromBusiness: bizForGti,
      incomeFromOtherSources: osIncome,
      grossTotalIncome: gti,
      chapterVIADeductions: deductions,
      totalIncome: totalIncome,
      normalRateIncome: normalIncome,
      specialRateIncome: specialInTotal,
      taxOnNormalIncome: taxNormal,
      taxOnSpecialIncome: taxSpecial,
      rebate87A: rebate,
      taxAfterRebate: taxAfterRebate,
      surcharge: surcharge,
      marginalRelief: relief,
      cess: cess,
      totalTaxLiability: totalTax,
      tdsAndTcs: tds,
      advanceTaxPaid: advance,
      selfAssessmentTaxPaid: tp.selfAssessmentTax,
      interest234A: interest.section234A,
      interest234B: interest.section234B,
      interest234C: interest.section234C,
      netPayable: netPayable,
      effectiveRatePercent:
          totalIncome == 0 ? 0 : (totalTax * 10000 / totalIncome).round() / 100,
      lineItems: List.unmodifiable(lines),
      warnings: List.unmodifiable(warnings),
    );
  }

  // --------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------

  static int _hraExemption(SalaryIncome s) {
    if (s.hraReceived <= 0 || s.rentPaid <= 0) return 0;
    final salaryBase = s.basic + s.dearnessAllowance;
    final rentLess10 = s.rentPaid - pct(salaryBase, 10);
    final cityPct = pct(salaryBase, s.isMetroCity ? 50 : 40);
    return nonNegative(
        [s.hraReceived, rentLess10, cityPct].reduce(math.min));
  }

  /// Progressive slab tax. When [agriculturalIncome] exceeds ₹5,000 and
  /// non-agricultural income exceeds the basic exemption, partial
  /// integration applies: tax(normal + agri) − tax(exemption + agri).
  static int _slabTax(List<Slab> slabs, int income, {int agriculturalIncome = 0}) {
    final basic = slabs.first.from;
    if (agriculturalIncome > 5000 && income > basic) {
      return nonNegative(_rawSlabTax(slabs, income + agriculturalIncome) -
          _rawSlabTax(slabs, basic + agriculturalIncome));
    }
    return _rawSlabTax(slabs, income);
  }

  static int _rawSlabTax(List<Slab> slabs, int income) {
    var tax = 0.0;
    for (final s in slabs) {
      if (income <= s.from) break;
      final upper = s.to == null ? income : math.min(income, s.to!);
      tax += (upper - s.from) * s.ratePercent / 100;
    }
    return tax.round();
  }

  static double _surchargeRate(List<SurchargeBand> bands, int totalIncome) {
    var rate = 0.0;
    for (final b in bands) {
      if (totalIncome > b.threshold) rate = b.ratePercent;
    }
    return rate;
  }

  static int _surchargeThreshold(List<SurchargeBand> bands, int totalIncome) {
    var t = 0;
    for (final b in bands) {
      if (totalIncome > b.threshold) t = b.threshold;
    }
    return t;
  }

  static int _surcharge(ItrRulePack rp, double rate, int taxNormal, int taxSpecial) {
    final specialRate = math.min(rate, rp.specialIncomeSurchargeCapPercent);
    return pct(taxNormal, rate) + pct(taxSpecial, specialRate);
  }
}

class _SpecialIncome {
  const _SpecialIncome({
    required this.stcg111A,
    required this.ltcg112ATaxable,
    required this.ltcgOther,
  });

  final int stcg111A;
  final int ltcg112ATaxable;
  final int ltcgOther;

  /// Uses the unexhausted basic exemption against the highest-rate income
  /// first (s.111A at 20%), then the 12.5% buckets.
  _SpecialIncome absorbExemption(int room) {
    var r = room;
    final a = math.min(stcg111A, r);
    r -= a;
    final b = math.min(ltcg112ATaxable, r);
    r -= b;
    final c = math.min(ltcgOther, r);
    return _SpecialIncome(
      stcg111A: stcg111A - a,
      ltcg112ATaxable: ltcg112ATaxable - b,
      ltcgOther: ltcgOther - c,
    );
  }

  int tax(ItrRulePack rp) =>
      pct(stcg111A, rp.stcg111ARatePercent) +
      pct(ltcg112ATaxable, rp.ltcg112ARatePercent) +
      pct(ltcgOther, rp.ltcgOtherRatePercent);
}

/// Intra-head set-off of capital losses (s.70 and s.74).
///
/// Short-term losses may be set off against any capital gain; long-term
/// losses only against long-term gains. Losses are applied to the
/// highest-taxed bucket first so the taxpayer keeps the cheapest income.
class _CapitalGainsPool {
  _CapitalGainsPool(this.net111A, this.netStcgOther, this.net112A, this.netLtcgOther);

  factory _CapitalGainsPool.from(List<CapitalGain> gains) {
    var a = 0, b = 0, c = 0, d = 0;
    for (final g in gains) {
      switch (g.type) {
        case CapitalGainType.stcg111A:
          a += g.gain;
        case CapitalGainType.stcgOther:
          b += g.gain;
        case CapitalGainType.ltcg112A:
          c += g.gain;
        case CapitalGainType.ltcgOther:
          d += g.gain;
      }
    }
    return _CapitalGainsPool(a, b, c, d);
  }

  int net111A;
  int netStcgOther;
  int net112A;
  int netLtcgOther;

  ({int carriedForward}) applySetOff() {
    // Long-term losses against long-term gains.
    var ltLoss = nonNegative(-net112A) + nonNegative(-netLtcgOther);
    net112A = nonNegative(net112A);
    netLtcgOther = nonNegative(netLtcgOther);
    ltLoss = _absorb(ltLoss, (v) => netLtcgOther = v, () => netLtcgOther);
    ltLoss = _absorb(ltLoss, (v) => net112A = v, () => net112A);

    // Short-term losses against short-term gains first, then long-term.
    var stLoss = nonNegative(-net111A) + nonNegative(-netStcgOther);
    net111A = nonNegative(net111A);
    netStcgOther = nonNegative(netStcgOther);
    stLoss = _absorb(stLoss, (v) => netStcgOther = v, () => netStcgOther);
    stLoss = _absorb(stLoss, (v) => net111A = v, () => net111A);
    stLoss = _absorb(stLoss, (v) => netLtcgOther = v, () => netLtcgOther);
    stLoss = _absorb(stLoss, (v) => net112A = v, () => net112A);

    return (carriedForward: ltLoss + stLoss);
  }

  static int _absorb(int loss, void Function(int) set, int Function() get) {
    if (loss <= 0) return 0;
    final used = math.min(loss, get());
    set(get() - used);
    return loss - used;
  }
}
