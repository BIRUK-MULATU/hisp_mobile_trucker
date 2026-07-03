import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
      create: (_) => AuthBloc(
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        authRepository: repository,
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // ── Navigate to Home on successful login ──
            context.go(AppRouter.home);
          }
        },
        child: const _LoginBody(),
      ),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight =
        screenHeight * AppDimensions.loginTopSectionRatio;

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
              child: _BottomCard(topSectionHeight: topSectionHeight),
            ),
          ],
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
              child: Image.asset(
                'assets/images/ethiopia_flag.png',
                fit: BoxFit.cover
              ),
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
  const _BottomCard({required this.topSectionHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft:
              Radius.circular(AppDimensions.loginCardBorderRadius),
          topRight:
              Radius.circular(AppDimensions.loginCardBorderRadius),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXXL,
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXXL,
        ),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoginInProgress;
            final errorMessage =
                state is AuthFailureState ? state.message : null;

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
    );
  }
}
