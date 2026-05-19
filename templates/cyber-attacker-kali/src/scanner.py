import os
import sys
from scapy.all import ARP, Ether, srp

def scan_network(target_ip):
    print(f"🕵️‍♂️ Iniciando escaneo ARP táctico en: {target_ip}")
    
    # 1. Crear el paquete ARP para solicitar direcciones MAC de la subred
    arp_request = ARP(pdst=target_ip)
    
    # 2. Crear el paquete Ethernet de Broadcast (enviar a todos)
    broadcast = Ether(dst="ff:ff:ff:ff:ff:ff")
    
    # 3. Fusionar ambos paquetes (Capa 2 + Capa 3)
    packet = broadcast / arp_request
    
    # 4. Enviar el paquete y capturar las respuestas (srp = Send and Receive Packets)
    print("📡 Emitiendo ráfaga de paquetes en la red virtual...")
    answered_list = srp(packet, timeout=2, verbose=False)[0]
    
    print("\n🖥️  DISPOSITIVOS DETECTADOS EN EL LABORATORIO:")
    print("--------------------------------------------------")
    print("Dirección IP\t\tDirección MAC (Física)")
    print("--------------------------------------------------")
    
    clients = []
    for element in answered_list:
        client_dict = {"ip": element[1].psrc, "mac": element[1].hwsrc}
        clients.append(client_dict)
        print(f"{client_dict['ip']}\t\t{client_dict['mac']}")
        
    print("--------------------------------------------------")
    return clients

if __name__ == "__main__":
    # Validar defensivamente si se ejecuta como root (Scapy requiere privilegios para forjar paquetes)
    if os.getuid() != 0:
        print("❌ Error Crítico: Scapy requiere privilegios de Root/Sudo para inyectar paquetes a nivel de hardware.")
        sys.exit(1)
        
    # Usar IP por defecto del laboratorio cerrado si no se pasa un argumento
    target = sys.argv[1] if len(sys.argv) > 1 else "172.20.0.0/24"
    scan_network(target)