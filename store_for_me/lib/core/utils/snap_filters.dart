class SnapFilters {
  static const List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> aestheticWhite = [
    1.0, 0.0, 0.0, 0.0, 20,
    0.0, 1.0, 0.0, 0.0, 20,
    0.0, 0.0, 1.0, 0.0, 25,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> moodyTeal = [
    0.7, 0.0, 0.0, 0.0, 0,
    0.0, 1.1, 0.0, 0.0, 10,
    0.0, 0.0, 1.3, 0.0, 20,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> goldenHour = [
    1.2, 0.1, 0.0, 0.0, 15,
    0.1, 1.0, 0.0, 0.0, 10,
    0.0, 0.0, 0.8, 0.0, -10,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> cyberpunk = [
    1.2, 0.0, 0.4, 0.0, 20,
    0.0, 0.8, 0.2, 0.0, -10,
    0.3, 0.0, 1.4, 0.0, 30,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> neoGlow = [
    1.1, 0.0, 0.0, 0.0, 30,
    0.0, 1.3, 0.0, 0.0, 30,
    0.0, 0.0, 1.2, 0.0, 30,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> dramaticBW = [
    1.5 * 0.2126, 1.5 * 0.7152, 1.5 * 0.0722, 0, -50,
    1.5 * 0.2126, 1.5 * 0.7152, 1.5 * 0.0722, 0, -50,
    1.5 * 0.2126, 1.5 * 0.7152, 1.5 * 0.0722, 0, -50,
    0, 0, 0, 1, 0,
  ];

  static const List<double> softRose = [
    1.2, 0.1, 0.1, 0.0, 20,
    0.1, 1.0, 0.1, 0.0, 10,
    0.1, 0.1, 1.1, 0.0, 15,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> oceanDeep = [
    0.6, 0.0, 0.0, 0.0, -10,
    0.0, 0.8, 0.0, 0.0, 0,
    0.0, 0.0, 1.5, 0.0, 40,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static const List<double> vintage80s = [
    0.9, 0.1, 0.1, 0, 10,
    0.1, 0.8, 0.1, 0, 10,
    0.1, 0.1, 0.7, 0, 10,
    0, 0, 0, 1, 0,
  ];

  static final Map<String, List<double>> allFilters = {
    'Original': identity,
    'Aesthetic': aestheticWhite,
    'Moody': moodyTeal,
    'Golden': goldenHour,
    'Cyber': cyberpunk,
    'Glow': neoGlow,
    'Noir': dramaticBW,
    'Rose': softRose,
    'Ocean': oceanDeep,
    '80s': vintage80s,
  };
}
