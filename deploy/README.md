# Деплой

## GitHub Pages (основной вариант)

Сайт публикуется сам: при каждом пуше в `master` GitHub Actions
(`.github/workflows/site.yml`) прогоняет `make test`, собирает сайт через
`make dist` и выкладывает его на `https://pchelar.github.io/godot-zero/`.
HTTPS там уже есть, поэтому офлайн-режим работает сразу.

Один раз в репозитории: **Settings → Pages → Build and deployment → Source:
GitHub Actions**. Бесплатно Pages работает для публичных репозиториев.

Сайт живёт в подпапке, поэтому сборка для Pages идёт с
`SITE_ROOT=/godot-zero/`: по этому адресу страница 404 находит стили и
картинки. Локально `SITE_ROOT` не нужен, по умолчанию `/`.

Свой домен подключается там же, в Settings → Pages → Custom domain. Тогда сайт
окажется в корне домена и `SITE_ROOT` в workflow нужно убрать.

# Деплой на VPS (запасной вариант)

Сайт статический: nginx отдаёт готовые файлы из `/var/www/godot-zero`.
Сборка идёт на вашем компьютере, на сервер копируется только результат.

## Один раз на сервере (Ubuntu)

```bash
sudo apt update
sudo apt install nginx rsync
sudo mkdir -p /var/www/godot-zero
sudo chown $USER:$USER /var/www/godot-zero
```

Конфиг nginx из репозитория (`deploy/nginx.conf`) скопируйте на сервер в
`/etc/nginx/sites-available/godot-zero`, замените `example.com` на свой домен
(или IP-адрес сервера, пока домена нет) и включите:

```bash
sudo ln -s /etc/nginx/sites-available/godot-zero /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 'Nginx Full'
```

## Каждый раз на своём компьютере

```bash
make deploy DEPLOY_HOST=user@сервер
```

`make deploy` собирает демо, собирает сайт с нуля в `build/dist`, проверяет, что
сборка без предупреждений, сжимает файлы заранее (`.gz` рядом с оригиналами,
nginx отдаёт их без нагрузки на процессор) и копирует всё на сервер через
`rsync`. Удалённые со страниц файлы удаляются и на сервере.

Путь на сервере можно поменять: `DEPLOY_PATH=/другой/путь`.

## HTTPS и работа без интернета

Работа сайта без интернета держится на service worker, а браузеры включают его
только на HTTPS. Без HTTPS сайт работает как обычно, но офлайн-режима не будет.

Бесплатный сертификат даёт Let's Encrypt, ему нужен домен, указывающий на сервер
(запись `A` с IP-адресом сервера):

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d ваш-домен
```

certbot сам допишет HTTPS в конфиг nginx и будет продлевать сертификат.

## Что кэшируется офлайн

- Все страницы, картинки, стили и архивы проектов — при первом заходе на сайт.
- Движок Godot (около 40 МБ) — после первого запуска любого демо.

После каждого деплоя у страниц новая версия: браузер скачает их заново в фоне.
Движок перекачивается, только если он изменился.
