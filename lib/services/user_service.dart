import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/user_model.dart';


class UserService {
  final _db = FirebaseFirestore.instance;

  /// 🔄 STREAM USER (UTILISER PARTOUT)
  Stream<UserModel> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }
}
