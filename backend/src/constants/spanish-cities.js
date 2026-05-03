export const SPANISH_CITIES = [
  "A Coruña",
  "Albacete",
  "Alcalá de Henares",
  "Alcobendas",
  "Alcorcón",
  "Algeciras",
  "Alicante",
  "Almería",
  "Ávila",
  "Badajoz",
  "Badalona",
  "Barcelona",
  "Bilbao",
  "Burgos",
  "Cáceres",
  "Cádiz",
  "Cartagena",
  "Castellón de la Plana",
  "Ceuta",
  "Ciudad Real",
  "Córdoba",
  "Cuenca",
  "Donostia-San Sebastián",
  "Elche",
  "Fuenlabrada",
  "Getafe",
  "Gijón",
  "Girona",
  "Granada",
  "Guadalajara",
  "Hospitalet de Llobregat",
  "Huelva",
  "Huesca",
  "Jaén",
  "Jerez de la Frontera",
  "Las Palmas de Gran Canaria",
  "Leganés",
  "León",
  "Lleida",
  "Logroño",
  "Lugo",
  "Madrid",
  "Majadahonda",
  "Málaga",
  "Marbella",
  "Melilla",
  "Mérida",
  "Móstoles",
  "Murcia",
  "Ourense",
  "Oviedo",
  "Palma",
  "Pamplona",
  "Pontevedra",
  "Sabadell",
  "Salamanca",
  "San Cristóbal de La Laguna",
  "San Sebastián de los Reyes",
  "Santa Cruz de Tenerife",
  "Santander",
  "Santiago de Compostela",
  "Segovia",
  "Sevilla",
  "Soria",
  "Tarragona",
  "Terrassa",
  "Teruel",
  "Toledo",
  "Torrejón de Ardoz",
  "Valencia",
  "Valladolid",
  "Vigo",
  "Vitoria-Gasteiz",
  "Zamora",
  "Zaragoza",
];

export const normalizeSpanishCity = (value) =>
  value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replaceAll(/[\u0300-\u036f]/g, "");

const CITY_LOOKUP = new Map(
  SPANISH_CITIES.map((city) => [normalizeSpanishCity(city), city]),
);

export const findSpanishCity = (value) => {
  if (typeof value !== "string") {
    return null;
  }

  const normalizedValue = normalizeSpanishCity(value);

  if (!normalizedValue) {
    return null;
  }

  return CITY_LOOKUP.get(normalizedValue) ?? null;
};
