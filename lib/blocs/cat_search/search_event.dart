part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

// โหลด autocomplete suggestions
class SearchAutocompleteRequested extends SearchEvent {
  final String query;
  const SearchAutocompleteRequested(this.query);

  @override
  List<Object?> get props => [query];
}

// เลือก suggestion
class SearchSuggestionSelected extends SearchEvent {
  final SearchCategory category;
  const SearchSuggestionSelected(this.category);

  @override
  List<Object?> get props => [category.id];
}

// เปลี่ยน gender filter
class SearchGenderFilterChanged extends SearchEvent {
  final int? gender;
  const SearchGenderFilterChanged(this.gender);

  @override
  List<Object?> get props => [gender];
}

// เปลี่ยนหน้า
class SearchPageChanged extends SearchEvent {
  final int page;
  const SearchPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

// เพิ่มลงตะกร้า
class SearchAddToBasketRequested extends SearchEvent {
  final ClothingItem item;
  const SearchAddToBasketRequested(this.item);

  @override
  List<Object?> get props => [item.uuid];
}

// เปิด item detail popup
class SearchItemDetailRequested extends SearchEvent {
  final ClothingItem item;
  const SearchItemDetailRequested(this.item);

  @override
  List<Object?> get props => [item.uuid];
}

// clear search
class SearchCleared extends SearchEvent {
  const SearchCleared();
}