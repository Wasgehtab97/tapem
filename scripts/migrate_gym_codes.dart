// scripts/migrate_gym_codes.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tapem/firebase_options_dev.dart';
import 'package:tapem/features/gym/domain/services/gym_code_service.dart';

/// Migration script to convert static gym codes to rotating codes
/// 
/// This script:
/// 1. Reads all gyms with existing 'code' field
/// 2. Creates initial rotating codes in gym_codes collection
/// 3. Sets expiration to 1 month from now
/// 4. Optionally removes old 'code' field from gyms
/// 
/// Usage: dart run scripts/migrate_gym_codes.dart [--remove-old-field]

Future<void> main(List<String> args) async {
  final removeOldField = args.contains('--remove-old-field');
  
  print('🚀 Starting Gym Code Migration...\n');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  final gymCodeService = GymCodeService(firestore: firestore);
  
  try {
    // Get all gyms
    print('📋 Fetching all gyms...');
    final gymsSnapshot = await firestore.collection('gyms').get();
    print('Found ${gymsSnapshot.docs.length} gyms\n');
    
    var successCount = 0;
    var skipCount = 0;
    var errorCount = 0;
    
    for (final gymDoc in gymsSnapshot.docs) {
      final gymId = gymDoc.id;
      final gymData = gymDoc.data();
      final gymName = gymData['name'] as String? ?? 'Unknown';
      final oldCode = gymData['code'] as String?;
      
      print('Processing: $gymName ($gymId)');
      
      // Check if gym already has rotating codes
      final existingCode = await gymCodeService.getActiveCodeForGym(gymId);
      if (existingCode != null) {
        print('  ⏭️  Already has rotating code: ${existingCode.code}');
        print('  Expires: ${existingCode.expiresAt}');
        skipCount++;
        print('');
        continue;
      }
      
      try {
        // Create code document with unique code
        final gymCode = await gymCodeService.createCode(
          gymId: gymId,
          createdBy: 'migration-script',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
        
        print('  ✅ Created rotating code: ${gymCode.code}');
        print('  Expires: ${gymCode.expiresAt}');
        
        if (oldCode != null) {
          print('  Old static code was: $oldCode');
          
          if (removeOldField) {
            await gymDoc.reference.update({
              'code': FieldValue.delete(),
            });
            print('  🗑️  Removed old code field');
          }
        }
        
        successCount++;
      } catch (e) {
        print('  ❌ Error: $e');
        errorCount++;
      }
      
      print('');
    }
    
    // Summary
    print('━' * 50);
    print('Migration Complete!\n');
    print('✅ Successfully migrated: $successCount gyms');
    print('⏭️  Skipped (already migrated): $skipCount gyms');
    if (errorCount > 0) {
      print('❌ Errors: $errorCount gyms');
    }
    print('━' * 50);
    
    if (!removeOldField && successCount > 0) {
      print('\n💡 Tip: Run with --remove-old-field to remove old code fields');
    }
    
  } catch (e, stackTrace) {
    print('❌ Migration failed: $e');
    print(stackTrace);
    exit(1);
  }
  
  exit(0);
}
