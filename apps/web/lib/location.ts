export interface Coordinates {
  latitude: number;
  longitude: number;
}

export const SRI_LANKA_CITY_COORDINATES: Record<string, Coordinates> = {
  colombo: { latitude: 6.8918, longitude: 79.8732 },
  kandy: { latitude: 7.2906, longitude: 80.6337 },
  galle: { latitude: 6.0535, longitude: 80.2210 },
  negombo: { latitude: 7.2008, longitude: 79.8736 },
  kurunegala: { latitude: 7.4863, longitude: 80.3623 },
};

/**
 * Request user's current GPS coordinates using the Browser Geolocation API.
 */
export function getCurrentUserCoordinates(): Promise<Coordinates> {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("Geolocation is not supported by your browser."));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        resolve({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        });
      },
      (err) => {
        let msg = "Could not access location.";
        if (err.code === err.PERMISSION_DENIED) {
          msg = "Location permission denied. Please allow location access or choose a city.";
        } else if (err.code === err.POSITION_UNAVAILABLE) {
          msg = "Location information is unavailable.";
        } else if (err.code === err.TIMEOUT) {
          msg = "Location request timed out.";
        }
        reject(new Error(msg));
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 60000,
      }
    );
  });
}
