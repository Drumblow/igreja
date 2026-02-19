import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/financial_repository.dart';
import 'financial_event_state.dart';

class FinancialBloc extends Bloc<FinancialEvent, FinancialState> {
  final FinancialRepository _repository;

  FinancialBloc({required FinancialRepository repository})
      : _repository = repository,
        super(const FinancialInitial()) {
    on<FinancialEntriesLoadRequested>(_onEntriesLoadRequested);
    on<FinancialBalanceLoadRequested>(_onBalanceLoadRequested);
    on<FinancialEntryCreateRequested>(_onEntryCreateRequested);
    on<FinancialEntryUpdateRequested>(_onEntryUpdateRequested);
    on<FinancialEntryDeleteRequested>(_onEntryDeleteRequested);
    on<AccountPlansLoadRequested>(_onAccountPlansLoadRequested);
    on<AccountPlanCreateRequested>(_onAccountPlanCreateRequested);
    on<BankAccountsLoadRequested>(_onBankAccountsLoadRequested);
    on<BankAccountCreateRequested>(_onBankAccountCreateRequested);
    on<CampaignsLoadRequested>(_onCampaignsLoadRequested);
    on<CampaignCreateRequested>(_onCampaignCreateRequested);
    on<MonthlyClosingsLoadRequested>(_onMonthlyClosingsLoadRequested);
    on<MonthlyClosingCreateRequested>(_onMonthlyClosingCreateRequested);
  }

  Future<void> _onEntriesLoadRequested(
    FinancialEntriesLoadRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      final result = await _repository.getEntries(
        page: event.page,
        search: event.search,
        type: event.type,
        status: event.status,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );
      emit(FinancialEntriesLoaded(
        entries: result.items,
        totalCount: result.total,
        currentPage: event.page,
        activeSearch: event.search,
        activeType: event.type,
        activeStatus: event.status,
      ));
    } catch (e) {
      emit(FinancialError(message: e.toString()));
    }
  }

  Future<void> _onBalanceLoadRequested(
    FinancialBalanceLoadRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      final balance = await _repository.getBalanceReport(
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );
      emit(FinancialBalanceLoaded(balance: balance));
    } catch (e) {
      emit(FinancialError(message: e.toString()));
    }
  }

  Future<void> _onEntryCreateRequested(
    FinancialEntryCreateRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      await _repository.createEntry(event.data);
      emit(const FinancialSaved(message: 'Lançamento criado com sucesso'));
    } catch (e) {
      emit(FinancialError(message: 'Erro ao criar lançamento: $e'));
    }
  }

  Future<void> _onEntryUpdateRequested(
    FinancialEntryUpdateRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      await _repository.updateEntry(event.entryId, event.data);
      emit(const FinancialSaved(message: 'Lançamento atualizado com sucesso'));
    } catch (e) {
      emit(FinancialError(message: 'Erro ao atualizar lançamento: $e'));
    }
  }

  Future<void> _onEntryDeleteRequested(
    FinancialEntryDeleteRequested event,
    Emitter<FinancialState> emit,
  ) async {
    try {
      await _repository.deleteEntry(event.entryId);
      // Reload entries
      if (state is FinancialEntriesLoaded) {
        final current = state as FinancialEntriesLoaded;
        add(FinancialEntriesLoadRequested(
          page: current.currentPage,
          search: current.activeSearch,
          type: current.activeType,
          status: current.activeStatus,
        ));
      }
    } catch (e) {
      emit(FinancialError(message: 'Erro ao cancelar lançamento: $e'));
    }
  }

  Future<void> _onAccountPlansLoadRequested(
    AccountPlansLoadRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      final result = await _repository.getAccountPlans(type: event.type);
      emit(AccountPlansLoaded(plans: result.items, totalCount: result.total));
    } catch (e) {
      emit(FinancialError(message: e.toString()));
    }
  }

  Future<void> _onAccountPlanCreateRequested(
    AccountPlanCreateRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      await _repository.createAccountPlan(event.data);
      emit(const FinancialSaved(message: 'Plano de contas criado com sucesso'));
    } catch (e) {
      emit(FinancialError(message: 'Erro ao criar plano de contas: $e'));
    }
  }

  Future<void> _onBankAccountsLoadRequested(
    BankAccountsLoadRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      final result = await _repository.getBankAccounts();
      emit(BankAccountsLoaded(accounts: result.items, totalCount: result.total));
    } catch (e) {
      emit(FinancialError(message: e.toString()));
    }
  }

  Future<void> _onBankAccountCreateRequested(
    BankAccountCreateRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      await _repository.createBankAccount(event.data);
      emit(const FinancialSaved(message: 'Conta bancária criada com sucesso'));
    } catch (e) {
      emit(FinancialError(message: 'Erro ao criar conta bancária: $e'));
    }
  }

  Future<void> _onCampaignsLoadRequested(
    CampaignsLoadRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      final result = await _repository.getCampaigns(search: event.search);
      emit(CampaignsLoaded(campaigns: result.items, totalCount: result.total));
    } catch (e) {
      emit(FinancialError(message: e.toString()));
    }
  }

  Future<void> _onCampaignCreateRequested(
    CampaignCreateRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      await _repository.createCampaign(event.data);
      emit(const FinancialSaved(message: 'Campanha criada com sucesso'));
    } catch (e) {
      emit(FinancialError(message: 'Erro ao criar campanha: $e'));
    }
  }

  Future<void> _onMonthlyClosingsLoadRequested(
    MonthlyClosingsLoadRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      final result = await _repository.getMonthlyClosings(page: event.page);
      emit(MonthlyClosingsLoaded(closings: result.items, totalCount: result.total));
    } catch (e) {
      emit(FinancialError(message: e.toString()));
    }
  }

  Future<void> _onMonthlyClosingCreateRequested(
    MonthlyClosingCreateRequested event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());
    try {
      await _repository.createMonthlyClosing(event.data);
      emit(const FinancialSaved(message: 'Fechamento mensal realizado com sucesso'));
    } catch (e) {
      emit(FinancialError(message: 'Erro ao realizar fechamento: $e'));
    }
  }
}
