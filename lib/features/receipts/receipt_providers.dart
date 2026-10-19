import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/models/receipt.dart';
import '../../data/repositories/receipt_repository.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(AppDatabase.instance),
);

final receiptsProvider =
    StateNotifierProvider<ReceiptsNotifier, AsyncValue<List<Receipt>>>(
      (ref) => ReceiptsNotifier(ref.read(receiptRepositoryProvider)),
    );

class ReceiptsNotifier extends StateNotifier<AsyncValue<List<Receipt>>> {
  ReceiptsNotifier(this._repository) : super(const AsyncLoading()) {
    refresh();
  }

  final ReceiptRepository _repository;

  Future<void> refresh() async {
    try {
      state = AsyncData(await _repository.getAll());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> save(Receipt receipt) async {
    try {
      await _repository.save(receipt);
    } finally {
      await refresh();
    }
  }

  Future<void> update(Receipt receipt) async {
    try {
      await _repository.update(receipt);
    } finally {
      await refresh();
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
    } finally {
      await refresh();
    }
  }
}
