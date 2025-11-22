import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

/// CompanyProvider - Supabase-first with Hive caching
/// 
/// Write: Supabase (cloud) → Hive (local cache)
/// Read: Hive (fast) → Fallback to Supabase if missing
class CompanyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  Box? _companyBox;
  List<Company> _companies = [];

  List<Company> get companies => _companies;

  Future<void> init() async {
    if (_companyBox != null && _companyBox!.isOpen) return;
    if (!Hive.isBoxOpen('companiesBox')) {
      _companyBox = await Hive.openBox('companiesBox');
    } else {
      _companyBox = Hive.box('companiesBox');
    }
    await getAllCompanies();
  }

  /// Add a new company - saves to Supabase first, then caches in Hive
  Future<void> addCompany(Company company) async {
    if (_companyBox == null) await init();
    
    try {
      // 1. Save to Supabase (source of truth)
      await _supabase.from('companies').insert({
        'companyId': company.companyId,
        'companyName': company.companyName,
        'description': company.description,
        'logoUrl': company.logoUrl,
        'website': company.website,
        'contactNo': company.contactNo,
        'email': company.email,
        'createdAt': company.createdAt.toIso8601String(),
      });
      
      // 2. Cache in Hive
      await _companyBox!.put(company.userId, company.toMap());
      _companies.add(company);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding company to Supabase: $e');
      rethrow;
    }
  }

  /// Update company - saves to Supabase first, then updates Hive cache
  Future<void> updateCompany(Company company) async {
    if (_companyBox == null) await init();
    
    try {
      // 1. Update in Supabase (source of truth)
      await _supabase.from('companies').update({
        'companyName': company.companyName,
        'description': company.description,
        'logoUrl': company.logoUrl,
        'website': company.website,
        'contactNo': company.contactNo,
      }).eq('companyId', company.companyId);
      
      // 2. Update Hive cache
      await _companyBox!.put(company.userId, company.toMap());
      
      final index = _companies.indexWhere((e) => e.userId == company.userId);
      if (index != -1) {
        _companies[index] = company;
      } else {
        _companies.add(company);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating company in Supabase: $e');
      rethrow;
    }
  }

  /// Delete company - removes from Supabase first, then from Hive cache
  Future<void> deleteCompany(String userId) async {
    if (_companyBox == null) await init();
    
    try {
      // 1. Delete from Supabase
      await _supabase.from('companies').delete().eq('companyId', userId);
      
      // 2. Remove from Hive cache
      await _companyBox!.delete(userId);
      _companies.removeWhere((e) => e.userId == userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting company from Supabase: $e');
      rethrow;
    }
  }

  /// Get all companies from Hive cache
  Future<void> getAllCompanies() async {
    if (_companyBox == null) return;
    _companies = _companyBox!.values.map((e) =>
      Company.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    notifyListeners();
  }

  /// Fetch all companies from Supabase and refresh Hive cache
  Future<void> fetchAllCompaniesFromSupabase() async {
    if (_companyBox == null) await init();
    
    try {
      final response = await _supabase.from('companies').select();
      
      _companies = [];
      for (final data in response) {
        final map = Map<String, dynamic>.from(data);
        // Add fields needed for local model
        map['userId'] = map['companyId'];
        map['password'] = 'secured_by_supabase';
        map['userType'] = UserType.company.name;
        
        final company = Company.fromMap(map);
        _companies.add(company);
        
        // Update Hive cache
        await _companyBox!.put(company.userId, company.toMap());
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching companies from Supabase: $e');
      // Fall back to Hive cache
      await getAllCompanies();
    }
  }

  /// Get company by ID - checks Hive first, fetches from Supabase if not found
  Company? getCompanyById(String userId) {
    try {
      return _companies.firstWhere((c) => c.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Fetch single company from Supabase by ID
  Future<Company?> fetchCompanyById(String companyId) async {
    if (_companyBox == null) await init();
    
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('companyId', companyId)
          .maybeSingle();
      
      if (response == null) return null;
      
      final map = Map<String, dynamic>.from(response);
      map['userId'] = map['companyId'];
      map['password'] = 'secured_by_supabase';
      map['userType'] = UserType.company.name;
      
      final company = Company.fromMap(map);
      
      // Update Hive cache
      await _companyBox!.put(company.userId, company.toMap());
      
      // Update in-memory list
      final index = _companies.indexWhere((c) => c.userId == company.userId);
      if (index != -1) {
        _companies[index] = company;
      } else {
        _companies.add(company);
      }
      notifyListeners();
      
      return company;
    } catch (e) {
      debugPrint('Error fetching company from Supabase: $e');
      return getCompanyById(companyId);
    }
  }
}
