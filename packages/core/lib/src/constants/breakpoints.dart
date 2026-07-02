class Breakpoints {
  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;
}

enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}

DeviceScreenType getDeviceScreenType(double width) {
  if (width < Breakpoints.mobile) {
    return DeviceScreenType.mobile;
  }
  if (width < Breakpoints.tablet) {
    return DeviceScreenType.tablet;
  }
  return DeviceScreenType.desktop;
}
