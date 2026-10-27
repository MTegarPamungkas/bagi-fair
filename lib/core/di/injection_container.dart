import 'package:bagi_fair/data/datasources/cloud_gateway.dart';
import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/data/datasources/supabase_cloud_gateway.dart';
import 'package:bagi_fair/data/repositories/auth_repository_impl.dart';
import 'package:bagi_fair/data/repositories/export_repository_impl.dart';
import 'package:bagi_fair/data/repositories/group_repository_impl.dart';
import 'package:bagi_fair/data/repositories/ledger_repository_impl.dart';
import 'package:bagi_fair/data/repositories/notification_repository_impl.dart';
import 'package:bagi_fair/data/repositories/settings_repository_impl.dart';
import 'package:bagi_fair/data/services/app_links_service.dart';
import 'package:bagi_fair/data/services/notification_service.dart';
import 'package:bagi_fair/data/services/share_service.dart';
import 'package:bagi_fair/data/sync/sync_engine.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/repositories/export_repository.dart';
import 'package:bagi_fair/domain/repositories/group_repository.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:bagi_fair/domain/repositories/notification_repository.dart';
import 'package:bagi_fair/domain/repositories/receipt_repository.dart';
import 'package:bagi_fair/domain/repositories/settings_repository.dart';
import 'package:bagi_fair/domain/repositories/sync_repository.dart';
import 'package:bagi_fair/domain/usecases/auth_usecases.dart';
import 'package:bagi_fair/domain/usecases/expense_usecases.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:bagi_fair/domain/usecases/home_usecases.dart';
import 'package:bagi_fair/domain/usecases/notification_usecases.dart';
import 'package:bagi_fair/domain/usecases/settings_usecases.dart';
import 'package:bagi_fair/domain/usecases/sync_usecases.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:bagi_fair/features/groups/presentation/bloc/group_form_bloc.dart';
import 'package:bagi_fair/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:bagi_fair/features/groups/presentation/bloc/join_group_bloc.dart';
import 'package:bagi_fair/features/home/presentation/bloc/home_bloc.dart';
import 'package:bagi_fair/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:bagi_fair/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/bloc/receipt_scan_bloc.dart';
import 'package:bagi_fair/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:bagi_fair/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  required LocalStore store,
  required SupabaseClient client,
}) async {
  getIt.registerSingleton<LocalStore>(store);
  getIt.registerLazySingleton<Uuid>(() => const Uuid());

  getIt.registerLazySingleton<CloudGateway>(
    () => SupabaseCloudGateway(client),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(store, client),
  );

  getIt.registerLazySingleton<Connectivity>(Connectivity.new);
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(store),
  );
  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      store: store,
      gateway: getIt<CloudGateway>(),
      auth: getIt<AuthRepository>(),
      connectivity: getIt<Connectivity>(),
    ),
  );
  getIt.registerLazySingleton<SyncRepository>(() => getIt<SyncEngine>());
  getIt.registerLazySingleton<MutationQueue>(() => getIt<SyncEngine>());

  getIt.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(
      store: store,
      queue: getIt<MutationQueue>(),
      auth: getIt<AuthRepository>(),
      gateway: getIt<CloudGateway>(),
    ),
  );
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(store, getIt<MutationQueue>()),
  );
  getIt.registerLazySingleton<SettlementRepository>(
    () => SettlementRepositoryImpl(store, getIt<MutationQueue>()),
  );
  getIt.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(store, getIt<MutationQueue>()),
  );
  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      store,
      getIt<MutationQueue>(),
      getIt<CloudGateway>(),
    ),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(store, getIt<MutationQueue>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(store, getIt<MutationQueue>()),
  );
  getIt.registerLazySingleton<ExportRepository>(ExportRepositoryImpl.new);
  getIt.registerLazySingleton<NotificationService>(NotificationService.new);
  getIt.registerLazySingleton<ShareService>(ShareService.new);
  getIt.registerLazySingleton<AppLinksService>(AppLinksService.new);

  _registerUsecases();
  _registerBlocs();
}

