# 🏹 Laboratorio Objetivo Vulnerable - GenPy

Este entorno contiene un nodo deliberadamente vulnerable diseñado para practicar técnicas de hacking ético, escaneo de vulnerabilidades y explotación de servicios en un entorno 100% controlado y legal.

## 📡 Información de Red del Laboratorio
* **Subred de Pruebas:** `172.20.0.0/24`
* **IP del Objetivo Fijo:** `172.20.0.5`

## 🎯 Objetivos de Aprendizaje (Retos)
1. **Reconocimiento:** Usa tu contenedor de Kali (`cyber-attacker-kali`) para correr un escaneo con `nmap` hacia la IP `172.20.0.5` e identifica qué servicios están corriendo en los puertos 21, 22 y 80.
2. **Explotación Web:** Ingresa desde el navegador de tu Mac a `http://localhost:8080` para interactuar con las aplicaciones web vulnerables instaladas (DVWA, Mutillidae).
3. **Fuerza Bruta:** Intenta usar la herramienta `hydra` desde tu máquina atacante para descifrar las credenciales del servicio SSH en el puerto 22.

## ⚠️ Advertencia de Seguridad
Este contenedor está diseñado bajo las mejores prácticas de aislamiento. No modifiques la configuración de `networks` a modo `host` para evitar exponer estos servicios vulnerables a redes públicas o internet.