import os, time, threading, sqlite3, datetime as dt, requests
import subprocess, urllib.parse, re, math
from flask import Flask, jsonify, Response, render_template

# ────────── Konfiguration via ENV ──────────
INTERVAL  = int(os.getenv("CHECK_INTERVAL_SEC", 20))            # Sek. zw. Checks
RETENTION = int(os.getenv("RETENTION_DAYS",    60))             # Tage Aufbewahrung
TEST_URL  = os.getenv("TEST_URL", "https://1.1.1.1")            # Prüfdienst
DB_PATH   = os.getenv("DB_PATH", "data.db")

def get_utc_timestamp():
    """UTC-Timestamp zurückgeben (immer UTC, unabhängig von Container-Zeitzone)"""
    return int(dt.datetime.now(dt.timezone.utc).timestamp())

def ping_host():
    """Einmaliges Ping auf das TEST_URL-Host ausführen und Laufzeit in ms zurückgeben."""
    host = urllib.parse.urlparse(TEST_URL).hostname or TEST_URL
    try:
        r = subprocess.run(["ping", "-c", "1", "-W", "1", host], capture_output=True, text=True)
        if r.returncode == 0:
            m = re.search(r"time=([0-9.]+) ms", r.stdout)
            if m:
                return float(m.group(1))
    except Exception:
        pass
    return None

# ────────── Backend ──────────

app = Flask(__name__)

def init_db():
    """Tabelle anlegen, falls sie noch nicht existiert."""
    with sqlite3.connect(DB_PATH) as c:
        c.execute("CREATE TABLE IF NOT EXISTS status(ts INTEGER PRIMARY KEY, up INTEGER, ping REAL)")
        try:
            c.execute("ALTER TABLE status ADD COLUMN ping REAL")
        except sqlite3.OperationalError:
            pass

def write_sample():
    """Einen Connectivity-Datensatz schreiben und alte Daten trimmen."""
    ping_ms = ping_host()  # Ping immer messen, unabhängig vom HTTP-Test
    up = 1
    try:
        requests.get(TEST_URL, timeout=5)
    except requests.RequestException:
        up = 0
    
    now = get_utc_timestamp()  # UTC-Timestamp verwenden
    with sqlite3.connect(DB_PATH) as c:
        # INSERT OR REPLACE verwenden um Duplikate zu vermeiden
        c.execute("INSERT OR REPLACE INTO status(ts,up,ping) VALUES(?,?,?)", (now, up, ping_ms))
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
    return render_template('index.html')

@app.route("/data")
def data():
    # Alle Daten holen (ohne since Filter) um das Problem zu debuggen
    with sqlite3.connect(DB_PATH) as c:
        rows = c.execute("SELECT ts,up,ping FROM status ORDER BY ts").fetchall()
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
    
    # UTC-Zeit für alle Berechnungen
    now = get_utc_timestamp()
    
    # Basis-Daten für detaillierten Verlauf - nur letzten 12 Stunden
    twelve_hours_ago = now - (12 * 3600)  # 12 Stunden in Sekunden
    detail_rows = [row for row in rows if row[0] >= twelve_hours_ago]

    result = {
        "labels":[t for t,_,_ in detail_rows],  # Raw UTC timestamps der letzten 12h senden
        "values":[u for _,u,_ in detail_rows],
        "pings":[p for _,_,p in detail_rows]
    }
    
    # 24-Stunden-Aggregation (letzte 24h)
    current_hour_start = (now // 3600) * 3600  # Aktuelle Stunde, auf den Stundenanfang gerundet
    hourly_data = []

    for h in range(24):
        # Von der aktuellen Stunde 23 Stunden zurückgehen
        hour_start = current_hour_start - (h * 3600)
        hour_end = hour_start + 3600
        hour_rows = [(up, ping) for ts, up, ping in rows if hour_start <= ts < hour_end]

        if hour_rows:
            ups = [u for u, _ in hour_rows]
            pings = [p for _, p in hour_rows if p is not None]
            uptime = sum(ups) / len(ups)
            ping_avg = sum(pings) / len(pings) if pings else None
            if pings:
                k = max(0, min(len(pings)-1, math.ceil(len(pings) * 0.99) - 1))
                ping_p99 = sorted(pings)[k]
            else:
                ping_p99 = None
        else:
            uptime = -1  # Keine Daten verfügbar
            ping_avg = ping_p99 = None

        # Nur die Stunde des Tages (0-23) senden
        hour_of_day = dt.datetime.fromtimestamp(hour_start, dt.timezone.utc).hour
        hourly_data.insert(0, {"hour": hour_of_day, "uptime": uptime, "ping_avg": ping_avg, "ping_p99": ping_p99})
    
    # Tages-Aggregation (letzte 30 Tage) - korrekte Kalendertage verwenden
    daily_data = []
    current_utc_date = dt.datetime.fromtimestamp(now, dt.timezone.utc).date()
    
    for d in range(30):
        # Kalendertag berechnen (d Tage zurück vom heutigen Tag)
        target_date = current_utc_date - dt.timedelta(days=d)

        # Start und Ende des Kalendertages in UTC
        day_start_dt = dt.datetime.combine(target_date, dt.time.min).replace(tzinfo=dt.timezone.utc)
        day_end_dt = dt.datetime.combine(target_date, dt.time.max).replace(tzinfo=dt.timezone.utc)

        day_start = int(day_start_dt.timestamp())
        day_end = int(day_end_dt.timestamp())

        day_rows = [(up, ping) for ts, up, ping in rows if day_start <= ts <= day_end]

        if day_rows:
            ups = [u for u, _ in day_rows]
            pings = [p for _, p in day_rows if p is not None]
            uptime = sum(ups) / len(ups)
            ping_avg = sum(pings) / len(pings) if pings else None
            if pings:
                k = max(0, min(len(pings)-1, math.ceil(len(pings) * 0.99) - 1))
                ping_p99 = sorted(pings)[k]
            else:
                ping_p99 = None
        else:
            uptime = -1  # Keine Daten verfügbar
            ping_avg = ping_p99 = None

        # UTC-Timestamp für Tagesbeginn senden
        daily_data.insert(0, {"date": day_start, "uptime": uptime, "ping_avg": ping_avg, "ping_p99": ping_p99})
    
    result["hourly"] = hourly_data
    result["daily"] = daily_data
    
    return jsonify(result)

if __name__ == "__main__":
    init_db()
    write_sample()                              # sofort ersten Punkt speichern
    threading.Thread(target=monitor_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=8000)
