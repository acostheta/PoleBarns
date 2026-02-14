import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pole_barn_model.dart';
import '../models/related_material_model.dart';
import '../repositories/pole_barn_repository.dart';

class PoleBarnFormState {
  final PoleBarn poleBarn;
  final List<RelatedMaterial> relatedMaterials;
  final bool isLoading;
  final bool isSaving; // Added for auto-save status
  final String? error;
  final bool isPriceManuallyEdited;
  final bool isNameManuallyEdited;

  PoleBarnFormState({
    required this.poleBarn,
    required this.relatedMaterials,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isPriceManuallyEdited = false,
    this.isNameManuallyEdited = false,
  });

  // Local calculations for immediate UI feedback before DB sync
  double get localTotal =>
      relatedMaterials.fold(0, (sum, item) => sum + item.calculatedTotal);

  double get localCost =>
      relatedMaterials.fold(0, (sum, item) => sum + item.calculatedCost);

  double get localTotalPrice => localTotal + poleBarn.labour;

  PoleBarnFormState copyWith({
    PoleBarn? poleBarn,
    List<RelatedMaterial>? relatedMaterials,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? isPriceManuallyEdited,
    bool? isNameManuallyEdited,
  }) {
    return PoleBarnFormState(
      poleBarn: poleBarn ?? this.poleBarn,
      relatedMaterials: relatedMaterials ?? this.relatedMaterials,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isPriceManuallyEdited:
          isPriceManuallyEdited ?? this.isPriceManuallyEdited,
      isNameManuallyEdited: isNameManuallyEdited ?? this.isNameManuallyEdited,
    );
  }
}

class PoleBarnFormNotifier extends StateNotifier<PoleBarnFormState> {
  final PoleBarnRepository _repository;
  Timer? _debounce;

