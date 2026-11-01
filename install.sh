#!/bin/sh
# Установщик OpenWrt Router Monitor.
#
#   Установка / обновление:
#     wget -qO- https://raw.githubusercontent.com/USER/REPO/main/install.sh | REPO=USER/REPO sh
#   Удаление:
#     wget -qO- https://raw.githubusercontent.com/USER/REPO/main/install.sh | REPO=USER/REPO sh -s uninstall
#
# Переменные (необязательно): BRANCH (по умолчанию main), BASE (свой URL папки files/), ROOT (префикс для тестов)

ROOT="${ROOT:-}"
BRANCH="${BRANCH:-main}"
CGI="$ROOT/www/cgi-bin/mon"
MENU="$ROOT/usr/share/luci/menu.d/luci-app-mon.json"
VIEW="$ROOT/www/luci-static/resources/view/mon.js"

say() { printf '%s\n' "$*"; }
die() { printf 'Ошибка: %s\n' "$*" >&2; exit 1; }

clear_cache() { rm -rf "$ROOT"/tmp/luci-indexcache* "$ROOT"/tmp/luci-modulecache; }

if [ "$1" = "uninstall" ]; then
	rm -f "$CGI" "$MENU" "$VIEW"
	clear_cache
	say "Удалено. Обнови страницу LuCI (Ctrl+F5)."
	exit 0
fi

if [ -z "$BASE" ]; then
	[ -n "$REPO" ] || die "не указан репозиторий. Запусти так: ... | REPO=user/repo sh"
	BASE="https://raw.githubusercontent.com/$REPO/$BRANCH/files"
fi

# fetch URL DEST [sh]  — качает во временный файл, проверяет и только потом подменяет
fetch() {
	tmp="$2.new"
	mkdir -p "$(dirname "$2")" || die "не могу создать папку для $2"
	if ! wget -q -O "$tmp" "$1"; then
		rm -f "$tmp"
		die "не скачалось $1
Если ругается на https, поставь: apk add ca-bundle libustream-mbedtls"
	fi
	[ -s "$tmp" ] || { rm -f "$tmp"; die "скачался пустой файл: $1"; }
	if [ "$3" = "sh" ]; then
		sh -n "$tmp" || { rm -f "$tmp"; die "скрипт $1 с синтаксической ошибкой"; }
	fi
	mv "$tmp" "$2"
}

say "Скачиваю файлы из $BASE ..."
fetch "$BASE/mon" "$CGI" sh
fetch "$BASE/luci-app-mon.json" "$MENU"
fetch "$BASE/mon.js" "$VIEW"
chmod +x "$CGI"
clear_cache

LANIP=$(uci -q get network.lan.ipaddr 2>/dev/null | cut -d/ -f1)
LANIP=${LANIP:-192.168.1.1}

say ""
say "Готово."
say "  Отдельная страница: http://$LANIP/cgi-bin/mon"
say "  В LuCI:             Services -> Монитор (обнови страницу через Ctrl+F5)"

if [ -f "$ROOT/etc/shadow" ] && grep -q '^root::' "$ROOT/etc/shadow"; then
	say ""
	say "ВНИМАНИЕ: у root не задан пароль. Задай его командой: passwd"
fi
