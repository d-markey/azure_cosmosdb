import 'package:azure_cosmosdb/azure_cosmosdb.dart';

const cities = {
  'Berlin': Point.geography(52.520007, 13.404954),
  'Canberra': Point.geography(-35.28467, 149.13522),
  'London': Point.geography(51.5073509, -0.1277583),
  'New-York': Point.geography(40.712784, -74.005941),
  'Paris': Point.geography(48.856613, 2.342889),
  'Ushuaia': Point.geography(-54.8019121, -68.3029511),
};

const cityDistances = <String, double>{
  // Berlin
  'Berlin->Berlin': 0,
  'Berlin->Canberra': 16056,
  'Berlin->London': 932,
  'Berlin->New-York': 6385,
  'Berlin->Paris': 878,
  'Berlin->Ushuaia': 14092,
  // Canberra
  'Canberra->Canberra': 0,
  'Canberra->London': 16971,
  'Canberra->New-York': 16215,
  'Canberra->Paris': 16909,
  'Canberra->Ushuaia': 9379,
  // London
  'London->London': 0,
  'London->New-York': 5571,
  'London->Paris': 343,
  'London->Ushuaia': 13381,
  // New-York
  'New-York->New-York': 0,
  'New-York->Paris': 5836,
  'New-York->Ushuaia': 10631,
  // Paris
  'Paris->Paris': 0,
  'Paris->Ushuaia': 13260,
  // Ushuaia
  'Ushuaia->Ushuaia': 0,
};

const monuments = {
  'Eiffel Tower': Point.geography(48.858370, 2.294481),
  'Notre Dame de Paris': Point.geography(48.852968, 2.349902),
  'London Tower Bridge': Point.geography(51.50562, -0.07537),
  'Big Ben': Point.geography(51.50108, -0.12462),
  'Statue of Liberty': Point.geography(40.689247, -74.044502),
  'Empire State Building': Point.geography(40.748817, -73.985428),
};

final parisArea = Polygon()
  ..add(LineString()
    ..addAll([
      Point.geography(48.84956, 2.22737),
      Point.geography(48.85001, 2.25071),
      Point.geography(48.83555, 2.25758),
      Point.geography(48.81611, 2.33723),
      Point.geography(48.81611, 2.35989),
      Point.geography(48.82877, 2.40040),
      Point.geography(48.82199, 2.43954),
      Point.geography(48.82741, 2.45945),
      Point.geography(48.83826, 2.46838),
      Point.geography(48.84639, 2.44366),
      Point.geography(48.84414, 2.41551),
      Point.geography(48.87621, 2.41276),
      Point.geography(48.88298, 2.39560),
      Point.geography(48.89833, 2.39216),
      Point.geography(48.90059, 2.32281),
      Point.geography(48.88118, 2.28093),
      Point.geography(48.88027, 2.25552),
      Point.geography(48.87305, 2.25209),
      Point.geography(48.87440, 2.24453),
      Point.geography(48.86763, 2.23149),
    ]));

final boisDeBoulogneArea = Polygon()
  ..add(LineString()
    ..addAll([
      Point.geography(48.84956, 2.22737),
      Point.geography(48.85001, 2.25071),
      Point.geography(48.88118, 2.28093),
      Point.geography(48.88027, 2.25552),
      Point.geography(48.87305, 2.25209),
      Point.geography(48.87440, 2.24453),
      Point.geography(48.86763, 2.23149),
    ]));

final boisDeVincennesArea = Polygon()
  ..add(LineString()
    ..addAll([
      Point.geography(48.82877, 2.40040),
      Point.geography(48.82199, 2.43954),
      Point.geography(48.82741, 2.45945),
      Point.geography(48.83826, 2.46838),
      Point.geography(48.84639, 2.44366),
      Point.geography(48.84414, 2.41551),
    ]));
