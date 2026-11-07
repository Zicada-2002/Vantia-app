import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/firebase/firebase_env.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/features/collaborators/data/firebase_collaborator_repository.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';

final collaboratorRepositoryProvider = Provider<CollaboratorRepository>(
  (ref) => FirebaseCollaboratorRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: FirebaseEnv.functionsRegion),
  ),
);

final invitesProvider = StreamProvider<List<Invite>>((ref) {
  final s = ref.watch(sessionProvider);
  if (s is! SessionReady || !s.isOwner) return Stream.value(const []);
  return ref.watch(collaboratorRepositoryProvider).watchInvites(s.businessId);
});

final membersProvider = StreamProvider<List<Member>>((ref) {
  final s = ref.watch(sessionProvider);
  if (s is! SessionReady) return Stream.value(const []);
  return ref.watch(collaboratorRepositoryProvider).watchMembers(s.businessId);
});
