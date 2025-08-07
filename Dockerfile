# ─────────────────────────  Basis-Image  ────────────────────────────
FROM python:3.12-alpine

WORKDIR /app

# Zeitzone auf UTC setzen für konsistente Zeitstempel
ENV TZ=UTC
RUN apk add --no-cache tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Flask & Requests schlank installieren
RUN pip install --no-cache-dir flask requests

# ─────────────────────  Monitoring-Script einbetten  ────────────────
RUN cat <<'PY' > /app/monitor.py
import os, time, threading, sqlite3, datetime as dt, requests
from flask import Flask, jsonify, Response

# ────────── Konfiguration via ENV ──────────
INTERVAL  = int(os.getenv("CHECK_INTERVAL_SEC", 20))            # Sek. zw. Checks
RETENTION = int(os.getenv("RETENTION_DAYS",    60))             # Tage Aufbewahrung
TEST_URL  = os.getenv("TEST_URL", "https://1.1.1.1")            # Prüfdienst
DB_PATH   = os.getenv("DB_PATH", "data.db")

def get_utc_timestamp():
    """UTC-Timestamp zurückgeben (immer UTC, unabhängig von Container-Zeitzone)"""
    return int(dt.datetime.now(dt.timezone.utc).timestamp())

# ────────── Ein-Seiten-Frontend (Chart.js + date-fns Adapter) ─────────
HTML_PAGE = """<!doctype html><html lang=de>
<head><meta charset=utf-8><title>Internet-Verbindungsmonitor</title>
<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
<script src='https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3'></script>
<style>
  body{font-family:sans-serif;margin:2rem}
  #status{font-size:1.2rem;margin-bottom:1rem}
  .chart-container{margin-bottom:2rem}
  .chart-title{font-size:1.1rem;font-weight:bold;margin-bottom:0.5rem}
  .legend{background:#f5f5f5;padding:1rem;border-radius:8px;margin-bottom:2rem}
  .legend-item{display:inline-block;margin-right:2rem;margin-bottom:0.5rem}
  .legend-color{display:inline-block;width:20px;height:15px;margin-right:8px;vertical-align:middle;border-radius:3px}
</style></head>
<body>
  <h1>Internet-Verbindungsmonitor</h1>
  <p id=status>Starte …</p>
  
  <div class="legend">
    <strong>Verfügbarkeitsstufen:</strong><br>
    <div class="legend-item"><span class="legend-color" style="background:#4ade80"></span>Exzellent (≥99,9%)</div>
    <div class="legend-item"><span class="legend-color" style="background:#eab308"></span>Gut (98,0-99,8%)</div>
    <div class="legend-item"><span class="legend-color" style="background:#ef4444"></span>Problematisch (<98%)</div>
    <div class="legend-item"><span class="legend-color" style="background:#3b82f6"></span>Keine Daten</div>
  </div>
  
  <div class="chart-container">
    <div class="chart-title">Detaillierter Verlauf</div>
    <canvas id=c height=80></canvas>
  </div>
  
  <div class="chart-container">
    <div class="chart-title">24-Stunden-Übersicht (letzte 24h)</div>
    <canvas id=hourlyChart height=60></canvas>
  </div>
  
  <div class="chart-container">
    <div class="chart-title">Tagesübersicht (letzte 30 Tage)</div>
    <canvas id=dailyChart height=60></canvas>
  </div>

<script>
let chart=null, hourlyChart=null, dailyChart=null;

// Hilfsfunktion: UTC-Timestamp zu lokaler Zeit konvertieren
function utcToLocal(utcTimestamp) {
  return new Date(utcTimestamp * 1000);
}

// Hilfsfunktion: UTC-Stunde zu lokaler Stunde umrechnen und formatieren
function formatHourLabel(utcHour) {
  // UTC-Stunde in lokale Stunde umrechnen
  const now = new Date();
  const utcTime = new Date(now.getTime() + (now.getTimezoneOffset() * 60000));
  utcTime.setUTCHours(utcHour, 0, 0, 0);
  const localHour = utcTime.getHours();
  return localHour.toString().padStart(2, '0') + ':00';
}

// Hilfsfunktion: UTC-Timestamp zu lokalem Tages-Label  
function formatDayLabel(utcTimestamp) {
  const localDate = utcToLocal(utcTimestamp);
  return localDate.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit' });
}

async function reloadData(){
  const r = await fetch('/data');
  const {labels,values,hourly,daily} = await r.json();

  // Status-Text setzen
  const statusTxt = values.length
        ? (values.at(-1) ? '🟢 Verbindung steht' : '🔴 Keine Verbindung')
        : 'Noch keine Daten';
  document.getElementById('status').textContent = statusTxt;

  // Detaillierter Verlauf - UTC-Timestamps zu lokalen Zeiten konvertieren
  const localLabels = labels.map(utcTimestamp => utcToLocal(utcTimestamp).toISOString());
  
  if(!chart){
    chart = new Chart(document.getElementById('c'),{
      type:'line',
      data:{labels:localLabels,
            datasets:[{label:'Online-Status',data:values,stepped:true,fill:true}]},
      options:{scales:{
        y:{min:0,max:1,ticks:{stepSize:1,callback:v=>v?'Online':'Offline'}},
        x:{type:'time',time:{unit:'hour'}}
      }}
    });
  }else{
    chart.data.labels = localLabels;
    chart.data.datasets[0].data = values;
    chart.update();
  }
  
  // 24-Stunden-Chart - UTC zu lokaler Zeit konvertieren
  if(hourly && hourly.length){
    if(!hourlyChart){
      hourlyChart = new Chart(document.getElementById('hourlyChart'),{
        type:'bar',
        data:{
          labels:hourly.map(h=>h.uptime<0 ? formatHourLabel(h.hour)+' ?' : formatHourLabel(h.hour)),
          datasets:[{
            label:'Stündlicher Status',
            data:hourly.map(h=>h.uptime<0?0.5:h.uptime),
            backgroundColor:hourly.map(h=>h.uptime<0?'#3b82f6':(h.uptime>=0.999?'#4ade80':(h.uptime>=0.98?'#eab308':'#ef4444'))),
            borderWidth:0
          }]
        },
        options:{
          responsive:true,
          scales:{
            y:{min:0,max:1,ticks:{stepSize:0.2,callback:v=>(v*100).toFixed(0)+'%'}},
            x:{title:{display:true,text:'Stunde (Ortszeit)'}}
          },
          plugins:{
            tooltip:{
              callbacks:{
                label:ctx=>{
                  const hourData = hourly[ctx.dataIndex];
                  return hourData.uptime<0 ? 'Keine Daten verfügbar' : `Verfügbarkeit: ${(ctx.parsed.y*100).toFixed(1)}%`;
                }
              }
            }
          }
        }
      });
    }else{
      hourlyChart.data.labels = hourly.map(h=>h.uptime<0 ? formatHourLabel(h.hour)+' ?' : formatHourLabel(h.hour));
      hourlyChart.data.datasets[0].data = hourly.map(h=>h.uptime<0?0.5:h.uptime);
      hourlyChart.data.datasets[0].backgroundColor = hourly.map(h=>h.uptime<0?'#3b82f6':(h.uptime>=0.999?'#4ade80':(h.uptime>=0.98?'#eab308':'#ef4444')));
      hourlyChart.update();
    }
  }
  
  // Tages-Chart - UTC zu lokaler Zeit konvertieren
  if(daily && daily.length){
    if(!dailyChart){
      dailyChart = new Chart(document.getElementById('dailyChart'),{
        type:'bar',
        data:{
          labels:daily.map(d=>d.uptime<0 ? formatDayLabel(d.date)+' ?' : formatDayLabel(d.date)),
          datasets:[{
            label:'Täglicher Status',
            data:daily.map(d=>d.uptime<0?0.5:d.uptime),
            backgroundColor:daily.map(d=>d.uptime<0?'#3b82f6':(d.uptime>=0.999?'#4ade80':(d.uptime>=0.98?'#eab308':'#ef4444'))),
            borderWidth:0
          }]
        },
        options:{
          responsive:true,
          scales:{
            y:{min:0,max:1,ticks:{stepSize:0.2,callback:v=>(v*100).toFixed(0)+'%'}},
            x:{title:{display:true,text:'Tag (Ortszeit)'}}
          },
          plugins:{
            tooltip:{
              callbacks:{
                label:ctx=>{
                  const dayData = daily[ctx.dataIndex];
                  return dayData.uptime<0 ? 'Keine Daten verfügbar' : `Verfügbarkeit: ${(ctx.parsed.y*100).toFixed(1)}%`;
                }
              }
            }
          }
        }
      });
    }else{
      dailyChart.data.labels = daily.map(d=>d.uptime<0 ? formatDayLabel(d.date)+' ?' : formatDayLabel(d.date));
      dailyChart.data.datasets[0].data = daily.map(d=>d.uptime<0?0.5:d.uptime);
      dailyChart.data.datasets[0].backgroundColor = daily.map(d=>d.uptime<0?'#3b82f6':(d.uptime>=0.999?'#4ade80':(d.uptime>=0.98?'#eab308':'#ef4444')));
      dailyChart.update();
    }
  }
}

reloadData();
setInterval(reloadData, 60000);   // jede Minute
</script></body></html>"""

