# OpenWrt Router Monitor

Лёгкая веб-панель для OpenWrt: кто и куда подключается через роутер. Один CGI-скрипт на shell/awk, без пакетов, без демонов, ничего не висит в памяти между запросами.

## Возможности

- **Подключения**: таблица соединений из conntrack, флаги стран по IP, кнопки по каждому устройству в сети, поиск.
- **Роутер**: куда ходит сам роутер и с какого IP (sing-box/podkop, NTP, DNS, обновления).
- **Сервисы**: какой процесс к кому подключён и что слушает порты.
- **Клиенты**: устройства из DHCP и число их соединений, клик открывает их подключения.
- **Логи** и **Podkop**: системный лог и лог podkop со статусом sing-box.
- Пункт в меню LuCI: Services → Монитор.

## Установка

По SSH на роутере (замени `USER/REPO` на свой репозиторий):

```sh
wget -qO- https://raw.githubusercontent.com/USER/REPO/main/install.sh | REPO=USER/REPO sh
```

После установки открой `http://192.168.1.1/cgi-bin/mon` или в LuCI Services → Монитор (обнови страницу через Ctrl+F5).

Обновление: та же команда. Удаление:

```sh
wget -qO- https://raw.githubusercontent.com/USER/REPO/main/install.sh | REPO=USER/REPO sh -s uninstall
```

Если `wget` ругается на https: `apk add ca-bundle libustream-mbedtls` (на старых версиях `opkg install ...`).

## Требования

- OpenWrt 23.05 и новее (проверено на 25.12, mediatek/filogic).
- Включённый conntrack (по умолчанию есть) и uhttpd с `/cgi-bin` (по умолчанию так).
- Для флагов стран браузер ходит на ip-api.com и flagcdn.com, роутер никуда не обращается.

## Безопасность

- Страница `/cgi-bin/mon` открыта всем в локальной сети и не требует входа в LuCI. Там видны все соединения устройств. Не пробрасывай порт 80 наружу и обязательно задай пароль root (`passwd`).
- Браузер отправляет внешние IP-адреса из таблицы на ip-api.com, чтобы определить страну. Если это не подходит, убери функцию `geo()` из `files/mon`.

## Как устроено

| Файл | Куда ставится |
| --- | --- |
| `files/mon` | `/www/cgi-bin/mon` |
| `files/luci-app-mon.json` | `/usr/share/luci/menu.d/luci-app-mon.json` |
| `files/mon.js` | `/www/luci-static/resources/view/mon.js` |

Данные читаются напрямую из `/proc/net/nf_conntrack`, `/tmp/dhcp.leases` и `netstat`. Страница обновляется раз в 5 секунд и стоит на паузе, пока вкладка браузера скрыта.
