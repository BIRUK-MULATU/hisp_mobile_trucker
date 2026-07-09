import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../../shared/widgets/server_url_dialog.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  /// True when the user was sent here because the server rejected
  /// the stored credentials (401) — shows a short explanation.
  final bool sessionExpired;

  const LoginPage({super.key, this.sessionExpired = false});

  @override
  Widget build(BuildContext context) {
    final secureStorage = SecureStorage();
    final apiClient = ApiClient();
    final remoteDataSource = AuthRemoteDataSourceImpl(
      apiClient: apiClient,
      secureStorage: secureStorage,
    );
    final repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureStorage: secureStorage,
    );

    return BlocProvider(
      // Check for a stored session first — a previously logged-in
      // user goes straight to home, even without internet.
      create: (_) => AuthBloc(
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        authRepository: repository,
      )..add(const AuthCheckRequested()),
      child: _LoginView(sessionExpired: sessionExpired),
    );
  }
}

class _LoginView extends StatelessWidget {
  final bool sessionExpired;
  const _LoginView({required this.sessionExpired});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // ── Navigate to Home on successful login ──
            context.go(AppRouter.home);
          }
        },
        builder: (context, state) {
          // Session check in progress — show a splash instead of
          // flashing the login form at an already logged-in user.
          if (state is AuthInitial || state is AuthCheckInProgress) {
            return const AppLoader(color: Colors.white);
          }
          return _LoginBody(sessionExpired: sessionExpired);
        },
      ),
    );
  }
}

class _LoginBody extends StatelessWidget {
  final bool sessionExpired;
  const _LoginBody({required this.sessionExpired});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * AppDimensions.loginTopSectionRatio;

    return Stack(
      children: [
        Container(color: AppColors.primary),
        Column(
          children: [
            SizedBox(
              height: topSectionHeight,
              child: const _LogoSection(),
            ),
            Expanded(
              child: _BottomCard(
                topSectionHeight: topSectionHeight,
                sessionExpired: sessionExpired,
              ),
            ),
          ],
        ),
        // Offline logins are a first-class flow — show the connection
        // state before the user even types.
        const Positioned(
          top: 0,
          right: AppDimensions.space,
          child: SafeArea(child: ConnectivityIndicator()),
        ),
        // First login happens BEFORE Settings is reachable — the
        // server must be changeable from here.
        Positioned(
          top: 0,
          left: AppDimensions.spaceXS,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.dns_rounded, color: Colors.white70),
              tooltip: 'Change DHIS2 server',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final url = await showServerUrlDialog(context);
                if (url != null) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('Server set to $url'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.loginLogoSize,
              height: AppDimensions.loginLogoSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: ClipOval(
                  child: Image.asset('assets/images/ethiopia_flag.png',
                      fit: BoxFit.cover),
                ),
              ),
            ),

            // child: ClipOval(
            //   child: Image.asset(
            //     'assets/images/ethiopia_flag.png',
            //     width: AppDimensions.loginLogoSize * 0.7,
            //     height: AppDimensions.loginLogoSize * 0.7,
            //     fit: BoxFit.cover,
            //   ),
            // ),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(
              'የጤና ሚኒስቴር የጤና አመራር መረጃ ስርዓት',
              style: AppTextStyles.headingLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              'Health Management Information System',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  final double topSectionHeight;
  final bool sessionExpired;
  const _BottomCard({
    required this.topSectionHeight,
    required this.sessionExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.loginCardBorderRadius),
          topRight: Radius.circular(AppDimensions.loginCardBorderRadius),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXXL,
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXXL,
        ),
        // Cap the form width so it doesn't stretch across tablets.
        child: ResponsiveContent(
          maxWidth: AppBreakpoints.formMaxWidth,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoginInProgress;
              final errorMessage = state is AuthFailureState
                  ? state.message
                  // Until the first login attempt replaces it, explain
                  // why the user was sent back here after a 401.
                  : (sessionExpired && state is AuthUnauthenticated)
                      ? 'Your session has ended. Please log in again.'
                      : null;

              return LoginForm(
                isLoading: isLoading,
                errorMessage: errorMessage,
                onSubmit: (username, password) {
                  context.read<AuthBloc>().add(
                        LoginSubmitted(
                          username: username,
                          password: password,
                        ),
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
