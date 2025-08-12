import os, time, threading, sqlite3, datetime as dt, requests
from flask import Flask, jsonify, Response, render_template

# ────────── Konfiguration via ENV ──────────
INTERVAL  = int(os.getenv("CHECK_INTERVAL_SEC", 20))            # Sek. zw. Checks
RETENTION = int(os.getenv("RETENTION_DAYS",    60))             # Tage Aufbewahrung
TEST_URL  = os.getenv("TEST_URL", "https://1.1.1.1")            # Prüfdienst
DB_PATH   = os.getenv("DB_PATH", "data.db")

def get_utc_timestamp():
    """UTC-Timestamp zurückgeben (immer UTC, unabhängig von Container-Zeitzone)"""
    return int(dt.datetime.now(dt.timezone.utc).timestamp())

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
    return render_template('index.html')

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
    
    # UTC-Zeit für alle Berechnungen
    now = get_utc_timestamp()
    
    # Basis-Daten für detaillierten Verlauf - nur letzten 12 Stunden
    twelve_hours_ago = now - (12 * 3600)  # 12 Stunden in Sekunden
    detail_rows = [row for row in rows if row[0] >= twelve_hours_ago]
    
    result = {
        "labels":[t for t,_ in detail_rows],  # Raw UTC timestamps der letzten 12h senden
        "values":[u for _,u in detail_rows]
    }
    
    # 24-Stunden-Aggregation (letzte 24h)
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
        
        day_rows = [up for ts, up in rows if day_start <= ts <= day_end]
        
        if day_rows:
            uptime = sum(day_rows) / len(day_rows)
        else:
            uptime = -1  # Keine Daten verfügbar
            
        # UTC-Timestamp für Tagesbeginn senden
        daily_data.insert(0, {"date": day_start, "uptime": uptime})
    
    result["hourly"] = hourly_data
    result["daily"] = daily_data
    
    return jsonify(result)

if __name__ == "__main__":
    init_db()
    write_sample()                              # sofort ersten Punkt speichern
    threading.Thread(target=monitor_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=8000)
