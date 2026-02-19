import 'package:equatable/equatable.dart';
import '../data/models/financial_models.dart';

// ══════════════════════════════════════════
// Events
// ══════════════════════════════════════════

abstract class FinancialEvent extends Equatable {
  const FinancialEvent();
  @override
  List<Object?> get props => [];
}

/// Load financial entries list
class FinancialEntriesLoadRequested extends FinancialEvent {
  final int page;
  final String? search;
  final String? type;
  final String? status;
  final String? dateFrom;
  final String? dateTo;

  const FinancialEntriesLoadRequested({
    this.page = 1,
    this.search,
    this.type,
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [page, search, type, status, dateFrom, dateTo];
}

/// Load balance report
class FinancialBalanceLoadRequested extends FinancialEvent {
  final String? dateFrom;
  final String? dateTo;

  const FinancialBalanceLoadRequested({this.dateFrom, this.dateTo});

  @override
  List<Object?> get props => [dateFrom, dateTo];
}

/// Create a financial entry
class FinancialEntryCreateRequested extends FinancialEvent {
  final Map<String, dynamic> data;
  const FinancialEntryCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Update a financial entry
class FinancialEntryUpdateRequested extends FinancialEvent {
  final String entryId;
  final Map<String, dynamic> data;
  const FinancialEntryUpdateRequested({required this.entryId, required this.data});
  @override
  List<Object?> get props => [entryId, data];
}

/// Delete (cancel) a financial entry
class FinancialEntryDeleteRequested extends FinancialEvent {
  final String entryId;
  const FinancialEntryDeleteRequested({required this.entryId});
  @override
  List<Object?> get props => [entryId];
}

/// Load account plans
class AccountPlansLoadRequested extends FinancialEvent {
  final String? type;
  const AccountPlansLoadRequested({this.type});
  @override
  List<Object?> get props => [type];
}

/// Create account plan
class AccountPlanCreateRequested extends FinancialEvent {
  final Map<String, dynamic> data;
  const AccountPlanCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Load bank accounts
class BankAccountsLoadRequested extends FinancialEvent {
  const BankAccountsLoadRequested();
}

/// Create bank account
class BankAccountCreateRequested extends FinancialEvent {
  final Map<String, dynamic> data;
  const BankAccountCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Load campaigns
class CampaignsLoadRequested extends FinancialEvent {
  final String? search;
  const CampaignsLoadRequested({this.search});
  @override
  List<Object?> get props => [search];
}

/// Create campaign
class CampaignCreateRequested extends FinancialEvent {
  final Map<String, dynamic> data;
  const CampaignCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Load monthly closings
class MonthlyClosingsLoadRequested extends FinancialEvent {
  final int page;
  const MonthlyClosingsLoadRequested({this.page = 1});
  @override
  List<Object?> get props => [page];
}

/// Create monthly closing
class MonthlyClosingCreateRequested extends FinancialEvent {
  final Map<String, dynamic> data;
  const MonthlyClosingCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

// ══════════════════════════════════════════
// States
// ══════════════════════════════════════════

abstract class FinancialState extends Equatable {
  const FinancialState();
  @override
  List<Object?> get props => [];
}

class FinancialInitial extends FinancialState {
  const FinancialInitial();
}

class FinancialLoading extends FinancialState {
  const FinancialLoading();
}

/// Entries list loaded
class FinancialEntriesLoaded extends FinancialState {
  final List<FinancialEntry> entries;
  final int totalCount;
  final int currentPage;
  final String? activeSearch;
  final String? activeType;
  final String? activeStatus;

  const FinancialEntriesLoaded({
    required this.entries,
    required this.totalCount,
    this.currentPage = 1,
    this.activeSearch,
    this.activeType,
    this.activeStatus,
  });

  @override
  List<Object?> get props => [entries, totalCount, currentPage, activeSearch, activeType, activeStatus];
}

/// Balance report loaded
class FinancialBalanceLoaded extends FinancialState {
  final FinancialBalance balance;

  const FinancialBalanceLoaded({required this.balance});

  @override
  List<Object?> get props => [balance];
}

/// Account plans loaded
class AccountPlansLoaded extends FinancialState {
  final List<AccountPlan> plans;
  final int totalCount;

  const AccountPlansLoaded({required this.plans, required this.totalCount});

  @override
  List<Object?> get props => [plans, totalCount];
}

/// Bank accounts loaded
class BankAccountsLoaded extends FinancialState {
  final List<BankAccount> accounts;
  final int totalCount;

  const BankAccountsLoaded({required this.accounts, required this.totalCount});

  @override
  List<Object?> get props => [accounts, totalCount];
}

/// Campaigns loaded
class CampaignsLoaded extends FinancialState {
  final List<Campaign> campaigns;
  final int totalCount;

  const CampaignsLoaded({required this.campaigns, required this.totalCount});

  @override
  List<Object?> get props => [campaigns, totalCount];
}

/// Monthly closings loaded
class MonthlyClosingsLoaded extends FinancialState {
  final List<MonthlyClosing> closings;
  final int totalCount;

  const MonthlyClosingsLoaded({required this.closings, required this.totalCount});

  @override
  List<Object?> get props => [closings, totalCount];
}

/// A resource was saved successfully
class FinancialSaved extends FinancialState {
  final String message;

  const FinancialSaved({required this.message});

  @override
  List<Object?> get props => [message];
}

class FinancialError extends FinancialState {
  final String message;

  const FinancialError({required this.message});

  @override
  List<Object?> get props => [message];
}
