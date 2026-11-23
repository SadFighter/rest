import http.server
import socketserver
import json
import os
import platform
import subprocess
import webbrowser
import threading
import time

PORT = 8000
PROFILE_FILE = 'profile.json'

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/sysinfo':
            info = {
                "os": platform.system(),
                "cpu_cores": os.cpu_count() or 1,
                "ram_total": 0,
                "ram_used": 0
            }
            try:
                if platform.system() == "Linux":
                    with open('/proc/meminfo', 'r') as f:
                        lines = f.readlines()
                        mem_total = int(lines[0].split()[1]) * 1024
                        mem_free = int(lines[1].split()[1]) * 1024
                        info["ram_total"] = mem_total
                        info["ram_used"] = mem_total - mem_free
                elif platform.system() == "Darwin":
                    total = int(subprocess.check_output(['sysctl', '-n', 'hw.memsize']).strip())
                    info["ram_total"] = total
                    info["ram_used"] = total // 2 
                elif platform.system() == "Windows":
                    out = subprocess.check_output(['wmic', 'OS', 'get', 'TotalVisibleMemorySize,FreePhysicalMemory', '/format:csv']).decode()
                    lines = [l for l in out.split('\n') if l.strip()]
                    if len(lines) > 1:
                        parts = lines[1].split(',')
                        free = int(parts[1]) * 1024
                        total = int(parts[2]) * 1024
                        info["ram_total"] = total
                        info["ram_used"] = total - free
            except Exception as e:
                print("Errore lettura RAM:", e)

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(info).encode('utf-8'))

        elif self.path == '/api/profile-status':
            exists = os.path.exists(PROFILE_FILE)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"setup_complete": exists}).encode('utf-8'))

        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/api/save-profile':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                with open(PROFILE_FILE, 'w') as f:
                    json.dump(data, f, indent=2)
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ok"}).encode('utf-8'))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    
    # Se il profilo non esiste, apriamo il browser in kiosk mode
    if not os.path.exists(PROFILE_FILE):
        print("Nessun profilo trovato. Apertura della pagina di setup in Kiosk Mode...")
        def open_browser():
            time.sleep(1.5)
            # Apre Firefox in kiosk. Se non è nel PATH, usa il browser di default
            try:
                subprocess.Popen(["firefox", "--kiosk", f"http://localhost:{PORT}/setup.html"])
            except FileNotFoundError:
                webbrowser.open(f'http://localhost:{PORT}/setup.html')
        
        threading.Thread(target=open_browser, daemon=True).start()
    else:
        print("Profilo trovato. In attesa di richieste...")

    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        print(f"Server in ascolto su http://localhost:{PORT}")
        httpd.serve_forever()