void _registerUsecases() {
  getIt.registerLazySingleton<WatchAuthUser>(
    () => WatchAuthUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignInWithEmail>(
    () => SignInWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignUpWithEmail>(
    () => SignUpWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOut>(() => SignOut(getIt<AuthRepository>()));

  getIt.registerLazySingleton<WatchSettings>(
    () => WatchSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<GetSettings>(
    () => GetSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<UpdateSettings>(
    () => UpdateSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<WatchProfile>(
    () => WatchProfile(getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<GetProfile>(
    () => GetProfile(getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<SaveProfile>(
    () => SaveProfile(getIt<ProfileRepository>()),
  );

  getIt.registerLazySingleton<WatchGroups>(
    () => WatchGroups(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<WatchGroup>(
    () => WatchGroup(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<WatchGroupMembers>(
    () => WatchGroupMembers(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<GetGroup>(
    () => GetGroup(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<CreateGroup>(
    () => CreateGroup(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<UpdateGroup>(
    () => UpdateGroup(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<ArchiveGroup>(
    () => ArchiveGroup(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<CreateGroupInvite>(
    () => CreateGroupInvite(getIt<GroupRepository>()),
  );
  getIt.registerLazySingleton<JoinGroupByCode>(
    () => JoinGroupByCode(getIt<GroupRepository>()),
  );

  getIt.registerLazySingleton<WatchExpenses>(
    () => WatchExpenses(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<WatchExpense>(
    () => WatchExpense(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<GetExpense>(
    () => GetExpense(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<SaveExpense>(
    () => SaveExpense(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<DeleteExpense>(
    () => DeleteExpense(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<WatchSettlements>(
    () => WatchSettlements(getIt<SettlementRepository>()),
  );
  getIt.registerLazySingleton<SaveSettlement>(
    () => SaveSettlement(getIt<SettlementRepository>()),
  );
  getIt.registerLazySingleton<WatchActivities>(
    () => WatchActivities(getIt<ActivityRepository>()),
  );
  getIt.registerLazySingleton<LogActivity>(
    () => LogActivity(getIt<ActivityRepository>()),
  );
  getIt.registerLazySingleton<WatchReceipts>(
    () => WatchReceipts(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<GetReceipt>(
    () => GetReceipt(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<SaveReceipt>(
    () => SaveReceipt(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<ScanReceipt>(
    () => ScanReceipt(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<UploadReceiptImage>(
    () => UploadReceiptImage(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<ComputeGroupBalance>(ComputeGroupBalance.new);

  getIt.registerLazySingleton<WatchNotifications>(
    () => WatchNotifications(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<WatchUnreadNotifications>(
    () => WatchUnreadNotifications(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<SendNotification>(
    () => SendNotification(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<MarkNotificationRead>(
    () => MarkNotificationRead(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<MarkAllNotificationsRead>(
    () => MarkAllNotificationsRead(getIt<NotificationRepository>()),
  );

  getIt.registerLazySingleton<WatchSyncStatus>(
    () => WatchSyncStatus(getIt<SyncRepository>()),
  );
  getIt.registerLazySingleton<GetSyncStatus>(
    () => GetSyncStatus(getIt<SyncRepository>()),
  );
  getIt.registerLazySingleton<SyncNow>(() => SyncNow(getIt<SyncRepository>()));
  getIt.registerLazySingleton<GetPendingChanges>(
    () => GetPendingChanges(getIt<SyncRepository>()),
  );

  getIt.registerLazySingleton<WatchHomeOverview>(
    () => WatchHomeOverview(
      getIt<GroupRepository>(),
      getIt<ExpenseRepository>(),
      getIt<SettlementRepository>(),
    ),
  );
}

void _registerBlocs() {
  getIt.registerLazySingleton<SettingsBloc>(
    () => SettingsBloc(
      getIt<WatchSettings>(),
      getIt<GetSettings>(),
      getIt<UpdateSettings>(),
    ),
  );
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getIt<WatchAuthUser>(),
      getIt<SignInWithEmail>(),
      getIt<SignUpWithEmail>(),
      getIt<SignOut>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<SyncBloc>(
    () => SyncBloc(getIt<WatchSyncStatus>(), getIt<SyncNow>()),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      getIt<WatchHomeOverview>(),
      getIt<WatchNotifications>(),
      getIt<MarkNotificationRead>(),
      getIt<MarkAllNotificationsRead>(),
    ),
  );
  getIt.registerFactory<GroupsBloc>(
    () => GroupsBloc(getIt<WatchGroups>(), getIt<WatchHomeOverview>()),
  );
  getIt.registerFactory<GroupFormBloc>(
    () => GroupFormBloc(
      getIt<CreateGroup>(),
      getIt<AuthRepository>(),
      getIt<Uuid>(),
    ),
  );
  getIt.registerFactory<JoinGroupBloc>(
    () => JoinGroupBloc(getIt<JoinGroupByCode>()),
  );
  getIt.registerFactory<GroupDetailBloc>(
    () => GroupDetailBloc(
      watchGroup: getIt<WatchGroup>(),
      watchMembers: getIt<WatchGroupMembers>(),
      watchExpenses: getIt<WatchExpenses>(),
      watchSettlements: getIt<WatchSettlements>(),
      watchActivities: getIt<WatchActivities>(),
      watchReceipts: getIt<WatchReceipts>(),
      computeBalance: getIt<ComputeGroupBalance>(),
      saveSettlement: getIt<SaveSettlement>(),
      logActivity: getIt<LogActivity>(),
      deleteExpense: getIt<DeleteExpense>(),
      archiveGroup: getIt<ArchiveGroup>(),
      sendNotification: getIt<SendNotification>(),
      auth: getIt<AuthRepository>(),
      exportRepository: getIt<ExportRepository>(),
      notifications: getIt<NotificationService>(),
      uuid: getIt<Uuid>(),
    ),
  );
  getIt.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(
      getIt<WatchNotifications>(),
      getIt<MarkNotificationRead>(),
      getIt<MarkAllNotificationsRead>(),
    ),
  );
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getIt<WatchProfile>(),
      getIt<GetProfile>(),
      getIt<SaveProfile>(),
      getIt<AuthRepository>(),
      getIt<SettingsRepository>(),
    ),
  );
  getIt.registerFactory<ReceiptScanBloc>(
    () => ReceiptScanBloc(
      getGroup: getIt<GetGroup>(),
      scanReceipt: getIt<ScanReceipt>(),
      saveReceipt: getIt<SaveReceipt>(),
      uploadImage: getIt<UploadReceiptImage>(),
      logActivity: getIt<LogActivity>(),
      auth: getIt<AuthRepository>(),
      uuid: getIt<Uuid>(),
    ),
  );
  getIt.registerFactoryParam<ExpenseFormBloc, ExpenseFormRequest, void>(
    (request, _) => ExpenseFormBloc(
      getGroup: getIt<GetGroup>(),
      watchMembers: getIt<WatchGroupMembers>(),
      getExpense: getIt<GetExpense>(),
      getReceipt: getIt<GetReceipt>(),
      saveExpense: getIt<SaveExpense>(),
      saveReceipt: getIt<SaveReceipt>(),
      logActivity: getIt<LogActivity>(),
      sendNotification: getIt<SendNotification>(),
      auth: getIt<AuthRepository>(),
      notifications: getIt<NotificationService>(),
      request: request,
      uuid: getIt<Uuid>(),
    ),
  );
}
