import 'package:flutter/material.dart';

import '../domain/models/models.dart';

class ExamCatalog {
  static const String region = 'PH';
  static const String country = 'Philippines';

  static const List<ExamDefinition> exams = [
    ExamDefinition(
      id: 'let',
      shortName: 'LET',
      fullName: 'Licensure Examination for Teachers',
      regulator: 'PRC',
      assetPath: 'assets/questions/let.json',
      description: 'GenEd and Professional Education coverage for Philippine teacher licensure.',
      accent: Color(0xFF38BDF8), // Sky blue
      accentDark: Color(0xFF0284C7),
      focusAreas: [
        'All subjects',
        'General Education',
        'Professional Education',
      ],
    ),
    ExamDefinition(
      id: 'pnle',
      shortName: 'PNLE',
      fullName: 'Philippine Nurse Licensure Examination',
      regulator: 'PRC',
      assetPath: 'assets/questions/pnle.json',
      description: 'Nursing practice areas aligned with Philippine board exam domains.',
      accent: Color(0xFF86EFAC), // Light green
      accentDark: Color(0xFF16A34A),
      focusAreas: [
        'All subjects',
        'Nursing Practice I - Community Health',
        'Nursing Practice II - Maternal and Child',
        'Nursing Practice III - Medical-Surgical',
        'Nursing Practice IV - Mental Health',
        'Nursing Practice V - Nursing Care Management',
      ],
    ),
    ExamDefinition(
      id: 'cpale',
      shortName: 'CPALE',
      fullName: 'CPA Licensure Examination',
      regulator: 'PRC',
      assetPath: 'assets/questions/cpale.json',
      description: 'FAR, AFAR, MAS, Auditing, Taxation, and RFBT for Philippine CPAs.',
      accent: Color(0xFFFBBF24), // Amber / finance gold
      accentDark: Color(0xFFB45309),
      focusAreas: [
        'All subjects',
        'Financial Accounting and Reporting',
        'Advanced Financial Accounting and Reporting',
        'Management Advisory Services',
        'Auditing',
        'Taxation',
        'Regulatory Framework for Business Transactions',
      ],
    ),
    ExamDefinition(
      id: 'cele',
      shortName: 'CELE',
      fullName: 'Civil Engineers Licensure Examination',
      regulator: 'PRC',
      assetPath: 'assets/questions/cele.json',
      description: 'Math, hydraulics/geotech, and structural/construction topics for CELE.',
      accent: Color(0xFF94A3B8), // Engineering grey
      accentDark: Color(0xFF475569),
      focusAreas: [
        'All subjects',
        'Mathematics',
        'Hydraulics and Geotechnical Engineering',
        'Structural Engineering and Construction',
      ],
    ),
    ExamDefinition(
      id: 'cse',
      shortName: 'CSE',
      fullName: 'Civil Service Examination',
      regulator: 'CSC',
      assetPath: 'assets/questions/cse.json',
      description: 'Verbal, numerical, analytical, and general information for CSC exams.',
      accent: Color(0xFF818CF8), // Indigo
      accentDark: Color(0xFF4338CA),
      passingScorePercent: 75,
      focusAreas: [
        'All subjects',
        'General Information',
        'Numerical Ability',
        'Analytical Ability',
        'Verbal Ability',
      ],
    ),
    ExamDefinition(
      id: 'ale',
      shortName: 'ALE',
      fullName: 'Agriculturist Licensure Examination',
      regulator: 'PRC',
      assetPath: 'assets/questions/ale.json',
      description: 'Crop, soil, animal, protection, economics, and extension for PH agriculturists.',
      accent: Color(0xFFA3E635), // Lime / agriculture
      accentDark: Color(0xFF4D7C0F),
      passingScorePercent: 75,
      focusAreas: [
        'All subjects',
        'Crop Science',
        'Soil Science',
        'Crop Protection',
        'Animal Science',
        'Agricultural Economics and Marketing',
        'Agricultural Extension and Communication',
      ],
    ),
    ExamDefinition(
      id: 'cle',
      shortName: 'CLE',
      fullName: 'Criminologists Licensure Examination',
      regulator: 'PRC',
      assetPath: 'assets/questions/cle.json',
      description: 'Criminal law, LEA, CDI, criminalistics, corrections, and sociology/ethics.',
      accent: Color(0xFFFB7185), // Rose
      accentDark: Color(0xFFBE123C),
      focusAreas: [
        'All subjects',
        'Criminal Law and Jurisprudence',
        'Law Enforcement Administration',
        'Crime Detection and Investigation',
        'Criminalistics',
        'Correctional Administration',
        'Criminal Sociology and Ethics',
      ],
    ),
  ];

  static ExamDefinition byId(String id) =>
      exams.firstWhere((e) => e.id == id, orElse: () => exams.first);
}
