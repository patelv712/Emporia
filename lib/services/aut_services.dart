import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  signInGoogle() async {
    //begin signin

    final GoogleSignInAccount? user = (await GoogleSignIn().signIn());

    //obtain auth details

    final GoogleSignInAuthentication auth = await user!.authentication;

    //create new user cred

    final cred = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    //sign in

    return await FirebaseAuth.instance.signInWithCredential(cred);
  }
}
