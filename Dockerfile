FROM python:3.12-alpine
WORKDIR /app
RUN pip install --no-cache-dir flask requests

# ── Skript reinschreiben ──────────────────────────────────────────────
RUN cat <<'PY' > /app/monitor.py
import sqlite3, threading, time, datetime as dt, os, requests
from flask import Flask, jsonify, Response

INTERVAL  = int(os.getenv("CHECK_INTERVAL_SEC", 10))   # Sekunden
RETENTION = int(os.getenv("RETENTION_DAYS", 1000))       # Tage
TEST_URL  = os.getenv("TEST_URL", "https://1.1.1.1")   # DNS-frei
DB_PATH   = os.getenv("DB_PATH", "data.db")

HTML_PAGE = """<!doctype html><html lang=de>
<head><meta charset=utf-8><title>Internet-Monitor</title>
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
let chart;                            // globales Chart-Objekt

async function reloadData(){
  const r = await fetch('/data');
  const {labels,values} = await r.json();
  const txt  = values.length
               ? (values.at(-1) ? '🟢 Verbindung steht' : '🔴 Keine Verbindung')
               : 'Noch keine Daten';
  document.getElementById('status').textContent = txt;

  if(!values.length){                // erst messen, dann zeichnen
    if(chart){ chart.destroy(); chart = null; }
    return;
  }
  const ctx = document.getElementById('c').getContext('2d');
  if(!chart){
    chart = new Chart(ctx,{
      type:'line',
      data:{labels,
            datasets:[{label:'Online (1) / Offline (0)',
                       data:values,
                       stepped:true,
                       fill:true}]},
      options:{scales:{
          y:{ticks:{stepSize:1,callback:v=>v?'Online':'Offline'},min:0,max:1},
          x:{type:'time',time:{unit:'hour'}}
      }}
    });
  }else{
    chart.data.labels = labels;
    chart.data.datasets[0].data = values;
    chart.update();
  }
}

reloadData();                       // initial
setInterval(reloadData, 60000);     // jede Minute
</script></body></html>"""

app = Flask(__name__)

def init_db():
    with sqlite3.connect(DB_PATH) as c:
        c.execute("CREATE TABLE IF NOT EXISTS status(ts INTEGER PRIMARY KEY, up INTEGER)")

def write_sample():
    up = 1
    try: requests.get(TEST_URL, timeout=5)
    except requests.RequestException: up = 0
    now = int(time.time())
    with sqlite3.connect(DB_PATH) as c:
        c.execute("INSERT INTO status VALUES(?,?)", (now, up))
        c.execute("DELETE FROM status WHERE ts < ?", (now-RETENTION*86400))

def monitor():
    while True:
        write_sample()
        time.sleep(INTERVAL)

@app.route("/")
def index(): return Response(HTML_PAGE, mimetype="text/html")

@app.route("/data")
def data():
    since = int(time.time()) - RETENTION*86400
    with sqlite3.connect(DB_PATH) as c:
        rows = c.execute("SELECT ts,up FROM status WHERE ts>=? ORDER BY ts",(since,)).fetchall()
    return jsonify({"labels":[dt.datetime.fromtimestamp(t).isoformat() for t,_ in rows],
                    "values":[u for _,u in rows]})

if __name__ == "__main__":
    init_db()
    write_sample()                  # sofort erste Messung
    threading.Thread(target=monitor, daemon=True).start()
    app.run(host="0.0.0.0", port=8000)
PY

EXPOSE 8000
CMD ["python", "monitor.py"]
