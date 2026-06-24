/// Listing visibility state for showroom dashboard rows.
enum ShowroomListingStatus {
  active,
  pending,
  sold;

  String get labelKu => switch (this) {
        ShowroomListingStatus.active => 'چالاک',
        ShowroomListingStatus.pending => 'لە پێداچوونەوەدایە',
        ShowroomListingStatus.sold => 'فرۆشرا',
      };
}
