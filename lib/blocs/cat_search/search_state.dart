part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

// ── Initial ──────────────────────────────────────────────────────────────────
class SearchInitial extends SearchState {
  final List<SearchCategory> suggestions;

  const SearchInitial({this.suggestions = const []});

  @override
  List<Object?> get props => [suggestions];
}

// ── Loaded (มี results หรือ outfits) ─────────────────────────────────────────
class SearchLoaded extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final List<ClothingItem> outfits;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;
  final bool hasSelected;

  const SearchLoaded({
    required this.suggestions,
    required this.results,
    required this.outfits,
    required this.currentPage,
    required this.totalPages,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
    required this.hasSelected,
  });

  SearchLoaded copyWith({
    List<SearchCategory>? suggestions,
    List<ClothingItem>? results,
    List<ClothingItem>? outfits,
    int? currentPage,
    int? totalPages,
    int? selectedCategoryId,
    bool clearCategoryId = false,
    int? selectedGender,
    bool clearGender = false,
    bool? showGenderFilters,
    bool? hasSelected,
  }) {
    return SearchLoaded(
      suggestions: suggestions ?? this.suggestions,
      results: results ?? this.results,
      outfits: outfits ?? this.outfits,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedCategoryId:
          clearCategoryId ? null : selectedCategoryId ?? this.selectedCategoryId,
      selectedGender: clearGender ? null : selectedGender ?? this.selectedGender,
      showGenderFilters: showGenderFilters ?? this.showGenderFilters,
      hasSelected: hasSelected ?? this.hasSelected,
    );
  }

  @override
  List<Object?> get props => [
        suggestions,
        results,
        outfits,
        currentPage,
        totalPages,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
        hasSelected,
      ];
}

// ── Results Loading ───────────────────────────────────────────────────────────
class SearchResultsLoading extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> outfits;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;

  const SearchResultsLoading({
    required this.suggestions,
    required this.outfits,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
  });

  @override
  List<Object?> get props => [
        suggestions,
        outfits,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
      ];
}

// ── Outfits Loading ───────────────────────────────────────────────────────────
class SearchOutfitsLoading extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;

  const SearchOutfitsLoading({
    required this.suggestions,
    required this.results,
    required this.currentPage,
    required this.totalPages,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
  });

  @override
  List<Object?> get props => [
        suggestions,
        results,
        currentPage,
        totalPages,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
      ];
}

// ── Basket In Progress ────────────────────────────────────────────────────────
class SearchBasketInProgress extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final List<ClothingItem> outfits;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;
  final bool hasSelected;
  final String basketUuid; // uuid ที่กำลัง add

  const SearchBasketInProgress({
    required this.suggestions,
    required this.results,
    required this.outfits,
    required this.currentPage,
    required this.totalPages,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
    required this.hasSelected,
    required this.basketUuid,
  });

  @override
  List<Object?> get props => [
        suggestions,
        results,
        outfits,
        currentPage,
        totalPages,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
        hasSelected,
        basketUuid,
      ];
}

// ── Basket Success ────────────────────────────────────────────────────────────
class SearchBasketSuccess extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final List<ClothingItem> outfits;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;
  final bool hasSelected;

  const SearchBasketSuccess({
    required this.suggestions,
    required this.results,
    required this.outfits,
    required this.currentPage,
    required this.totalPages,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
    required this.hasSelected,
  });

  @override
  List<Object?> get props => [
        suggestions,
        results,
        outfits,
        currentPage,
        totalPages,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
        hasSelected,
      ];
}

// ── Basket Failure ────────────────────────────────────────────────────────────
class SearchBasketFailure extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final List<ClothingItem> outfits;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;
  final bool hasSelected;
  final String errorMessage;

  const SearchBasketFailure({
    required this.suggestions,
    required this.results,
    required this.outfits,
    required this.currentPage,
    required this.totalPages,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
    required this.hasSelected,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [
        suggestions,
        results,
        outfits,
        currentPage,
        totalPages,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
        hasSelected,
        errorMessage,
      ];
}

// ── Item Detail Requested (trigger popup ใน listener) ────────────────────────
class SearchItemDetailReady extends SearchState {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final List<ClothingItem> outfits;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;
  final bool hasSelected;
  final ClothingItem selectedItem;

  const SearchItemDetailReady({
    required this.suggestions,
    required this.results,
    required this.outfits,
    required this.currentPage,
    required this.totalPages,
    this.selectedCategoryId,
    this.selectedGender,
    required this.showGenderFilters,
    required this.hasSelected,
    required this.selectedItem,
  });

  @override
  List<Object?> get props => [
        suggestions,
        results,
        outfits,
        currentPage,
        totalPages,
        selectedCategoryId,
        selectedGender,
        showGenderFilters,
        hasSelected,
        selectedItem,
      ];
}