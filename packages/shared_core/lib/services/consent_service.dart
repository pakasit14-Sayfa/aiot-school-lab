import '../models/consent_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// PDPA consent — มุมมองผู้ปกครอง (ดู/ให้/ถอน consent) และมุมมอง School Admin
/// (publish/retire consent policy version)
class ConsentService {
  static Future<List<MyParentLink>> listMyParentLinks() async {
    final rows =
        await supabase.rpc(
              'list_my_parent_links',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map((row) => MyParentLink.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ParentConsent>> listMyConsents(String parentLinkId) async {
    final rows =
        await supabase.rpc(
              'list_my_consents',
              params: {
                'p_token': AuthService.sessionToken,
                'p_parent_link_id': parentLinkId,
              },
            )
            as List;
    return rows
        .map((row) => ParentConsent.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> grantParentConsent({
    required String parentLinkId,
    required String policyId,
  }) async {
    await supabase.rpc(
      'grant_parent_consent',
      params: {
        'p_token': AuthService.sessionToken,
        'p_parent_link_id': parentLinkId,
        'p_policy_id': policyId,
        'p_evidence': {'confirmed_read': true, 'channel': 'flutter_parent_app'},
      },
    );
  }

  static Future<void> withdrawParentConsent(String consentId) async {
    await supabase.rpc(
      'withdraw_parent_consent',
      params: {
        'p_token': AuthService.sessionToken,
        'p_consent_id': consentId,
        'p_reason': 'withdrawn_by_parent_in_app',
      },
    );
  }

  static Future<List<AdminConsentPolicy>> listAdminConsentPolicies() async {
    final rows =
        await supabase.rpc(
              'list_consent_policies_admin',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map((row) => AdminConsentPolicy.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> publishConsentPolicy({
    required String consentType,
    required String version,
    required String documentHash,
    required String contentUrl,
    required bool isRequired,
  }) async {
    await supabase.rpc(
      'publish_consent_policy',
      params: {
        'p_token': AuthService.sessionToken,
        'p_consent_type': consentType.trim(),
        'p_version': version.trim(),
        'p_document_hash': documentHash.trim().toLowerCase(),
        'p_content_url': contentUrl.trim(),
        'p_is_required': isRequired,
      },
    );
  }

  static Future<void> retireConsentPolicy(String policyId) async {
    await supabase.rpc(
      'retire_consent_policy',
      params: {'p_token': AuthService.sessionToken, 'p_policy_id': policyId},
    );
  }
}
