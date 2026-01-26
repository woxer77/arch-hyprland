const https = require('https');

const WEATHER_CODES = {
  0: { icon: '☀️', desc: 'Clear sky' },
  1: { icon: '🌤️', desc: 'Mainly clear' },
  2: { icon: '⛅', desc: 'Partly cloudy' },
  3: { icon: '☁️', desc: 'Overcast' },
  45: { icon: '🌫️', desc: 'Fog' },
  48: { icon: '🌫️', desc: 'Depositing rime fog' },
  51: { icon: '🌧️', desc: 'Light drizzle' },
  53: { icon: '🌧️', desc: 'Moderate drizzle' },
  55: { icon: '🌧️', desc: 'Dense drizzle' },
  56: { icon: '❄️', desc: 'Light freezing drizzle' },
  57: { icon: '❄️', desc: 'Dense freezing drizzle' },
  61: { icon: '🌧️', desc: 'Slight rain' },
  63: { icon: '🌧️', desc: 'Moderate rain' },
  65: { icon: '🌧️', desc: 'Heavy rain' },
  66: { icon: '❄️', desc: 'Light freezing rain' },
  67: { icon: '❄️', desc: 'Heavy freezing rain' },
  71: { icon: '❄️', desc: 'Slight snow fall' },
  73: { icon: '❄️', desc: 'Moderate snow fall' },
  75: { icon: '❄️', desc: 'Heavy snow fall' },
  77: { icon: '❄️', desc: 'Snow grains' },
  80: { icon: '🌧️', desc: 'Slight rain showers' },
  81: { icon: '🌧️', desc: 'Moderate rain showers' },
  82: { icon: '🌧️', desc: 'Violent rain showers' },
  85: { icon: '❄️', desc: 'Slight snow showers' },
  86: { icon: '❄️', desc: 'Heavy snow showers' },
  95: { icon: '⛈️', desc: 'Thunderstorm' },
  96: { icon: '⛈️', desc: 'Thunderstorm with slight hail' },
  99: { icon: '⛈️', desc: 'Thunderstorm with heavy hail' },
};

// Polyfill for fetch if needed, or just use https to be safe across node versions
function fetchJSON(url, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timed out'));
    });
    req.setTimeout(timeout);
  });
}

(async function () {
  try {
    // 1. Get Location (using a free IP-based geo API)
    // We use get.geojs.io
    const geoData = await fetchJSON('https://get.geojs.io/v1/ip/geo.json');
    const { latitude, longitude, city, country } = geoData;

    // 2. Get Weather from Open-Meteo
    // Fetch 3 days of data to match the original script's scope
    const weatherUrl = `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m&current_weather=true&timezone=auto&days=3`;
    
    const weatherData = await fetchJSON(weatherUrl);

    if (!weatherData.hourly || !weatherData.current_weather) {
      throw new Error('Invalid API response structure');
    }

    const { 
      hourly,
      current_weather
    } = weatherData;
    
    const {
        time,
        temperature_2m,
        relative_humidity_2m,
        weather_code,
        wind_speed_10m,
        precipitation_probability
    } = hourly;

    const now = new Date();
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    
    const formatTime = (isoDateStr) => {
      const date = new Date(isoDateStr);
      return date.getHours().toString().padStart(2, '0') + ':00';
    };

    const getHumanizedDate = (isoDateStr) => {
      const dateObj = new Date(isoDateStr);
      const dateMidnight = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()).getTime();
      const daysDiff = Math.round((dateMidnight - todayMidnight) / (1000 * 60 * 60 * 24));
      
      const dayStr = dateObj.getDate().toString().padStart(2, '0');
      const monthStr = (dateObj.getMonth() + 1).toString().padStart(2, '0');
      const yearStr = dateObj.getFullYear();
      const fullDate = `${dayStr}/${monthStr}/${yearStr}`;

      if (daysDiff === 0) {
        return `<b>Today, ${fullDate}, ${city} (${country})</b>`;
      } else if (daysDiff === 1) {
        return `<b>Tomorrow, ${fullDate}</b>`;
      } else {
        return `<b>${fullDate}</b>`;
      }
    };

    const tooltipLines = [];
    const step = 3; // Show data every 3 hours
    let currentDayIndex = -1;

    for (let i = 0; i < time.length; i += step) {
        const timeStr = time[i];
        const dateObj = new Date(timeStr);
        const dayDiff = Math.floor((dateObj.getTime() - todayMidnight) / (1000 * 60 * 60 * 24));

        if (dayDiff < 0) continue; 
        if (dayDiff >= 3) break;

        // Header for the day
        if (dayDiff !== currentDayIndex) {
            if (currentDayIndex !== -1) tooltipLines.push(''); 
            tooltipLines.push(getHumanizedDate(timeStr));
            currentDayIndex = dayDiff;
        }

        // For today, skip hours that have already passed, but keep the current 3-hour block
        if (dayDiff === 0 && dateObj.getHours() < now.getHours() - step + 1) {
            continue;
        }

        const tempC = Math.round(temperature_2m[i]);
        const windKmph = Math.round(wind_speed_10m[i]);
        const humidity = Math.round(relative_humidity_2m[i]);
        const code = weather_code[i];
        const precipProb = precipitation_probability[i];
        
        const weatherInfo = WEATHER_CODES[code] || { icon: '🌡️', desc: 'Unknown' };
        
        let precipStr = '';
        if (precipProb > 0) {
            precipStr = `☔ ${precipProb}% `;
        }
        
        const line = `${formatTime(timeStr)} ${weatherInfo.icon} ${tempC}°C | 💨 ${windKmph}km/h 💧 ${humidity}% | ${precipStr}${weatherInfo.desc}`;
        tooltipLines.push(line);
    }

    const currentCode = current_weather.weathercode;
    const currentTemp = Math.round(current_weather.temperature);
    const currentIcon = (WEATHER_CODES[currentCode] || { icon: '🌡️' }).icon;

    const result = {
      text: `${currentIcon} ${currentTemp}°C`,
      tooltip: tooltipLines.join('\n')
    };

    console.log(JSON.stringify(result));

  } catch (error) {
    console.error(error);
    const errorResult = {
        text: '⚠️ N/A',
        tooltip: `Weather data unavailable: ${error.message || error}`
    };
    console.log(JSON.stringify(errorResult));
  }
})();