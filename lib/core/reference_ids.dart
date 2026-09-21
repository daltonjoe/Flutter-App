class RefIds {
  static int signId(int signIndex) => signIndex + 1;
  static int houseId(int houseNumber) => houseNumber;

  static const planets = {
    'Sun': 1,
    'Moon': 2,
    'Mercury': 3,
    'Venus': 4,
    'Mars': 5,
    'Jupiter': 6,
    'Saturn': 7,
    'Uranus': 8,
    'Neptune': 9,
    'Pluto': 10,
  };

  static const aspectByAngle = {0: 1, 60: 2, 90: 3, 120: 4, 180: 5};
  static int? aspectId(num angle) => aspectByAngle[angle.round()];
}
