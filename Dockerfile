# ─────────────────────────  Basis-Image  ────────────────────────────
FROM python:3.12-alpine

WORKDIR /app

# Flask & Requests schlank installieren
RUN pip install --no-cache-dir flask requests

# ─────────────────────  Monitoring-Script einbetten  ────────────────
RUN cat <<'PY' > /app/monitor.py
import os, time, threading, sqlite3, datetime as dt, requests
from flask import Flask, jsonify, Response

# ────────── Konfiguration via ENV ──────────
INTERVAL  = int(os.getenv("CHECK_INTERVAL_SEC", 60))            # Sek. zw. Checks
RETENTION = int(os.getenv("RETENTION_DAYS",    30))             # Tage Aufbewahrung
TEST_URL  = os.getenv("TEST_URL", "https://1.1.1.1")            # Prüfdienst
DB_PATH   = os.getenv("DB_PATH", "data.db")

# ────────── Ein-Seiten-Frontend (Chart.js + date-fns Adapter) ─────────
HTML_PAGE = """<!doctype html><html lang=de>
<head><meta charset=utf-8><title>Internet-Verbindungsmonitor</title>
<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
<script src='https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3'></script>
<style>
  body{font-family:sans-serif;margin:2rem}
  #status{font-size:1.2rem;margin-bottom:1rem}
</style></head>
<body>
  <h1>Internet-Verbindungsmonitor</h1>
  <p id=status>Starte …</p>
  <canvas id=c height=80></canvas>

<script>
let chart=null;

async function reloadData(){
  const r = await fetch('/data');
  const {labels,values} = await r.json();

  // Status-Text setzen
  const statusTxt = values.length
        ? (values.at(-1) ? '🟢 Verbindung steht' : '🔴 Keine Verbindung')
        : 'Noch keine Daten';
  document.getElementById('status').textContent = statusTxt;

  // Erst zeichnen, wenn Daten vorhanden
  if(!values.length){ if(chart){chart.destroy();chart=null;} return; }

  if(!chart){
    chart = new Chart(document.getElementById('c'),{
      type:'line',
      data:{labels,
            datasets:[{label:'Online-Status',data:values,stepped:true,fill:true}]},
      options:{scales:{
        y:{min:0,max:1,ticks:{stepSize:1,callback:v=>v?'Online':'Offline'}},
        x:{type:'time',time:{unit:'hour'}}
      }}
    });
  }else{
    chart.data.labels = labels;
    chart.data.datasets[0].data = values;
    chart.update();
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
    try: requests.get(TEST_URL, timeout=5)
    except requests.RequestException: up = 0
    now = int(time.time())
    with sqlite3.connect(DB_PATH) as c:
        c.execute("INSERT INTO status VALUES(?,?)", (now, up))
        c.execute("DELETE FROM status WHERE ts < ?", (now - RETENTION*86400,))  # ← tuple!

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
    since = int(time.time()) - RETENTION*86400
    with sqlite3.connect(DB_PATH) as c:
        rows = c.execute("SELECT ts,up FROM status WHERE ts>=? ORDER BY ts",(since,)).fetchall()
    return jsonify({
        "labels":[dt.datetime.fromtimestamp(t).isoformat() for t,_ in rows],
        "values":[u for _,u in rows]
    })

if __name__ == "__main__":
    init_db()
    write_sample()                              # sofort ersten Punkt speichern
    threading.Thread(target=monitor_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=8000)
PY

# ─────────────────────────  Laufzeit  ────────────────────────────────
EXPOSE 8000
CMD ["python", "monitor.py"]
