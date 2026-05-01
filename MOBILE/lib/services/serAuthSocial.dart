// services/social_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '940734154615-9k12v7i5bf9uisugjskcfiif2tpeaste.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Login com Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Tentar fazer logout se houver sessão ativa
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        //print('Erro ao fazer logout (ignorando): $e');
        // Continua mesmo com erro no logout
      }
      
      // Pequena pausa
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Tentar login
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'error': 'Login cancelado pelo usuário'};
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final String? idToken = googleAuth.idToken;
      
      //print('Email: ${googleUser.email}');
      //print('ID Token obtido: ${idToken != null ? "Sim" : "Não"}');
      
      if (idToken == null) {
        return {'success': false, 'error': 'Token não obtido'};
      }

      return {
        'success': true,
        'token': idToken,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photoUrl': googleUser.photoUrl,
      };
    } catch (e) {
      //print('Erro no login com Google: $e');
      
      // Se o erro for relacionado a disconnect, tentar novamente sem logout
      if (e.toString().contains('disconnect')) {
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser != null) {
            final googleAuth = await googleUser.authentication;
            if (googleAuth.idToken != null) {
              return {
                'success': true,
                'token': googleAuth.idToken,
                'email': googleUser.email,
                'name': googleUser.displayName ?? '',
                'photoUrl': googleUser.photoUrl,
              };
            }
          }
        } catch (retryError) {
          //print('Erro na tentativa de retry: $retryError');
        }
      }
      
      return {'success': false, 'error': e.toString()};
    }
  }

  // Login com Apple
  Future<Map<String, dynamic>> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      return {
        'success': true,
        'token': credential.authorizationCode,
        'email': credential.email ?? '',
        'name': credential.givenName ?? '',
        'userId': credential.userIdentifier,
      };
    } catch (e) {
      print('Erro no login com Apple: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Logout das redes sociais
  Future<void> logoutFromSocial() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Erro no logout (ignorando): $e');
    }
  }
  
  // Verificar se está logado
  Future<bool> isGoogleSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }
}