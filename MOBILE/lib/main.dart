import 'package:flutter/material.dart';
import 'screens/scrLogin.dart';
import 'screens/scrUserRegister.dart';
import 'screens/scrhome.dart';
import 'screens/scrSplash.dart';
import 'services/serAuth.dart';
import 'package:provider/provider.dart';
import 'providers/proUser.dart';
//import '../../models/modUser.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UsuarioProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Serviços',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'), // Forçar português
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacao();
  }

  Future<void> _verificarAutenticacao() async {
    try {
      final resultado = await _authService.verificarAutenticacao();
      
      if (mounted) {
        if (resultado['autenticado']) {
          // Atualizar o provider com os dados do usuário
          final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
          usuarioProvider.setUsuario(
            resultado['usuario'], 
            resultado['token']
          );
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao verificar autenticação: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    // Usar o Consumer para ouvir mudanças no provider
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        if (usuarioProvider.usuario != null && usuarioProvider.token != null) {
          return HomeScreen(
            usuario: usuarioProvider.usuario!,
            token: usuarioProvider.token!,
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}