  PoleBarnFormNotifier(this._repository, PoleBarn? initialPoleBarn)
      : super(PoleBarnFormState(
          poleBarn: initialPoleBarn ??
              PoleBarn(
                  largo: 0,
                  ancho: 0,
                  alto: 0,
                  spacing: 0,
                  sheet: 0,
                  budgetLimit: 0),
          relatedMaterials: [],
          isPriceManuallyEdited:
              initialPoleBarn != null && initialPoleBarn.precioVenta > 0,
          isNameManuallyEdited: initialPoleBarn != null &&
              initialPoleBarn.name != null &&
              initialPoleBarn.name!.isNotEmpty,
        )) {
    if (initialPoleBarn?.id != null) {
      loadMaterials();
    } else {
      // If new, create in DB immediately to enable real-time association of materials
      _initNewPoleBarn();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initNewPoleBarn() async {
    state = state.copyWith(isSaving: true);
    try {
      final id = await _repository.upsertPoleBarn(state.poleBarn);
      state = state.copyWith(
        poleBarn: state.poleBarn.copyWith(id: id),
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSaving: false);
    }
  }

  Future<void> loadMaterials() async {
    if (state.poleBarn.id == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final materials =
          await _repository.getRelatedMaterials(state.poleBarn.id!);
      state = state.copyWith(relatedMaterials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void updatePoleBarnField(PoleBarn updated) {
    bool priceManual = state.isPriceManuallyEdited;
    if (updated.precioVenta != state.poleBarn.precioVenta) {
      priceManual = true;
    }

    bool nameManual = state.isNameManuallyEdited;
    if (updated.name != state.poleBarn.name) {
      nameManual = true;
    }

    state = state.copyWith(
      poleBarn: updated,
      isPriceManuallyEdited: priceManual,
      isNameManuallyEdited: nameManual,
    );
    _updateGeneratedName();
    _debouncedSave();
  }

  void _updateGeneratedName() {
    if (state.isNameManuallyEdited) return;

    final pb = state.poleBarn;
    // Formula: POLE BARN ${ancho}x${largo}x${alto} @ ${Spacing}
    // We use int format if they are whole numbers for a cleaner look
    String fmt(double d) =>
        d == d.toInt() ? d.toInt().toString() : d.toString();

    final newName =
        "POLE BARN ${fmt(pb.ancho)}x${fmt(pb.largo)}x${fmt(pb.alto)} @ ${fmt(pb.spacing)}";

    if (pb.name != newName) {
      state = state.copyWith(
        poleBarn: pb.copyWith(name: newName),
      );
    }
  }

  void addMaterial(RelatedMaterial material) {
    state = state.copyWith(
      relatedMaterials: [...state.relatedMaterials, material],
    );
    _autoUpdatePrice();
    _debouncedSave();
  }

  void updateMaterial(int index, RelatedMaterial material) {
    final newList = [...state.relatedMaterials];
    newList[index] = material;
    state = state.copyWith(relatedMaterials: newList);
    _autoUpdatePrice();
    _debouncedSave();
  }

  void removeMaterial(int index) {
    final newList = [...state.relatedMaterials];
    newList.removeAt(index);
    state = state.copyWith(relatedMaterials: newList);
    _autoUpdatePrice();
    _debouncedSave();
  }

  void _autoUpdatePrice() {
    // Note: Now we also update the cost and price
    if (!state.isPriceManuallyEdited) {
      state = state.copyWith(
        poleBarn: state.poleBarn.copyWith(
          precioVenta: state.localTotalPrice,
          cost: state.localCost,
        ),
      );
    } else {
      state = state.copyWith(
        poleBarn: state.poleBarn.copyWith(cost: state.localCost),
      );
    }
  }

  void _debouncedSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), save);
  }

  Future<void> save() async {
    if (state.poleBarn.id == null) return;

    state = state.copyWith(isSaving: true);
    try {
      final id = await _repository.upsertPoleBarn(state.poleBarn);
      await _repository.saveRelatedMaterials(id, state.relatedMaterials);

      // We don't necessarily need to reload everything on every auto-save to avoid UI flicker
      // but we should ensure IDs are synced for new materials
      if (state.relatedMaterials.any((m) => m.id == null)) {
        final updatedMaterials = await _repository.getRelatedMaterials(id);
        state = state.copyWith(relatedMaterials: updatedMaterials);
      }

      state = state.copyWith(isSaving: false, error: null);
    } catch (e) {
      state = state.copyWith(error: "Error al guardar: $e", isSaving: false);
    }
  }
}

// Providers
final selectedPoleBarnIdProvider = StateProvider<int?>((ref) => null);

final poleBarnRepositoryProvider = Provider<PoleBarnRepository>((ref) {
  return PoleBarnRepository(Supabase.instance.client);
});

final rawMaterialsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(poleBarnRepositoryProvider).getRawMaterials();
});

final poleBarnFormProvider = StateNotifierProvider.family<PoleBarnFormNotifier,
    PoleBarnFormState, PoleBarn?>((ref, initial) {
  final repo = ref.watch(poleBarnRepositoryProvider);
  return PoleBarnFormNotifier(repo, initial);
});

// Stream for parent (Trigger updates)
final poleBarnStreamProvider = StreamProvider.family<PoleBarn?, int>((ref, id) {
  final repo = ref.watch(poleBarnRepositoryProvider);
  return repo.watchPoleBarn(id);
});

// Stream for materials (Realtime HU-02)
final relatedMaterialsStreamProvider =
    StreamProvider.family<List<RelatedMaterial>, int>((ref, poleBarnId) {
  return Supabase.instance.client
      .from('RelatedMaterials')
      .stream(primaryKey: const ['id'])
      .eq('PoleBarns_Ref', poleBarnId)
      .map((data) {
        // Usamos Map.from para asegurar compatibilidad en Web con JSArray/JSObject
        return data
            .map((json) =>
                RelatedMaterial.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      });
});

final poleBarnsListStreamProvider = StreamProvider<List<PoleBarn>>((ref) {
  final repo = ref.watch(poleBarnRepositoryProvider);
  return repo.watchPoleBarns();
});