# ────────── Backend ──────────
app = Flask(__name__)

def init_db():
    """Tabelle anlegen, falls sie noch nicht existiert."""
    with sqlite3.connect(DB_PATH) as c:
        c.execute("CREATE TABLE IF NOT EXISTS status(ts INTEGER PRIMARY KEY, up INTEGER)")

def write_sample():
    """Einen Connectivity-Datensatz schreiben und alte Daten trimmen."""
    up = 1
    try: 
        requests.get(TEST_URL, timeout=5)
    except requests.RequestException: 
        up = 0
    
    now = get_utc_timestamp()  # UTC-Timestamp verwenden
    with sqlite3.connect(DB_PATH) as c:
        # INSERT OR REPLACE verwenden um Duplikate zu vermeiden
        c.execute("INSERT OR REPLACE INTO status VALUES(?,?)", (now, up))
        # Alte Daten löschen - aber nur sehr alte (älter als RETENTION)
        cutoff = now - RETENTION*86400
        deleted = c.execute("DELETE FROM status WHERE ts < ?", (cutoff,)).rowcount
        total_count = c.execute("SELECT COUNT(*) FROM status").fetchone()[0]
        print(f"DEBUG: Inserted/updated ts={now}, up={up}, deleted {deleted} old records, total: {total_count}")

