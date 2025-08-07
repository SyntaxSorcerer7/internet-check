# ── Basis ────────────────────────────────────────────────────────────
FROM python:3.12-alpine

WORKDIR /app

# Benötigte Bibliotheken
RUN pip install --no-cache-dir flask requests

# ── Monitoring-Skript via Heredoc in /app/monitor.py schreiben ───────
RUN cat <<'PY' > /app/monitor.py
import sqlite3, threading, time, datetime as dt, os, requests
from flask import Flask, jsonify, Response

# ---------- Konfiguration über ENV ----------
INTERVAL   = int(os.getenv("CHECK_INTERVAL_SEC", 60))       # Sekunden
RETENTION  = int(os.getenv("RETENTION_DAYS",     30))       # Tage
TEST_URL   = os.getenv("TEST_URL", "https://www.google.com")
DB_PATH    = os.getenv("DB_PATH", "data.db")

# ---------- Ein-Seiten-GUI (Chart.js) ----------
HTML_PAGE = """<!doctype html><html lang=de>
<head><meta charset=utf-8><title>Internet-Monitor</title>
<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
<style>body{font-family:sans-serif;margin:2rem}#status{font-size:1.2rem}</style></head>
<body><h1>Internet-Verbindungsmonitor</h1><p id=status>Lade …</p><canvas id=c height=80></canvas>
<script>
async function reloadData(){
  const r = await fetch('/data');
  const {labels,values} = await r.json();
  document.getElementById('status').textContent =
      values.at(-1)?'🟢 Verbindung steht':'🔴 Keine Verbindung';
  new Chart(document.getElementById('c'),{
    type:'line',
    data:{labels,datasets:[{data:values,stepped:true,fill:true}]},
    options:{scales:{
        y:{ticks:{stepSize:1,callback:v=>v?'Online':'Offline'}},
        x:{type:'time',time:{unit:'hour'}}
    }}
  });
}
reloadData(); setInterval(()=>location.reload(),60000);
</script></body></html>"""

app = Flask(__name__)

# ---------- DB anlegen ----------
def init_db():
    with sqlite3.connect(DB_PATH) as c:
        c.execute("CREATE TABLE IF NOT EXISTS status(ts INTEGER PRIMARY KEY, up INTEGER)")

# ---------- Prüfschleife ----------
def monitor():
    while True:
        up = 1
        try:
            requests.get(TEST_URL, timeout=5)
        except requests.RequestException:
            up = 0
        now = int(time.time())
        with sqlite3.connect(DB_PATH) as c:
            c.execute("INSERT INTO status VALUES(?,?)", (now, up))
            cutoff = now - RETENTION*86400
            c.execute("DELETE FROM status WHERE ts < ?", (cutoff,))
        time.sleep(INTERVAL)

# ---------- Web-Endpunkte ----------
@app.route("/")
def index():
    return Response(HTML_PAGE, mimetype="text/html")

@app.route("/data")
def data():
    since = int(time.time()) - RETENTION*86400
    with sqlite3.connect(DB_PATH) as c:
        rows = c.execute(
            "SELECT ts, up FROM status WHERE ts>=? ORDER BY ts", (since,)
        ).fetchall()
    return jsonify({
        "labels":[dt.datetime.fromtimestamp(t).isoformat() for t,_ in rows],
        "values":[u for _,u in rows]
    })

# ---------- Start ----------
if __name__ == "__main__":
    init_db()
    threading.Thread(target=monitor, daemon=True).start()
    app.run(host="0.0.0.0", port=8000)
PY

# ── Laufzeit ──────────────────────────────────────────────────────────
EXPOSE 8000
CMD ["python", "monitor.py"]
