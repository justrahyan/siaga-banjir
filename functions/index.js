const functions = require("firebase-functions/v2/https");
const axios = require("axios");

const API_KEY = "bb2dd84ca2541574dac0faffefcb4e45";

// 🔹 Ambil cuaca real-time dari OpenWeatherMap
async function getOpenWeather(lat, lon) {
  const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${API_KEY}&units=metric&lang=id`;
  const res = await axios.get(url);
  const d = res.data;
  return [
    {
      local_datetime: new Date().toISOString(),
      t: d.main.temp,
      hu: d.main.humidity,
      weather_desc: d.weather[0].description,
    },
  ];
}

// 🔹 Prediksi 7 hari ke depan (AI sederhana)
function predictNextDays(data) {
  const preds = [];
  const base = data[0];
  for (let i = 1; i <= 7; i++) {
    const day = new Date();
    day.setDate(day.getDate() + i);

    const t = base.t + Math.random() * 2 - 1; // variasi kecil
    const hu = Math.min(100, Math.max(40, base.hu + Math.random() * 10 - 5));
    const kondisi =
      hu > 85 ? "Hujan" : hu > 70 ? "Berawan" : "Cerah";

    preds.push({
      local_datetime: day.toISOString().split("T")[0] + " 00:00:00",
      t: Number(t.toFixed(1)),
      hu: Math.round(hu),
      weather_desc: kondisi,
    });
  }
  return data.concat(preds);
}

// 🌍 Endpoint utama: prediksi berdasarkan lokasi pengguna
exports.prediksiCuaca = functions.onRequest(async (req, res) => {
  try {
    const { lat, lon } = req.query;
    if (!lat || !lon) {
      return res.status(400).json({ error: "lat dan lon wajib dikirim" });
    }

    const owm = await getOpenWeather(lat, lon);
    const hasil = predictNextDays(owm);
    res.json({ status: "success", data: hasil });
  } catch (err) {
    console.error("❌ Error prediksi:", err);
    res.status(500).json({ status: "error", message: err.toString() });
  }
});