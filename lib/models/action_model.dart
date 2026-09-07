typedef ActionCallback = Future<void> Function();

/// Describes one smart action presented for the current input.
class SmartAction {
  const SmartAction({
    required this.title,
    required this.iconName,
    required this.actionUrl,
    this.onTapCallback,
  });

  final String title;
  final String iconName;
  final String actionUrl;
  final void Function()? onTapCallback;
}
