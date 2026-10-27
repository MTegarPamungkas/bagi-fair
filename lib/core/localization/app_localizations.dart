import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:flutter/material.dart';

/// Compile-safe ID/EN localization. Keeping both languages next to each other
/// makes it obvious when a new screen still needs a translation.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [Locale('id'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isId => locale.languageCode != 'en';

  String t(String id, String en) => isId ? id : en;

  String get languageName => isId ? 'Bahasa Indonesia' : 'English';

  String get appName => 'Bagi Fair';

  String get tagline => t('Bagi adil, tanpa baper.', 'Fair splits, no drama.');

  String get taglineShort => t('Bagi adil.', 'Split fair.');

  String get fair => t('Adil', 'Fair');

  // ---------------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------------

  String get save => t('Simpan', 'Save');
  String get cancel => t('Batal', 'Cancel');
  String get delete => t('Hapus', 'Delete');
  String get edit => t('Ubah', 'Edit');
  String get close => t('Tutup', 'Close');
  String get back => t('Kembali', 'Back');
  String get next => t('Lanjut', 'Next');
  String get done => t('Selesai', 'Done');
  String get confirm => t('Konfirmasi', 'Confirm');
  String get retry => t('Coba lagi', 'Try again');
  String get loading => t('Sebentar…', 'One moment…');
  String get add => t('Tambah', 'Add');
  String get search => t('Cari…', 'Search…');
  String get all => t('Semua', 'All');
  String get none => t('Tidak ada', 'None');
  String get or => t('atau', 'or');
  String get optional => t('opsional', 'optional');
  String get you => t('Kamu', 'You');
  String get today => t('Hari ini', 'Today');
  String get yesterday => t('Kemarin', 'Yesterday');
  String get perPerson => t('per orang', 'per person');
  String get copy => t('Salin', 'Copy');
  String get copied => t('Disalin.', 'Copied.');
  String get share => t('Bagikan', 'Share');
  String get dismiss => t('Tutup', 'Dismiss');
  String get somethingWrong => t(
    'Ada yang tidak beres. Coba lagi ya.',
    'Something went wrong. Try again.',
  );
  String get offline => t('Offline', 'Offline');
  String get syncing => t('Menyinkronkan…', 'Syncing…');
  String get synced => t('Tersinkron', 'Synced');
  String get pendingSync => t('Menunggu sinkron', 'Waiting to sync');
  String get syncNow => t('Sinkronkan sekarang', 'Sync now');
  String get localMode => t('Mode lokal', 'Local mode');
  String get cloudMode => t('Tersambung ke cloud', 'Connected to cloud');

  String membersCount(int count) => t('$count anggota', '$count members');

  String expenseCount(int count) => t('$count pengeluaran', '$count expenses');

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  String get welcomeTitle =>
      t('Patungan tanpa drama.', 'Split bills, keep friends.');
  String get welcomeBody => t(
    'Bagi struk, pajak, dan service charge dengan adil. Semua orang tahu angkanya dari mana.',
    'Split receipts, tax, and service charge fairly. Everyone sees where every number comes from.',
  );
  String get signIn => t('Masuk', 'Sign in');
  String get signUp => t('Daftar', 'Create account');
  String get signInSubtitle =>
      t('Lanjutkan urusan patunganmu.', 'Pick up where your group left off.');
  String get signUpSubtitle =>
      t('Buat akun, langsung bagi adil.', 'Create an account and split fair.');
  String get createAccount => t('Buat akun', 'Create account');
  String get welcomeBack => t('Selamat datang lagi', 'Welcome back');
  String get email => t('Email', 'Email');
  String get password => t('Kata sandi', 'Password');
  String get displayName => t('Nama kamu', 'Your name');
  String get noAccount => t('Belum punya akun?', 'New here?');
  String get haveAccount => t('Sudah punya akun?', 'Already have an account?');
  String get emailRequired => t('Email wajib diisi.', 'Email is required.');
  String get emailInvalid =>
      t('Format email belum benar.', 'Enter a valid email.');
  String get passwordRequired =>
      t('Kata sandi wajib diisi.', 'Password is required.');
  String get passwordShort =>
      t('Kata sandi minimal 6 karakter.', 'Use at least 6 characters.');
  String get nameRequired => t('Nama wajib diisi.', 'Name is required.');
  String get invalidCredentials =>
      t('Email atau kata sandi salah.', 'Incorrect email or password.');
  String get emailInUse => t(
    'Email ini sudah terdaftar. Coba masuk.',
    'This email is already registered.',
  );
  String get emailNotConfirmed => t(
    'Cek email untuk konfirmasi, lalu masuk kembali.',
    'Check your email to confirm, then sign in.',
  );
  String get emailRateLimit => t(
    'Terlalu banyak percobaan. Coba lagi nanti.',
    'Too many attempts. Try later.',
  );
  String get networkError =>
      t('Koneksi bermasalah. Coba lagi.', 'Connection problem. Try again.');
  String get emailConfirmationSent => t(
    'Akun dibuat. Cek email untuk konfirmasi ya.',
    'Account created. Check your email to confirm.',
  );
  String get authSecureNote => t(
    'Data dilindungi Row Level Security. Hanya anggota grup yang bisa melihat.',
    'Protected by Row Level Security. Only group members can see it.',
  );

  // ---------------------------------------------------------------------------
  // Navigation / home
  // ---------------------------------------------------------------------------

  String get home => t('Beranda', 'Home');
  String get groups => t('Grup', 'Groups');
  String get notifications => t('Notifikasi', 'Notifications');
  String get settings => t('Pengaturan', 'Settings');
  String get homeEyebrow => t('Ringkasan', 'Overview');
  String get homeTitle => t('Semua tetap adil.', 'Everyone stays even.');
  String get homeSubtitle => t(
    'Lihat siapa berutang ke siapa, lalu bereskan tanpa canggung.',
    'See who owes whom, then settle up without the awkwardness.',
  );
  String greeting(String name) => t('Halo, $name', 'Hi, $name');
  String get youOwe => t('Kamu utang', 'You owe');
  String get youAreOwed => t('Kamu menagih', 'Owed to you');
  String get netPosition => t('Posisi kamu', 'Your position');
  String get impas => t('Impas', 'Even');
  String get impasTitle => t('Semua impas!', 'All even!');
  String get impasBody => t(
    'Tidak ada utang tersisa di grup ini. Bagi adil, tanpa baper.',
    'No outstanding debt in this group. Fair splits, no drama.',
  );
  String get activeGroups => t('Grup aktif', 'Active groups');
  String get seeAll => t('Lihat semua', 'See all');
  String get recentExpenses => t('Pengeluaran terbaru', 'Recent expenses');
  String get recentActivity => t('Aktivitas terbaru', 'Recent activity');
  String get noGroups => t('Belum ada grup', 'No groups yet');
  String get noGroupsBody => t(
    'Buat grup trip, kos, atau nongkrong. Lalu undang teman lewat link.',
    'Create a trip, rent, or hangout group. Then invite friends with a link.',
  );
  String get createFirstGroup =>
      t('Buat grup pertama', 'Create your first group');
  String get noExpenses => t('Belum ada pengeluaran', 'No expenses yet');
  String get noExpensesBody => t(
    'Catat yang pertama, atau scan struk biar cepat.',
    'Add the first one, or scan a receipt to go faster.',
  );
  String get addExpense => t('Catat pengeluaran', 'Add expense');
  String get newGroup => t('Grup baru', 'New group');
  String get joinGroup => t('Gabung grup', 'Join group');
  String get scanReceipt => t('Scan struk', 'Scan receipt');
  String get settleUp => t('Lunaskan', 'Settle up');
  String get quickActions => t('Aksi cepat', 'Quick actions');
  String get acrossGroups => t('di semua grup', 'across groups');
  String get noPending => t('Tidak ada antrean.', 'Nothing in the queue.');
  String get syncedJustNow => t('Baru saja tersinkron', 'Synced just now');

  // ---------------------------------------------------------------------------
  // Groups
  // ---------------------------------------------------------------------------

  String get groupsTitle => t('Grup kamu', 'Your groups');
  String get groupsSubtitle => t(
    'Satu tempat untuk trip, kos, dan nongkrong.',
    'One place for trips, rent, and hangouts.',
  );
  String get groupName => t('Nama grup', 'Group name');
  String get groupNameHint => t('Contoh: Bali Trip', 'e.g. Bali Trip');
  String get groupDescription => t('Catatan singkat', 'Short note');
  String get groupDescriptionHint =>
      t('Contoh: 4 hari 3 malam, patungan.', 'e.g. 4 days, split everything.');
  String get groupEmoji => t('Emoji', 'Emoji');
  String get groupCurrency => t('Mata uang grup', 'Group currency');
  String get groupType => t('Jenis grup', 'Group type');
  String get trip => t('Trip', 'Trip');
  String get kos => t('Kos', 'Rent');
  String get hangout => t('Nongkrong', 'Hangout');
  String get other => t('Lainnya', 'Other');
  String get createGroup => t('Buat grup', 'Create group');
  String get groupCreated => t('Grup berhasil dibuat.', 'Group created.');
  String get groupUpdated => t('Grup diperbarui.', 'Group updated.');
  String get groupArchived => t('Grup diarsipkan.', 'Group archived.');
  String get archiveGroup => t('Arsipkan grup', 'Archive group');
  String get archiveGroupBody => t(
    'Grup akan hilang dari beranda. Riwayat tetap tersimpan.',
    'The group disappears from home. History is kept.',
  );
  String get members => t('Anggota', 'Members');
  String get member => t('anggota', 'member');
  String get noMembers => t('Belum ada anggota lain.', 'No other members yet.');
  String get inviteFriends => t('Undang teman', 'Invite friends');
  String get inviteLink => t('Link undangan', 'Invite link');
  String get copyLink => t('Salin link', 'Copy link');
  String get linkCopied => t('Link undangan disalin.', 'Invite link copied.');
  String get shareInvite => t('Bagikan link', 'Share link');
  String get shareWhatsApp => t('Kirim ke WhatsApp', 'Send to WhatsApp');
  String get inviteCode => t('Kode undangan', 'Invite code');
  String get joinTitle => t('Gabung grup', 'Join a group');
  String get joinSubtitle => t(
    'Tempel link undangan atau masukkan kode 7 karakter.',
    'Paste an invite link or enter the 7-character code.',
  );
  String get joinCodeHint => t('Contoh: SENJA123', 'e.g. SENJA123');
  String get join => t('Gabung', 'Join');
  String get joinedGroup =>
      t('Kamu bergabung ke grup.', 'You joined the group.');
  String get invalidCode =>
      t('Kode undangan tidak ditemukan.', 'Invite code not found.');
  String get alreadyMember =>
      t('Kamu sudah ada di grup ini.', 'You are already in this group.');
  String get inviteExpired =>
      t('Link undangan sudah kedaluwarsa.', 'This invite has expired.');
  String get inviteNotFound =>
      t('Undangan tidak ditemukan.', 'Invite not found.');
  String get groupNotFound => t('Grup tidak ditemukan.', 'Group not found.');
  String get demoJoinHint => t(
    'Coba kode SENJA123 untuk melihat alur undangan di mode demo.',
    'Try code SENJA123 to see the invite flow in demo mode.',
  );
  String get owner => t('Pemilik', 'Owner');
  String get admin => t('Admin', 'Admin');
  String get memberRole => t('Anggota', 'Member');
  String get groupOverview => t('Ringkasan', 'Overview');
  String get inviteSheetTitle =>
      t('Ajak teman, bagi adil', 'Bring friends, split fair');
  String get inviteSheetBody => t(
    'Siapa pun dengan link ini bisa bergabung sebagai anggota. Link berlaku 7 hari.',
    'Anyone with this link can join as a member. The link is valid for 7 days.',
  );
  String get refreshLink => t('Buat link baru', 'New link');
  String get shareGroupSummary => t('Share ringkasan', 'Share summary');
  String get groupSettings => t('Pengaturan grup', 'Group settings');

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------

  String get expenses => t('Pengeluaran', 'Expenses');
  String get addExpenseTitle => t('Pengeluaran baru', 'New expense');
  String get editExpense => t('Ubah pengeluaran', 'Edit expense');
  String get expenseTitle => t('Untuk apa?', 'What was it for?');
  String get expenseTitleHint => t('Contoh: Makan malam', 'e.g. Dinner');
  String get amount => t('Nominal', 'Amount');
  String get currency => t('Mata uang', 'Currency');
  String get paidBy => t('Dibayar oleh', 'Paid by');
  String get splitMode => t('Cara bagi', 'Split mode');
  String get equal => t('Rata', 'Equally');
  String get percentage => t('Persentase', 'Percentage');
  String get exact => t('Nominal custom', 'Custom amounts');
  String get itemized => t('Per item', 'Per item');
  String get participants => t('Yang ikut', 'Participants');
  String get selectAll => t('Pilih semua', 'Select all');
  String get clearAll => t('Kosongkan', 'Clear');
  String get note => t('Catatan', 'Note');
  String get noteHint =>
      t('Opsional, misal patungan dengan Sinta.', 'Optional note.');
  String get date => t('Tanggal', 'Date');
  String get category => t('Kategori', 'Category');
  String get saveExpense => t('Simpan pengeluaran', 'Save expense');
  String get updateExpense => t('Simpan perubahan', 'Save changes');
  String get expenseSaved => t('Pengeluaran tersimpan.', 'Expense saved.');
  String get expenseDeleted => t('Pengeluaran dihapus.', 'Expense deleted.');
  String get deleteExpenseTitle => t('Hapus pengeluaran?', 'Delete expense?');
  String get deleteExpenseBody => t(
    'Saldo semua anggota akan dihitung ulang.',
    'Everyone’s balance will be recalculated.',
  );
  String get amountRequired =>
      t('Nominal harus lebih dari 0.', 'Amount must be greater than 0.');
  String get titleRequired => t('Isi keterangan pengeluaran.', 'Add a title.');
  String get payerRequired =>
      t('Pilih siapa yang membayar.', 'Choose who paid.');
  String get participantRequired =>
      t('Pilih minimal satu peserta.', 'Pick at least one participant.');
  String get itemsRequired =>
      t('Tambahkan minimal satu item.', 'Add at least one item.');
  String get itemUnassigned =>
      t('Setiap item harus punya pemilik.', 'Every item needs an owner.');
  String get percentageTotal =>
      t('Total persentase harus 100%.', 'Percentages must total 100%.');
  String get exactTotal => t(
    'Total nominal custom harus sama dengan nominal pengeluaran.',
    'Custom amounts must equal the expense total.',
  );
  String get splitTaxService => t('Pajak & service', 'Tax & service');
  String get tax => t('Pajak', 'Tax');
  String get service => t('Service charge', 'Service charge');
  String get discount => t('Diskon', 'Discount');
  String get subtotal => t('Subtotal', 'Subtotal');
  String get total => t('Total', 'Total');
  String get itemSubtotal => t('Subtotal item', 'Item subtotal');
  String get taxShare => t('Bagian pajak', 'Tax share');
  String get serviceShare => t('Bagian service', 'Service share');
  String get discountShare => t('Bagian diskon', 'Discount share');
  String get rounding => t('Pembulatan struk', 'Receipt rounding');
  String get breakdown => t('Rincian', 'Breakdown');
  String get whyThis => t('Kenapa angkanya segini?', 'Why this amount?');
  String get whyThisSubtitle => t(
    'Transparan per orang, supaya tidak ada yang baper.',
    'A transparent per-person calculation, so nobody feels shortchanged.',
  );
  String get perItem => t('Per item', 'Per item');
  String get addItem => t('Tambah item', 'Add item');
  String get itemName => t('Nama item', 'Item name');
  String get itemPrice => t('Harga', 'Price');
  String get quantity => t('Qty', 'Qty');
  String get assignPeople => t('Siapa yang makan/ikut?', 'Who is this for?');
  String get assignHint => t(
    'Ketuk nama untuk menandai pemilik item.',
    'Tap names to assign the item.',
  );
  String get everyone => t('Semua', 'Everyone');
  String get unassigned => t('Belum ditandai', 'Unassigned');
  String get paid => t('Dibayar', 'Paid');
  String get owes => t('Utang', 'Owes');
  String get isOwed => t('Dihutangi', 'Owed');
  String get expenseDetail => t('Detail pengeluaran', 'Expense detail');
  String get originalAmount => t('Nominal asli', 'Original amount');
  String get exchangeRate => t('Kurs', 'Exchange rate');
  String get convertedTotal =>
      t('Total di mata uang grup', 'Total in group currency');
  String get fxHint => t(
    'Contoh: 1 USD = 16.200 IDR. Isi 16200.',
    'e.g. 1 USD = 16,200 IDR. Enter 16200.',
  );
  String get splitModeEqualHint => t(
    'Dibagi rata ke semua peserta, sisa pembulatan dibagi otomatis.',
    'Split equally; rounding goes out automatically.',
  );
  String get splitModePercentageHint => t(
    'Atur porsi tiap orang. Total harus 100%.',
    'Set each person’s share. It must total 100%.',
  );
  String get splitModeExactHint => t(
    'Isi nominal tiap orang. Total harus sama dengan nominal.',
    'Enter each amount. It must equal the total.',
  );
  String get splitModeItemizedHint => t(
    'Tandai item untuk tiap orang. Pajak dan service dibagi proporsional.',
    'Assign items. Tax and service are split proportionally.',
  );
  String get receiptLinked => t('Terhubung ke struk', 'Linked to receipt');
  String get viewReceipt => t('Lihat struk', 'View receipt');
  String get noShare => t('Tidak ikut', 'Not involved');
  String get weight => t('Porsi', 'Share');
  String get shareOfTotal => t('dari total', 'of total');
  String get paidByLower => t('dibayar oleh', 'paid by');

  String categoryName(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => t('Makan', 'Food'),
    ExpenseCategory.transport => t('Transport', 'Transport'),
    ExpenseCategory.stay => t('Penginapan', 'Stay'),
    ExpenseCategory.groceries => t('Belanja harian', 'Groceries'),
    ExpenseCategory.utilities => t('Utilitas', 'Utilities'),
    ExpenseCategory.fun => t('Hiburan', 'Fun'),
    ExpenseCategory.shopping => t('Belanja', 'Shopping'),
    ExpenseCategory.other => t('Lainnya', 'Other'),
  };

  String splitModeName(SplitMode mode) => switch (mode) {
    SplitMode.equal => equal,
    SplitMode.percentage => percentage,
    SplitMode.exact => exact,
    SplitMode.itemized => itemized,
  };

  String groupTypeName(GroupType type) => switch (type) {
    GroupType.trip => trip,
    GroupType.kos => kos,
    GroupType.hangout => hangout,
    GroupType.other => other,
  };

  String roleName(GroupRole role) => switch (role) {
    GroupRole.owner => owner,
    GroupRole.admin => admin,
    GroupRole.member => memberRole,
  };

  // ---------------------------------------------------------------------------
  // Balances / settle
  // ---------------------------------------------------------------------------

  String get balances => t('Saldo', 'Balances');
  String get settleTitle => t('Lunaskan', 'Settle up');
  String get settleSubtitle => t(
    'Transfer paling sedikit, bukan yang paling ribet.',
    'The fewest transfers, not the most awkward ones.',
  );
  String get simplestTransfers => t('Cara paling simpel', 'Simplest way');
  String get noTransfers =>
      t('Tidak ada transfer yang dibutuhkan.', 'No transfers needed.');
  String get totalGroupSpend => t('Total pengeluaran grup', 'Group total');
  String get yourShare => t('Bagianmu', 'Your share');
  String get whoOwesWhom => t('Siapa ke siapa', 'Who owes whom');
  String get settleWith => t('Lunaskan ke', 'Settle with');
  String get settlementAmount => t('Nominal pelunasan', 'Amount');
  String get settlementNote => t('Catatan transfer', 'Transfer note');
  String get settlementNoteHint =>
      t('Contoh: BCA, sudah transfer', 'e.g. paid via bank transfer');
  String get markSettled => t('Tandai lunas', 'Mark settled');
  String get settlementSaved => t(
    'Pelunasan tercatat. Makin impas!',
    'Settlement saved. Closer to even!',
  );
  String get settlementHistory => t('Riwayat pelunasan', 'Settlement history');
  String get settlementFromTo => t('membayar', 'paid');
  String get noSettlements => t('Belum ada pelunasan.', 'No settlements yet.');
  String get nudgeFriend => t('Colek halus', 'Gentle nudge');
  String get nudgeTitle => t('Colek halus', 'Gentle nudge');
  String get nudgeBody => t(
    'Pesan yang sopan, tanpa nyindir. Pilih teman yang mau diingatkan.',
    'A polite reminder, no passive-aggression. Pick who to nudge.',
  );
  String get nudgeSent => t('Colek halus terkirim.', 'Gentle nudge sent.');
  String get nudgeMessage => t('Pesan', 'Message');
  String get sendNudge => t('Kirim colek', 'Send nudge');
  String get nudgeAlreadyEven => t(
    'Orang ini sudah impas. Tidak perlu dicolek.',
    'This person is already even.',
  );
  String get settleAllTransfers => t('Tandai semua lunas', 'Settle all');
  String get settleAllBody => t(
    'Semua transfer di atas akan dicatat sebagai pelunasan. Lanjut?',
    'All transfers above will be recorded as settlements. Continue?',
  );
  String get settledAll =>
      t('Semua pelunasan tercatat.', 'All settlements recorded.');
  String get balanceAfter =>
      t('Sisa setelah pelunasan', 'Remaining after settlement');

  // ---------------------------------------------------------------------------
  // Receipt / AI
  // ---------------------------------------------------------------------------

  String get scanTitle => t('Scan struk', 'Scan receipt');
  String get scanSubtitle => t(
    'Foto struk, AI baca itemnya, kamu yang memutuskan.',
    'Snap the receipt, AI reads it, you decide who had what.',
  );
  String get takePhoto => t('Kamera', 'Camera');
  String get choosePhoto => t('Pilih foto', 'Choose photo');
  String get scanningReceipt => t('Membaca struk…', 'Reading receipt…');
  String get scanFailed => t('Scan belum berhasil', 'Scan did not work');
  String get scanFailedBody => t(
    'Foto kurang jelas atau layanan AI sedang sibuk. Kamu tetap bisa input manual.',
    'The photo was unclear or the AI is busy. You can still enter it manually.',
  );
  String get manualEntry => t('Input manual', 'Enter manually');
  String get reviewReceipt => t('Cek hasil scan', 'Review scan');
  String get reviewSubtitle => t(
    'Koreksi kalau ada yang meleset. Tidak ada data yang disimpan tanpa persetujuanmu.',
    'Fix anything that looks off. Nothing is saved without your approval.',
  );
  String get merchant => t('Toko', 'Merchant');
  String get receiptDate => t('Tanggal struk', 'Receipt date');
  String get receiptItems => t('Item struk', 'Receipt items');
  String get saveReceipt => t('Simpan & lanjut bagi', 'Save & split');
  String get receiptSaved => t('Struk dikonfirmasi.', 'Receipt confirmed.');
  String get aiPowered => t('Ditenagai AI', 'AI powered');
  String get aiPrivacy => t(
    'Gambar dikirim ke Edge Function dan tidak menyimpan API key di aplikasi.',
    'The image goes to an Edge Function; the API key never ships in the app.',
  );
  String get rateLimited => t('Kuota scan habis', 'Scan quota reached');
  String get rateLimitBody => t(
    'Batas 10 scan per jam per pengguna. Coba lagi nanti atau input manual.',
    'Limit is 10 scans per hour per user. Try later or enter manually.',
  );
  String get imageTooLarge =>
      t('Foto terlalu besar. Coba foto ulang.', 'Image too large. Try again.');
  String get scanDemo => t('Isi contoh struk', 'Use sample receipt');
  String get aiNeedsCloud => t(
    'Scan AI tidak bisa dihubungi sekarang. Coba lagi atau input manual.',
    'AI scan is unreachable right now. Try again or enter manually.',
  );
  String get aiNotConfigured => t(
    'AI belum diaktifkan di server (GEMINI_API_KEY belum diatur). Kamu tetap bisa input manual atau pakai contoh struk.',
    'AI is not enabled on the server (GEMINI_API_KEY missing). You can still enter the bill manually or use the sample.',
  );
  String get receiptNotFound =>
      t('Struk tidak ditemukan.', 'Receipt not found.');
  String get createExpenseFromReceipt =>
      t('Buat pengeluaran dari struk', 'Create expense from receipt');
  String get assignInExpense => t(
    'Lanjut ke pengeluaran untuk menandai pemilik item.',
    'Continue to the expense to assign items.',
  );
  String get openingCamera => t('Membuka kamera…', 'Opening camera…');
  String get scanTip => t(
    'Taruh struk di permukaan rata, pastikan cahaya cukup.',
    'Lay the receipt flat with enough light.',
  );
  String get noReceipts => t('Belum ada struk.', 'No receipts yet.');

  // ---------------------------------------------------------------------------
  // Activity
  // ---------------------------------------------------------------------------

  String get activity => t('Aktivitas', 'Activity');
  String get noActivity => t('Belum ada aktivitas', 'No activity yet');
  String get activitySubtitle => t(
    'Semua perubahan tercatat, biar transparan.',
    'Every change is logged, so nothing is a mystery.',
  );

  String activityVerb(ActivityKind kind) => switch (kind) {
    ActivityKind.groupCreated => t('membuat grup', 'created the group'),
    ActivityKind.groupUpdated => t('memperbarui grup', 'updated the group'),
    ActivityKind.memberJoined => t('bergabung', 'joined'),
    ActivityKind.memberRemoved => t('keluar dari grup', 'left the group'),
    ActivityKind.expenseAdded => t(
      'menambahkan pengeluaran',
      'added an expense',
    ),
    ActivityKind.expenseUpdated => t(
      'mengubah pengeluaran',
      'updated an expense',
    ),
    ActivityKind.expenseDeleted => t(
      'menghapus pengeluaran',
      'deleted an expense',
    ),
    ActivityKind.settlementAdded => t(
      'mencatat pelunasan',
      'recorded a settlement',
    ),
    ActivityKind.receiptScanned => t('memindai struk', 'scanned a receipt'),
    ActivityKind.nudgeSent => t('mengirim colek halus', 'sent a gentle nudge'),
  };

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  String get notificationsTitle => t('Notifikasi', 'Notifications');
  String get notificationsSubtitle => t(
    'Pengingat sopan dan kabar dari grup.',
    'Gentle reminders and group updates.',
  );
  String get markAllRead => t('Tandai semua dibaca', 'Mark all read');
  String get noNotifications =>
      t('Belum ada notifikasi', 'No notifications yet');
  String get noNotificationsBody => t(
    'Kabar pengeluaran, pelunasan, dan colek halus akan muncul di sini.',
    'Expenses, settlements, and gentle nudges will show up here.',
  );
  String get allCaughtUp => t('Semua sudah dibaca.', 'All caught up.');
  String get notificationDeleted =>
      t('Notifikasi dihapus.', 'Notification removed.');

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String get settingsSubtitle => t(
    'Sesuaikan tampilan, bahasa, dan data.',
    'Tune the look, language, and data.',
  );
  String get account => t('Akun', 'Account');
  String get profile => t('Profil', 'Profile');
  String get profileSaved => t('Profil disimpan.', 'Profile saved.');
  String get appearance => t('Tampilan', 'Appearance');
  String get theme => t('Tema', 'Theme');
  String get themeSystem => t('Ikuti sistem', 'System');
  String get themeLight => t('Terang', 'Light');
  String get themeDark => t('Gelap', 'Dark');
  String get language => t('Bahasa', 'Language');
  String get indonesian => 'Bahasa Indonesia';
  String get english => 'English';
  String get defaultCurrency => t('Mata uang default', 'Default currency');
  String get notificationsHint => t(
    'Pengingat lokal untuk pelunasan dan aktivitas grup.',
    'Local reminders for settlements and group activity.',
  );
  String get politeReminders => t('Pengingat sopan', 'Polite reminders');
  String get politeRemindersHint => t(
    'Nada pesan selalu ramah, tanpa menyudutkan.',
    'Always friendly, never shaming.',
  );
  String get syncSection => t('Sinkronisasi', 'Sync');
  String get pendingChanges => t('Perubahan di antrean', 'Queued changes');
  String get lastSync => t('Sinkron terakhir', 'Last sync');
  String get never => t('Belum pernah', 'Never');
  String get demoData => t('Data demo', 'Demo data');
  String get demoDataHint => t(
    'Data contoh tersimpan lokal di perangkat ini.',
    'Sample data is stored locally on this device.',
  );
  String get exportSection => t('Ekspor', 'Export');
  String get exportCsv => t('Ekspor CSV', 'Export CSV');
  String get exportPdf => t('Ekspor PDF', 'Export PDF');
  String get exportHint => t(
    'Ekspor ringkasan grup yang sedang dipilih dari Beranda.',
    'Exports the summary for the group selected on Home.',
  );
  String get exportNeedsGroup => t(
    'Buka salah satu grup dulu, lalu ekspor dari sana.',
    'Open a group first, then export from there.',
  );
  String get exportedCsv =>
      t('CSV siap. Cek folder unduhan.', 'CSV ready in downloads.');
  String get exportedPdf =>
      t('PDF siap. Cek folder unduhan.', 'PDF ready in downloads.');
  String get about => t('Tentang', 'About');
  String get aboutBody => t(
    'Bagi Fair membantu teman membagi tagihan dengan transparan. Angka disimpan sebagai satuan terkecil, jadi tidak ada rupiah yang hilang karena pembulatan.',
    'Bagi Fair helps friends split bills transparently. Amounts are stored in minor units, so no cent disappears in rounding.',
  );
  String get signOut => t('Keluar', 'Sign out');
  String get signOutConfirm => t('Keluar dari akun?', 'Sign out?');
  String get signOutBody => t(
    'Data lokal di perangkat ini akan dihapus. Data cloud tetap aman.',
    'Local data on this device will be cleared. Cloud data stays safe.',
  );
  String get version => t('Versi', 'Version');
  String get dataSecurity => t('Keamanan data', 'Data security');
  String get dataSecurityBody => t(
    'Row Level Security memastikan hanya anggota grup yang bisa membaca atau mengubah data grup.',
    'Row Level Security ensures only group members can read or change group data.',
  );

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------

  String get loadFailed => t('Gagal memuat data.', 'Could not load data.');
  String get saveFailed =>
      t('Gagal menyimpan. Coba lagi.', 'Could not save. Try again.');
  String get joinFailed =>
      t('Gagal bergabung. Coba lagi.', 'Could not join. Try again.');
  String get inviteFailed =>
      t('Gagal membuat link undangan.', 'Could not create invite.');
  String get settleFailed =>
      t('Gagal mencatat pelunasan.', 'Could not record settlement.');
  String get scanError =>
      t('Scan gagal. Coba lagi.', 'Scan failed. Try again.');
  String get permissionDenied => t(
    'Izin kamera/galeri ditolak. Kamu bisa input manual.',
    'Camera/gallery permission denied. You can enter manually.',
  );
  String get shareFailed =>
      t('Gagal membagikan. Coba lagi.', 'Could not share. Try again.');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'id' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