def monitor_loop():
    """Endlos-Loop, der alle INTERVAL Sekunden misst."""
    while True:
        write_sample()
        time.sleep(INTERVAL)

@app.route("/")
def index():
    return Response(HTML_PAGE, mimetype="text/html")

@app.route("/data")
def data():
    # Alle Daten holen (ohne since Filter) um das Problem zu debuggen
    with sqlite3.connect(DB_PATH) as c:
        rows = c.execute("SELECT ts,up FROM status ORDER BY ts").fetchall()
        total_count = c.execute("SELECT COUNT(*) FROM status").fetchone()[0]
    
    print(f"DEBUG: Total records: {total_count}, All records: {len(rows)}")
    if rows:
        print(f"DEBUG: First timestamp: {rows[0][0]}, Last timestamp: {rows[-1][0]}")
        print(f"DEBUG: Current UTC time: {get_utc_timestamp()}")
        
        # Nur die letzten RETENTION Tage für die Anzeige verwenden
        current_time = get_utc_timestamp()
        retention_cutoff = current_time - RETENTION*86400
        recent_rows = [row for row in rows if row[0] >= retention_cutoff]
        print(f"DEBUG: Recent records (last {RETENTION} days): {len(recent_rows)}")
        rows = recent_rows
    
    # Basis-Daten für detaillierten Verlauf - UTC-Timestamps senden
    result = {
        "labels":[t for t,_ in rows],  # Raw UTC timestamps senden
        "values":[u for _,u in rows]
    }
    
    # 24-Stunden-Aggregation (letzte 24h)
    now = get_utc_timestamp()
    current_hour_start = (now // 3600) * 3600  # Aktuelle Stunde, auf den Stundenanfang gerundet
    hourly_data = []
    
    for h in range(24):
        # Von der aktuellen Stunde 23 Stunden zurückgehen
        hour_start = current_hour_start - (h * 3600)
        hour_end = hour_start + 3600
        hour_rows = [up for ts, up in rows if hour_start <= ts < hour_end]
        
        if hour_rows:
            uptime = sum(hour_rows) / len(hour_rows)
        else:
            uptime = -1  # Keine Daten verfügbar
            
        # Nur die Stunde des Tages (0-23) senden
        hour_of_day = dt.datetime.fromtimestamp(hour_start, dt.timezone.utc).hour
        hourly_data.insert(0, {"hour": hour_of_day, "uptime": uptime})
    
    # Tages-Aggregation (letzte 30 Tage)
    daily_data = []
    for d in range(30):
        day_start = now - (d * 86400)
        day_end = day_start + 86400
        day_rows = [up for ts, up in rows if day_start <= ts < day_end]
        
        if day_rows:
            uptime = sum(day_rows) / len(day_rows)
        else:
            uptime = -1  # Keine Daten verfügbar
            
        # UTC-Timestamp für Tag senden
        daily_data.insert(0, {"date": day_start, "uptime": uptime})
    
    result["hourly"] = hourly_data
    result["daily"] = daily_data
    
    return jsonify(result)

if __name__ == "__main__":
    init_db()
    write_sample()                              # sofort ersten Punkt speichern
    threading.Thread(target=monitor_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=8000)
PY

# ─────────────────────────  Laufzeit  ────────────────────────────────
EXPOSE 8000
CMD ["python", "monitor.py"]
