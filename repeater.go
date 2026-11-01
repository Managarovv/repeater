package main

import (
	"log"
	"os"
	"github.com/inetaf/tcpproxy"
)

func main() {
	var p tcpproxy.Proxy

	listenAddr := os.Getenv("LISTEN_ADDR")
	vpnSNI := os.Getenv("VPN_SNI")
	vpnTargetAddr := os.Getenv("VPN_TARGET_ADDR")
	localTargetAddr := os.Getenv("LOCAL_TARGET_ADDR")

	if vpnSNI == "" {
		log.Fatalf("Ошибка запуска: переменная окружения VPN_SNI не задана")
	}
	if vpnTargetAddr == "" {
		log.Fatalf("Ошибка запуска: переменная окружения VPN_TARGET_ADDR не задана")
	}
	if listenAddr == "" {
		listenAddr = ":443"
	}
	if localTargetAddr == "" {
		localTargetAddr = "127.0.0.1:8443"
	}

	// 1. SNI-маршрут: сработает ТОЛЬКО для amd.com
	p.AddSNIRoute(listenAddr, vpnSNI, tcpproxy.To(vpnTargetAddr))

	// 2. Правильный Fallback: заставляет дождаться парсинга SNI.
	// Если домен НЕ amd.com, трафик пойдет сюда.
	p.AddRoute(listenAddr, tcpproxy.To(localTargetAddr))

	log.Printf("SNI-роутер успешно запущен на %s", listenAddr)
	if err := p.Run(); err != nil {
		log.Fatal(err)
	}
}
