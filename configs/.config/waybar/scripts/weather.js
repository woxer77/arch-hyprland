(async function () {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);
    const response = await fetch('https://wttr.in/?format=j1', { signal: controller.signal });
    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    if (!data.weather || !data.nearest_area) {
      throw new Error('Invalid API response structure');
    }

    const { weather, nearest_area: nearestArea } = data;
    const city = nearestArea[0].areaName[0].value;
    const country = nearestArea[0].country[0].value;
    const WEATHER_CODES = {
      113: '☀️',
      116: '⛅',
      119: '☁️',
      122: '☁️',
      143: '☁️',
      176: '🌧️',
      179: '🌧️',
      182: '🌧️',
      185: '🌧️',
      200: '⛈️',
      227: '🌨️',
      230: '🌨️',
      248: '☁️',
      260: '☁️',
      263: '🌧️',
      266: '🌧️',
      281: '🌧️',
      284: '🌧️',
      293: '🌧️',
      296: '🌧️',
      299: '🌧️',
      302: '🌧️',
      305: '🌧️',
      308: '🌧️',
      311: '🌧️',
      314: '🌧️',
      317: '🌧️',
      320: '🌨️',
      323: '🌨️',
      326: '🌨️',
      329: '❄️',
      332: '❄️',
      335: '❄️',
      338: '❄️',
      350: '🌧️',
      353: '🌧️',
      356: '🌧️',
      359: '🌧️',
      362: '🌧️',
      365: '🌧️',
      368: '🌧️',
      371: '❄️',
      374: '🌨️',
      377: '🌨️',
      386: '🌨️',
      389: '🌨️',
      392: '🌧️',
      395: '❄️'
    };
    const API_HOURS_GAP = 3;
    const API_HOURS_COUNT = weather[0].hourly.length;
    const TOOLTIP_DAYS_TO_DISPLAY = 3;
    const now = new Date();
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const currHour = now.getHours();

    const humanizeTime = inputTime => {
      if (inputTime === '0') return '00:00';
      if (inputTime.length === 3) return `0${inputTime[0]}:00`;
      if (inputTime.length === 4) return `${inputTime[0]}${inputTime[1]}:00`;
      return '00:00';
    };

    const getHumanizedDate = inputDate => {
      const inputTimeObj = new Date(inputDate);

      const inputDateMidnight = new Date(
        inputTimeObj.getFullYear(),
        inputTimeObj.getMonth(),
        inputTimeObj.getDate()
      ).getTime();
      const daysDifference = Math.floor(
        (inputDateMidnight - todayMidnight) / (1000 * 60 * 60 * 24)
      );

      const date = inputTimeObj.getDate().toString().padStart(2, '0');
      const month = (inputTimeObj.getMonth() + 1).toString().padStart(2, '0');
      const year = inputTimeObj.getFullYear();
      const dateString = `${date}/${month}/${year}`;

      if (daysDifference === 0) {
        return {
          output: `<b>Today, ${dateString}, ${city}(${country})</b>\n`,
          idx: Math.floor(currHour / API_HOURS_GAP)
        };
      } else if (daysDifference === 1) {
        return { output: `<b>Tomorrow, ${dateString}</b>\n`, idx: 0 };
      } else return { output: `<b>${dateString}</b>\n`, idx: 0 };
    };

    const getHoursBundle = (weatherDay, startHoursIdx) => {
      const hoursBundle = [];
      for (let i = startHoursIdx; i < API_HOURS_COUNT; i++) {
        hoursBundle.push(weatherDay.hourly[i]);
      }
      return hoursBundle;
    };

    const tooltipWeather = [];
    const currHourWeather = {};
    for (let i = 0; i < TOOLTIP_DAYS_TO_DISPLAY; i++) {
      const { output: dateTitle, idx: startHoursIdx } = getHumanizedDate(weather[i].date);
      const hoursBundle = getHoursBundle(weather[i], startHoursIdx);

      tooltipWeather.push(dateTitle);
      if (i === 0) {
        currHourWeather.weatherCode = hoursBundle[0].weatherCode;
        currHourWeather.tempC = hoursBundle[0].tempC;
      }

      for (let j = 0; j < hoursBundle.length; j++) {
        const hour = hoursBundle[j];
        let precipitationStr = '';

        if (hour.chanceofrain > 0) precipitationStr += `☔ ${hour.chanceofrain}% `;
        if (hour.chanceofthunder > 0) precipitationStr += `⛈️ ${hour.chanceofthunder}% `;
        if (hour.chanceofsnow > 0) precipitationStr += `🌨️ ${hour.chanceofsnow}% `;
        if (hour.cloudcover > 20) precipitationStr += `☁️ ${hour.cloudcover}% `;
        if (hour.chanceoffog > 20) precipitationStr += `🌫️ ${hour.chanceoffog}% `;

        tooltipWeather.push(
          `${humanizeTime(hour.time)} ${WEATHER_CODES[hour.weatherCode]} ${hour.tempC}°C | 💨 ${
            hour.windspeedKmph
          }km/h 💧 ${hour.humidity}% | ${precipitationStr}${hour?.weatherDesc?.[0]?.value}`
        );

        if (i !== TOOLTIP_DAYS_TO_DISPLAY - 1 || j !== hoursBundle.length - 1) {
          tooltipWeather.push('\n'); // end of the hour
        }
      }
      if (i < TOOLTIP_DAYS_TO_DISPLAY - 1) {
        // end of the day
        tooltipWeather.push('\n');
      }
    }

    const result = {
      text: `${WEATHER_CODES[currHourWeather.weatherCode] || '🌡️'} ${currHourWeather.tempC}°C`,
      tooltip: tooltipWeather.join('')
    };

    console.log(JSON.stringify(result));
  } catch (error) {
    console.error(error);
    console.log(
      JSON.stringify({
        text: '⚠️ N/A',
        tooltip: `Weather data unavailable: ${error.message}`
      })
    );
  }
})();
