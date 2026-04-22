class AppLocalizations {
  static String text({
    required bool isUrdu,
    required String english,
    required String urdu,
  }) {
    return isUrdu ? urdu : english;
  }
}
