import os
import sys

def menu():
    print("\n💀 GENPY CYBERSECURITY SUITE ACTIVE 💀")
    print("════════════════════════════════════════")
    print("1) Run Custom ARP Scanner (Scapy)")
    print("2) Audit Target with Nmap (Port Scan)")
    print("3) Test Web Vulnerabilities (Sqlmap)")
    print("0) Exit Sandbox")
    print("════════════════════════════════════════")
    
    choice = input(">>> ")
    
    if choice == "1":
        # Ejecutar tu scanner nativo llamando al intérprete de python con sudo interno
        os.system("sudo python3 src/scanner.py")
    elif choice == "2":
        target = input("🎯 Ingresa la IP o Subred objetivo (ej: 172.20.0.3): ")
        print(f"\n🚀 Lanzando Nmap (Escaneo de servicios y versiones)...")
        os.system(f"nmap -sV -sC {target}")
    elif choice == "3":
        url = input("🌐 Ingresa la URL vulnerable (ej: http://172.20.0.3/index.php?id=1): ")
        print(f"\n🚀 Iniciando auditoría de inyección SQL con Sqlmap...")
        os.system(f"sqlmap -u '{url}' --batch --banner")
    elif choice == "0":
        print("🚪 Saliendo de la suite de seguridad.")
        sys.exit(0)
    else:
        print("⚠️ Opción inválida.")

if __name__ == "__main__":
    while True:
        menu()