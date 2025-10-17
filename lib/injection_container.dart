import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:navia/core/services/stt_service.dart';
import 'package:navia/core/services/voice_id_service.dart';
import 'package:navia/core/utils/secure_storage_helper.dart';
import 'core/services/background_service_manager.dart';
import 'core/services/shake_detector_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'features/auth/domain/usecases/check_if_user_exists_usecase.dart';
import 'features/auth/domain/usecases/signup_usecase.dart';
import 'features/auth/domain/usecases/verify_otp_usecase.dart';
import 'features/auth/domain/usecases/upload_voice_profile_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/main/presentation/cubit/navigation_cubit.dart';
import 'features/connectivity/presentation/cubit/connectivity_cubit.dart';

final sl = GetIt.instance;

Future<void> init({required String accessKey}) async {
  sl.registerLazySingleton(() => KeyManager(picoVoiceAccessKey: accessKey));

  // Presentation layer
  sl.registerFactory(() => AuthCubit(
    verifyOtpUsecase: sl(),
    checkIfUserExistsUsecase: sl(),
    checkAuthStatusUsecase: sl(),
    signupUsecase: sl(),
    sttService: sl(),
    voiceIdService: sl(),
    secureStorageHelper: sl(),
    authRepository: sl(),
    uploadVoiceProfileUsecase: sl(),
  ));

  //Nav Presentation
  sl.registerFactory(() => NavigationCubit());
  sl.registerFactory(() => ConnectivityCubit());


  // Domain layer
  sl.registerLazySingleton(() => VerifyOtpUsecase(repository: sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUsecase(repository: sl()));
  sl.registerLazySingleton(() => CheckIfUserExistsUsecase(repository: sl()));
  sl.registerLazySingleton(() => SignupUsecase(repository: sl()));
  sl.registerLazySingleton(() => UploadVoiceProfileUsecase(
    authRepository: sl(),
  ));

  // Data layer
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
  ));

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(
      auth: sl(),
      firestore: sl(),
      storage: sl(),
    ),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // Core & External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => STTService());
  sl.registerLazySingleton(() => VoiceIdService());
  sl.registerLazySingleton(() => SecureStorageHelper());
  sl.registerLazySingleton(() => ShakeDetectorService());
}
